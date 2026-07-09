import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification_transaction_model.dart';
import '../models/transaction_model.dart';
import '../repositories/notification_inbox_repository.dart';
import '../repositories/transaction_repository.dart';
import '../services/notification_parser.dart';
import '../services/ai_expense_categorizer.dart';
import '../services/gemini_notification_classifier.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'settings_provider.dart';
import 'auth_provider.dart';
import 'finance_provider.dart';

final notificationInboxRepositoryProvider = Provider<NotificationInboxRepository>((ref) => NotificationInboxRepository());

final notificationInboxControllerProvider = StateNotifierProvider<NotificationInboxController, NotificationInboxState>((ref) {
  final auth = ref.watch(authStateChangesProvider).value;
  final inboxRepo = ref.watch(notificationInboxRepositoryProvider);
  final txRepo = ref.watch(transactionRepositoryProvider);

  return NotificationInboxController(
    ref: ref,
    userId: auth?.uid ?? '',
    inboxRepo: inboxRepo,
    txRepo: txRepo,
  );
});

class NotificationInboxState {
  final List<NotificationTransaction> pending;
  final List<NotificationTransaction> confirmed;
  final List<NotificationTransaction> ignored;
  final bool isProcessing;

  NotificationInboxState({
    required this.pending,
    required this.confirmed,
    required this.ignored,
    this.isProcessing = false,
  });

  NotificationInboxState copyWith({
    List<NotificationTransaction>? pending,
    List<NotificationTransaction>? confirmed,
    List<NotificationTransaction>? ignored,
    bool? isProcessing,
  }) {
    return NotificationInboxState(
      pending: pending ?? this.pending,
      confirmed: confirmed ?? this.confirmed,
      ignored: ignored ?? this.ignored,
      isProcessing: isProcessing ?? this.isProcessing,
    );
  }
}

class NotificationInboxController extends StateNotifier<NotificationInboxState> {
  final Ref _ref;
  final String _userId;
  final NotificationInboxRepository _inboxRepo;
  final TransactionRepository _txRepo;

  StreamSubscription? _rawNotificationSubscription;
  StreamSubscription? _pendingSubscription;
  StreamSubscription? _confirmedSubscription;
  StreamSubscription? _ignoredSubscription;

  NotificationInboxController({
    required Ref ref,
    required String userId,
    required NotificationInboxRepository inboxRepo,
    required TransactionRepository txRepo,
  })  : _ref = ref,
        _userId = userId,
        _inboxRepo = inboxRepo,
        _txRepo = txRepo,
        super(NotificationInboxState(pending: [], confirmed: [], ignored: [])) {
    if (_userId.isNotEmpty) {
      _listenToFirestoreInbox();
      _listenToIncomingNotifications();
    }
  }

  void _listenToFirestoreInbox() {
    _pendingSubscription?.cancel();
    _pendingSubscription = _inboxRepo.getNotificationsStream(_userId, 'pending').listen((list) {
      state = state.copyWith(pending: list);
    });

    _confirmedSubscription?.cancel();
    _confirmedSubscription = _inboxRepo.getNotificationsStream(_userId, 'confirmed').listen((list) {
      state = state.copyWith(confirmed: list);
    });

    _ignoredSubscription?.cancel();
    _ignoredSubscription = _inboxRepo.getNotificationsStream(_userId, 'ignored').listen((list) {
      state = state.copyWith(ignored: list);
    });
  }

  void _listenToIncomingNotifications() {
    _rawNotificationSubscription?.cancel();
    
    // Listen to raw events emitted by the platform channel
    _rawNotificationSubscription = _ref.read(notificationServiceProvider).onRawNotification.listen((event) {
      _processRawNotification(event['message'] ?? '', event['packageName'] ?? '');
    });
  }

  Future<void> _processRawNotification(String message, String packageName) async {
    final settings = _ref.read(settingsProvider);
    
    // 1. Check if Notification Reader is enabled in settings
    if (!settings.isNotificationReaderEnabled) return;

    // 2. Identify the app name from package identifier
    final appName = _getAppNameFromPackage(packageName, message);

    // Save last received notification text & package locally for UI display
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('lastNotificationText_$appName', message);
      await prefs.setString('lastNotificationTime_$appName', DateTime.now().toIso8601String());
    } catch (_) {}
    
    // 3. Verify if app is in monitored apps list
    if (!settings.monitoredApps.contains(appName)) return;

