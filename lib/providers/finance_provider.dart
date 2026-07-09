import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/transaction_model.dart';
import '../models/budget_model.dart';
import '../repositories/transaction_repository.dart';
import '../repositories/budget_repository.dart';
import '../services/notification_service.dart';
import '../services/ai_expense_categorizer.dart';
import '../repositories/notification_inbox_repository.dart';
import '../providers/notification_inbox_controller.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'auth_provider.dart';
import '../repositories/user_repository.dart';

// Global providers for repositories
final transactionRepositoryProvider = Provider<TransactionRepository>((ref) => FirestoreTransactionRepository());
final budgetRepositoryProvider = Provider<BudgetRepository>((ref) => FirestoreBudgetRepository());
final userRepositoryProvider = Provider<UserRepository>((ref) => FirestoreUserRepository());

/// Safely resolve NotificationService cross-platform
final notificationServiceProvider = Provider<NotificationService>((ref) {
  // Safe runtime resolution
  // We can let the main entry inject it or resolve it here.
  // We'll stub or bind a global instance. See main.dart.
  throw UnimplementedError('Resolve in main.dart overrides');
});

/// Riverpod ChangeNotifierProvider for the Finance State
final financeProvider = ChangeNotifierProvider<FinanceProvider>((ref) {
  final user = ref.watch(authStateChangesProvider).value;
  final repo = ref.watch(transactionRepositoryProvider);
  final budgetRepo = ref.watch(budgetRepositoryProvider);
  final notification = ref.watch(notificationServiceProvider);
  final inboxRepo = ref.watch(notificationInboxRepositoryProvider);
  final userRepo = ref.watch(userRepositoryProvider);

  return FinanceProvider(
    userId: user?.uid ?? '',
    repository: repo,
    budgetRepository: budgetRepo,
    notificationService: notification,
    inboxRepository: inboxRepo,
    userRepository: userRepo,
  );
});

class FinanceProvider extends ChangeNotifier {
  final String _userId;
  final TransactionRepository _repository;
  final BudgetRepository _budgetRepository;
  final NotificationService _notificationService;
  final NotificationInboxRepository _inboxRepository;
  final UserRepository _userRepository;

  List<TransactionModel> _transactions = [];
  bool _isLoading = false;
  double _monthlyBudget = 30000.0;
  final double _initialBalance = 10000000.0; // Production default balance
  final bool _demoMode = false; // Always false, Firebase-only production mode

  double? _manualBalance;
  DateTime? _manualBalanceUpdatedAt;

  StreamSubscription? _transactionsSubscription;
  StreamSubscription? _budgetSubscription;
  StreamSubscription? _userSubscription;

  int _txRetryCount = 0;
  int _userRetryCount = 0;

  // Filtering & Sorting
  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _selectedType = 'All'; // 'All' | 'credit' | 'debit'
  String _sortBy = 'date_desc'; // 'date_desc' | 'date_asc' | 'amount_desc' | 'amount_asc'

  // Pending Transaction Buffer (For Auto-Confirmation Sheet)
  TransactionModel? _pendingTransaction;

  FinanceProvider({
    required String userId,
    required TransactionRepository repository,
    required BudgetRepository budgetRepository,
    required NotificationService notificationService,
    required NotificationInboxRepository inboxRepository,
    required UserRepository userRepository,
  })  : _userId = userId,
        _repository = repository,
        _budgetRepository = budgetRepository,
        _notificationService = notificationService,
        _inboxRepository = inboxRepository,
        _userRepository = userRepository {
    if (_userId.isNotEmpty) {
      _listenToData();
    }

    // Listen to real-time notification streams from platform channel
    _notificationService.onNotificationTransaction.listen((transaction) {
      final txWithUser = transaction.copyWith(userId: _userId);
      setPendingTransaction(txWithUser);
    });
  }

  // Getters
  List<TransactionModel> get transactions => _transactions;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;
  String get selectedType => _selectedType;
  String get sortBy => _sortBy;
  double get monthlyBudget => _monthlyBudget;
  TransactionModel? get pendingTransaction => _pendingTransaction;
  bool get demoMode => _demoMode;