    // 4. Verify if message is a financial alert using basic keywords
    final lowerMessage = message.toLowerCase();
    final financialKeywords = [
      'debited', 'credited', 'spent', 'received', 'paid', 'sent to', 'received from',
      'transferred', 'withdrawn', 'payment of', 'transaction', 'rs.', 'inr', '₹'
    ];
    final isFinancial = financialKeywords.any((kw) => lowerMessage.contains(kw));
    if (!isFinancial) return;

    // 5. Parse locally using regex
    final localParsed = NotificationParser.parse(message, appName);
    
    double amount = 0.0;
    String merchant = 'Unknown Merchant';
    String type = 'debit';
    String category = 'Others';
    String? upiRef;

    if (localParsed != null && localParsed.amount > 0 && localParsed.merchant != 'Unknown Merchant') {
      amount = localParsed.amount;
      merchant = localParsed.merchant;
      type = localParsed.type;
      upiRef = localParsed.upiReference;
      category = AIExpenseCategorizer.categorize(merchant);
    } else {
      // 6. Fallback to Gemini AI for incomplete or complex notifications
      state = state.copyWith(isProcessing: true);
      try {
        final aiParsed = await GeminiNotificationClassifier.classifyNotification(message);
        if (aiParsed != null && (aiParsed['amount'] as double) > 0) {
          amount = aiParsed['amount'] as double;
          merchant = aiParsed['merchant'] as String;
          type = aiParsed['type'] as String;
          category = aiParsed['category'] as String;
          
          // Try to get UPI reference locally as fallback
          if (localParsed != null) {
            upiRef = localParsed.upiReference;
          }
        } else {
          // If even Gemini failed to extract a transaction value, ignore the notification
          state = state.copyWith(isProcessing: false);
          return;
        }
      } catch (e) {
        debugPrint("[NOTIFICATION CONTROLLER] Gemini parsing exception: $e");
        state = state.copyWith(isProcessing: false);
        return;
      }
      state = state.copyWith(isProcessing: false);
    }

    // 7. Deduplicate notifications by hashing message and amount
    final String deterministicId = "nt_${message.hashCode.abs()}_${(amount * 100).toInt()}";
    
    final isDuplicate = await _inboxRepo.hasTransaction(_userId, deterministicId);
    if (isDuplicate) {
      debugPrint("[NOTIFICATION CONTROLLER] Ignored duplicate notification transaction: $deterministicId");
      return;
    }

    // 8. Create NotificationTransaction object
    final notificationTx = NotificationTransaction(
      id: deterministicId,
      userId: _userId,
      amount: amount,
      merchant: merchant,
      timestamp: DateTime.now(),
      type: type,
      appName: appName,
      upiReference: upiRef,
      rawMessage: message,
      status: settings.isAutoSaveEnabled ? 'confirmed' : 'pending',
      category: category,
    );