  String get userId => _userId;

  void _listenToData() {
    if (Firebase.apps.isEmpty) {
      debugPrint("[INIT GUARD] Skipping Firestore listeners: Firebase is uninitialized.");
      return;
    }
    _isLoading = true;
    notifyListeners();

    // 1. Load user custom corrections from Firestore into categorizer cache
    AIExpenseCategorizer.loadUserCorrections(_repository, _userId);

    // 2. Real-time stream subscription for budgets collection
    _budgetSubscription?.cancel();
    _budgetSubscription = _budgetRepository.getBudgetStream(_userId).listen(
      (budgetObj) {
        _monthlyBudget = budgetObj.monthlyBudget;
        debugPrint("[LOG] Realtime update: Budget updated in Firestore for UID: $_userId. New limit: $_monthlyBudget");
        notifyListeners();
      },
      onError: (_) {},
    );

    // 3. Setup user balance stream
    _listenToUser();

    // 4. Setup transactions stream
    _listenToTransactions();
  }

  void _listenToTransactions() {
    debugPrint("[LOG] 4. Database path being read: users/$_userId/transactions");
    _transactionsSubscription?.cancel();
    _transactionsSubscription = _repository.getTransactionsStream(_userId).listen(
      (list) {
        _txRetryCount = 0;
        _transactions = list;
        _isLoading = false;
        
        debugPrint("[LOG] 5. Number of documents returned: ${list.length}");
        for (var i = 0; i < list.length; i++) {
          final tx = list[i];
          debugPrint("[LOG] 6. Document returned #$i: ID=${tx.id} => data=${tx.toMap()}");
          debugPrint("[LOG] 7. Parsed transaction model: ID=${tx.id}, merchant=${tx.merchant}, amount=${tx.amount}, timestamp=${tx.timestamp}");
        }
        
        debugPrint("[LOG] 8. Provider transaction count: ${list.length}");
        
        final bal = balance;
        final inc = totalIncome;
        final exp = totalExpense;
        debugPrint("[LOG] 10. Dashboard calculation inputs: base=$_manualBalance, initial=$_initialBalance, cutoff=$_manualBalanceUpdatedAt, total transactions=${_transactions.length}");
        debugPrint("[LOG] 11. Calculated balance: $bal, income: $inc, expenses: $exp");
        
        notifyListeners();
      },
      onError: (e) {
        _isLoading = false;
        debugPrint("[FINANCE PROVIDER] Transactions stream error: $e");
        notifyListeners();
        
        if (e.toString().contains('permission-denied') && _txRetryCount < 5) {
          _txRetryCount++;
          debugPrint("[LOG] Retrying transactions stream listen in ${_txRetryCount}s (attempt $_txRetryCount/5)...");
          Future.delayed(Duration(seconds: _txRetryCount), () {
            if (_userId.isNotEmpty) {
              _listenToTransactions();
            }
          });
        }
      },
    );
  }

  void _listenToUser() {
    _userSubscription?.cancel();
    _userSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(_userId)
        .snapshots()
        .listen(
      (snap) {
        _userRetryCount = 0;
        if (!snap.exists) {
          debugPrint("[LOG] User document users/$_userId does not exist. Creating it automatically.");
          FirebaseFirestore.instance.collection('users').doc(_userId).set({
            'currentBalance': 10000000.0,
            'updatedAt': FieldValue.serverTimestamp(),
            'reason': 'Initial Setup',
          }).then((_) {
            debugPrint("[LOG] Write Success: Created user metadata document at users/$_userId");
          }).catchError((e) {
            debugPrint("[LOG] Error creating user document: $e");
          });
        } else {
          final data = snap.data();
          if (data != null && data.containsKey('currentBalance')) {
            _manualBalance = (data['currentBalance'] as num).toDouble();
            _manualBalanceUpdatedAt = (data['updatedAt'] as Timestamp?)?.toDate();
            
            debugPrint("[LOG] Current UID: $_userId");
            debugPrint("[LOG] Firestore path: users/$_userId");
            debugPrint("[LOG] Balance read: $_manualBalance");
            debugPrint("[LOG] Read Success: Successfully read user balance document.");
            debugPrint("[LOG] Realtime update: User balance document changed in Firestore.");
            notifyListeners();
          }
        }
      },
      onError: (e) {
        debugPrint("[FINANCE PROVIDER] User snapshot listen error: $e");
        if (e.toString().contains('permission-denied') && _userRetryCount < 5) {
          _userRetryCount++;
          debugPrint("[LOG] Retrying user metadata listen in ${_userRetryCount}s (attempt $_userRetryCount/5)...");
          Future.delayed(Duration(seconds: _userRetryCount), () {
            if (_userId.isNotEmpty) {
              _listenToUser();
            }
          });
        }
      },
    );
  }

  // Calculations
  double get totalIncome => _transactions
      .where((t) => t.type.toLowerCase() == 'credit')
      .fold(0.0, (sum, t) => sum + t.amount);

  double get totalExpense => _transactions
      .where((t) => t.type.toLowerCase() == 'debit' && t.category.toLowerCase() != 'correction')
      .fold(0.0, (sum, t) => sum + t.amount);

  double get balance {
    final base = _manualBalance ?? _initialBalance;
    final cutoff = _manualBalanceUpdatedAt;

    double income = 0.0;
    double expense = 0.0;

    for (final tx in _transactions) {
      if (cutoff != null && tx.timestamp.isBefore(cutoff)) {
        continue;
      }
      if (tx.type.toLowerCase() == 'credit') {
        income += tx.amount;
      } else {
        expense += tx.amount;
      }
    }

    return base + income - expense;
  }

  double get todaySpent {
    final now = DateTime.now();
    return _transactions
        .where((t) =>
            t.type.toLowerCase() == 'debit' &&
            t.timestamp.year == now.year &&
            t.timestamp.month == now.month &&
            t.timestamp.day == now.day)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get monthlySpent {
    final now = DateTime.now();
    return _transactions
        .where((t) =>
            t.type.toLowerCase() == 'debit' &&
            t.timestamp.year == now.year &&
            t.timestamp.month == now.month)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get remainingBudget {
    final left = _monthlyBudget - monthlySpent;
    return left > 0 ? left : 0.0;
  }

  double get budgetProgress {
    if (_monthlyBudget == 0) return 0.0;
    final progress = monthlySpent / _monthlyBudget;
    return progress > 1.0 ? 1.0 : progress;
  }

  // Filtered lists
  List<TransactionModel> get filteredTransactions {
    List<TransactionModel> list = List.from(_transactions);

    // Text search filter
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list
          .where((t) =>
              t.merchant.toLowerCase().contains(q) ||
              t.notes.toLowerCase().contains(q) ||
              t.category.toLowerCase().contains(q))
          .toList();
    }

    // Category filter
    if (_selectedCategory != 'All') {
      list = list
          .where((t) => t.category.toLowerCase() == _selectedCategory.toLowerCase())
          .toList();
    }

    // Type filter
    if (_selectedType != 'All') {
      list = list
          .where((t) => t.type.toLowerCase() == _selectedType.toLowerCase())
          .toList();
    }

    // Sorting rules
    if (_sortBy == 'date_desc') {
      list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    } else if (_sortBy == 'date_asc') {
      list.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    } else if (_sortBy == 'amount_desc') {
      list.sort((a, b) => b.amount.compareTo(a.amount));
    } else if (_sortBy == 'amount_asc') {
      list.sort((a, b) => a.amount.compareTo(b.amount));
    }

    return list;
  }

  // Filters State Modifiers
  void setSearchQuery(String value) {
    _searchQuery = value;
    notifyListeners();
  }

  void setSelectedCategory(String value) {
    _selectedCategory = value;
    notifyListeners();
  }

  void setSelectedType(String value) {
    _selectedType = value;
    notifyListeners();
  }

  void setSortBy(String value) {
    _sortBy = value;
    notifyListeners();
  }

  // Pending Transaction Buffer Mutators
  void setPendingTransaction(TransactionModel? tx) {
    _pendingTransaction = tx;
    notifyListeners();
  }

  Future<void> confirmPendingTransaction() async {
    final tx = _pendingTransaction;
    if (tx == null) return;
    _pendingTransaction = null;
    await addTransaction(tx);
    if (tx.id != null && tx.id!.startsWith('nt_')) {
      try {
        await _inboxRepository.updateNotificationStatus(_userId, tx.id!, 'confirmed');
      } catch (e) {
        debugPrint("[FINANCE PROVIDER] Failed to confirm notification in inbox: $e");
      }
    }
  }

  void ignorePendingTransaction() {
    final tx = _pendingTransaction;
    _pendingTransaction = null;
    notifyListeners();
    if (tx != null && tx.id != null && tx.id!.startsWith('nt_')) {
      try {
        _inboxRepository.updateNotificationStatus(_userId, tx.id!, 'ignored');
      } catch (e) {
        debugPrint("[FINANCE PROVIDER] Failed to ignore notification in inbox: $e");
      }
    }
  }

  // Persists custom category correction overrides
  Future<void> saveCategoryCorrection(String merchant, String category) async {
    if (_userId.isEmpty) return;
    await AIExpenseCategorizer.saveUserCorrection(merchant, category, _repository, _userId);
    notifyListeners();
  }

  // Firestore Mutations
  Future<void> addTransaction(TransactionModel transaction) async {
    if (_userId.isEmpty) return;
    final tx = transaction.copyWith(userId: _userId);
    await _repository.insertTransaction(tx);
  }

  Future<void> deleteTransaction(String id) async {
    await _repository.deleteTransaction(_userId, id);
  }

  Future<void> clearAllTransactions() async {
    if (_userId.isEmpty) return;
    await _repository.clearAllTransactions(_userId);
  }

  Future<void> updateBudget(double value) async {
    if (_userId.isEmpty) return;
    final budgetObj = BudgetModel(
      userId: _userId,
      monthlyBudget: value,
      categoryBudgets: const {},
    );
    await _budgetRepository.saveBudget(budgetObj);
  }



  void simulateIncomingSMS(String merchant, double amount, String type) {
    if (_userId.isEmpty) return;
    final category = AIExpenseCategorizer.categorize(merchant);
    final tx = TransactionModel(
      userId: _userId,
      amount: amount,
      merchant: merchant,
      category: category,
      type: type,
      paymentMethod: 'UPI (Auto)',
      timestamp: DateTime.now(),
      upiReference: DateTime.now().millisecondsSinceEpoch.toString().substring(0, 12),
      notes: 'Simulated UPI intercept.',
      source: 'SMS',
    );

    final service = _notificationService;
    if (service is AndroidNotificationService) {
      service.simulateNotificationIntercept(tx);
    } else {
      setPendingTransaction(tx);
    }
  }

  String exportToCSV() {
    final buffer = StringBuffer();
    buffer.writeln('ID,Date,Merchant,Category,Type,Amount,UPI_Ref,Method,Notes');
    for (final t in _transactions) {
      buffer.writeln(
        '${t.id},${t.timestamp.toIso8601String()},"${t.merchant.replaceAll('"', '""')}","${t.category}","${t.type}",${t.amount},"${t.upiReference ?? ''}","${t.paymentMethod}","${t.notes.replaceAll('"', '""')}"',
      );
    }
    return buffer.toString();
  }

  Future<void> updateManualBalance(double newBalance, String reason) async {
    if (_userId.isEmpty) return;
    final oldVal = balance;
    await _userRepository.updateManualBalance(
      uid: _userId,
      newBalance: newBalance,
      oldBalance: oldVal,
      reason: reason,
    );
  }

  @override
  void dispose() {
    _transactionsSubscription?.cancel();
    _budgetSubscription?.cancel();
    _userSubscription?.cancel();
    super.dispose();
  }
}