    // 9. Auto-save or queue for review
    if (settings.isAutoSaveEnabled) {
      // Create main expense ledger item
      final mainTx = TransactionModel(
        userId: _userId,
        amount: amount,
        merchant: merchant,
        category: category,
        type: type,
        paymentMethod: appName,
        upiReference: upiRef,
        timestamp: DateTime.now(),
        notes: 'Auto-saved via notification from $appName',
        source: 'SMS',
      );
      
      try {
        await _txRepo.insertTransaction(mainTx);
        await _inboxRepo.saveNotification(_userId, notificationTx);
      } catch (e) {
        debugPrint("[NOTIFICATION CONTROLLER] Failed to auto-save transaction: $e");
      }
    } else {
      // Save as pending for manual review
      try {
        await _inboxRepo.saveNotification(_userId, notificationTx);
        
        // Push to active FinanceProvider pending buffer if app is in foreground
        final finance = _ref.read(financeProvider);
        final parsedTx = TransactionModel(
          id: deterministicId,
          userId: _userId,
          amount: amount,
          merchant: merchant,
          category: category,
          type: type,
          paymentMethod: appName,
          upiReference: upiRef,
          timestamp: DateTime.now(),
          notes: 'Captured via notification from $appName',
          source: 'SMS',
        );
        finance.setPendingTransaction(parsedTx);
      } catch (e) {
        debugPrint("[NOTIFICATION CONTROLLER] Failed to save pending notification: $e");
      }
    }
  }

  /// Confirm a pending notification transaction (converts to real expense)
  Future<void> confirmNotification(NotificationTransaction transaction) async {
    final mainTx = TransactionModel(
      userId: _userId,
      amount: transaction.amount,
      merchant: transaction.merchant,
      category: transaction.category,
      type: transaction.type,
      paymentMethod: transaction.appName,
      upiReference: transaction.upiReference,
      timestamp: transaction.timestamp,
      notes: 'Confirmed notification from ${transaction.appName}',
      source: 'SMS',
    );

    try {
      await _txRepo.insertTransaction(mainTx);
      await _inboxRepo.updateNotificationStatus(_userId, transaction.id, 'confirmed');
    } catch (e) {
      debugPrint("[NOTIFICATION CONTROLLER] Failed to confirm notification: $e");
    }
  }

  /// Ignore a pending notification
  Future<void> ignoreNotification(String id) async {
    try {
      await _inboxRepo.updateNotificationStatus(_userId, id, 'ignored');
    } catch (e) {
      debugPrint("[NOTIFICATION CONTROLLER] Failed to ignore notification: $e");
    }
  }

  /// Restore an ignored notification back to pending status
  Future<void> restoreNotification(String id) async {
    try {
      await _inboxRepo.updateNotificationStatus(_userId, id, 'pending');
    } catch (e) {
      debugPrint("[NOTIFICATION CONTROLLER] Failed to restore notification: $e");
    }
  }

  /// Delete a notification transaction record permanently
  Future<void> deleteNotification(String id) async {
    try {
      await _inboxRepo.deleteNotification(_userId, id);
    } catch (e) {
      debugPrint("[NOTIFICATION CONTROLLER] Failed to delete notification: $e");
    }
  }

  /// Directly save a notification transaction (used for payment module notifications)
  Future<void> saveNotificationDirect(NotificationTransaction transaction) async {
    try {
      await _inboxRepo.saveNotification(_userId, transaction);
    } catch (e) {
      debugPrint("[NOTIFICATION CONTROLLER] Failed to save direct notification: $e");
    }
  }

  /// Simulates a notification trigger for testing
  void simulateRawNotification(String message, String appName) {
    String package = 'Unknown';
    if (appName == 'Google Pay') package = 'com.google.android.apps.nbu.paisa.user';
    if (appName == 'PhonePe') package = 'com.phonepe.app';
    if (appName == 'Paytm') package = 'net.one97.paytm';
    
    _processRawNotification(message, package);
  }

  String _getAppNameFromPackage(String packageName, String message) {
    final cleanPkg = packageName.toLowerCase();
    
    if (cleanPkg.contains('nbu.paisa') || cleanPkg.contains('gpay') || cleanPkg.contains('google')) {
      return 'Google Pay';
    } else if (cleanPkg.contains('phonepe')) {
      return 'PhonePe';
    } else if (cleanPkg.contains('paytm')) {
      return 'Paytm';
    } else if (cleanPkg.contains('bhim')) {
      return 'BHIM';
    } else if (cleanPkg.contains('amazon')) {
      return 'Amazon Pay';
    } else if (cleanPkg.contains('whatsapp')) {
      return 'WhatsApp';
    } else if (cleanPkg.contains('sbi')) {
      return 'SBI';
    } else if (cleanPkg.contains('hdfc')) {
      return 'HDFC';
    } else if (cleanPkg.contains('icici')) {
      return 'ICICI';
    } else if (cleanPkg.contains('axis')) {
      return 'Axis';
    } else if (cleanPkg.contains('kotak')) {
      return 'Kotak';
    } else if (cleanPkg.contains('pnb')) {
      return 'PNB';
    }
    
    // Fallback word matching
    final lowerMessage = message.toLowerCase();
    if (lowerMessage.contains('sbi')) return 'SBI';
    if (lowerMessage.contains('hdfc')) return 'HDFC';
    if (lowerMessage.contains('icici')) return 'ICICI';
    if (lowerMessage.contains('axis')) return 'Axis';
    if (lowerMessage.contains('kotak')) return 'Kotak';
    if (lowerMessage.contains('pnb')) return 'PNB';

    return 'Google Pay'; // Default fallback
  }

  @override
  void dispose() {
    _rawNotificationSubscription?.cancel();
    _pendingSubscription?.cancel();
    _confirmedSubscription?.cancel();
    _ignoredSubscription?.cancel();
    super.dispose();
  }
}
