import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/finance_provider.dart';
import '../models/transaction_model.dart';
import '../utils/formatters.dart';
import '../core/theme.dart';
import '../services/ai_expense_categorizer.dart';
import 'home_screen.dart';
import 'transactions_screen.dart';
import 'analytics_screen.dart';
import 'ai_assistant_screen.dart';
import 'settings_screen.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _selectedIndex = 0;
  
  // Track the last shown pending transaction to prevent double sheets
  TransactionModel? _lastShownPending;

  final List<Widget> _screens = const [
    HomeScreen(),
    TransactionsScreen(),
    AnalyticsScreen(),
    AIAssistantScreen(),
    SettingsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final finance = ref.watch(financeProvider);

    // Intercept and display pending transaction sheet dynamically
    if (finance.pendingTransaction != null && finance.pendingTransaction != _lastShownPending) {
      _lastShownPending = finance.pendingTransaction;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showConfirmationSheet(context, finance);
      });
    }
    
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              spreadRadius: 1,
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: _onItemTapped,
          backgroundColor: theme.scaffoldBackgroundColor,
          elevation: 0,
          indicatorColor: theme.colorScheme.primary.withOpacity(0.1),
          height: 65,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long_rounded),
              label: 'Transactions',
            ),
            NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined),
              selectedIcon: Icon(Icons.bar_chart_rounded),
              label: 'Analytics',
            ),
            NavigationDestination(
              icon: Icon(Icons.chat_bubble_outline_rounded),
              selectedIcon: Icon(Icons.chat_bubble_rounded),
              label: 'AI Assistant',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings_rounded),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }

  // 1. Auto-Confirmation Dialog Sheet
  void _showConfirmationSheet(BuildContext context, FinanceProvider finance) {
    final theme = Theme.of(context);
    final pending = finance.pendingTransaction;
    if (pending == null) return;

    final isDebit = pending.type.toLowerCase() == 'debit';
    final sign = isDebit ? '-' : '+';
    final amtColor = isDebit ? AppTheme.accentOrange : AppTheme.accentGreen;

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.auto_awesome_rounded, color: theme.colorScheme.primary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Payment Detected Automatically',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.accentBeige,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      pending.paymentMethod,
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Transaction Info Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.borderLight, width: 1.2),
                ),
                child: Row(
                  children: [
                    // Category Graphic Indicator
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _getCategoryColor(pending.category),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        _getCategoryIcon(pending.category),
                        color: theme.colorScheme.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Merchant and Category Labels
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pending.merchant,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Category: ${pending.category}',
                            style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                          ),
                          if (pending.upiReference != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              'UPI Ref: ${pending.upiReference}',
                              style: const TextStyle(color: AppTheme.textMuted, fontSize: 10, fontFamily: 'monospace'),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Amount Text
                    Text(
                      '$sign${Formatters.currency(pending.amount)}',
                      style: TextStyle(
                        color: amtColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Button row options
              Row(
                children: [
                  // Confirm Option
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        await finance.confirmPendingTransaction();
                        _lastShownPending = null;
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Saved: ${pending.merchant} for ${Formatters.currency(pending.amount)}'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                      child: const Text('Confirm'),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Edit Option
                  OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context); // Close confirm sheet
                      _showEditPendingSheet(context, finance, pending);
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      side: const BorderSide(color: AppTheme.borderLight),
                    ),
                    child: const Text('Edit', style: TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 8),

                  // Ignore Option
                  OutlinedButton(
                    onPressed: () {
                      finance.ignorePendingTransaction();
                      _lastShownPending = null;
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      side: const BorderSide(color: AppTheme.accentOrange),
                    ),
                    child: const Text('Ignore', style: TextStyle(color: AppTheme.accentOrange, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // 2. Pre-populated Edit Pending Sheet
  void _showEditPendingSheet(BuildContext context, FinanceProvider finance, TransactionModel pending) {
    final theme = Theme.of(context);
    final formKey = GlobalKey<FormState>();

    String merchant = pending.merchant;
    double amount = pending.amount;
    String category = pending.category;
    String type = pending.type;
    String notes = pending.notes;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 24,
                left: 24,
                right: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Edit Detected Payment', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                          IconButton(
                            onPressed: () {
                              finance.setPendingTransaction(null);
                              _lastShownPending = null;
                              Navigator.pop(context);
                            },
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Merchant Name
                      TextFormField(
                        initialValue: merchant,
                        decoration: const InputDecoration(labelText: 'Merchant Name'),
                        validator: (val) => val == null || val.trim().isEmpty ? 'Enter merchant name' : null,
                        onSaved: (val) => merchant = val!.trim(),
                      ),
                      const SizedBox(height: 12),

                      // Amount
                      TextFormField(
                        initialValue: amount.toStringAsFixed(2),
                        decoration: InputDecoration(labelText: 'Amount (${Formatters.activeSymbol})', prefixText: '${Formatters.activeSymbol} '),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'Enter amount';
                          if (double.tryParse(val) == null || double.parse(val) <= 0) return 'Enter a valid number';
                          return null;
                        },
                        onSaved: (val) => amount = double.parse(val!),
                      ),
                      const SizedBox(height: 16),

                      // Credit / Debit Type
                      Row(
                        children: [
                          const Text('Type:', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(width: 16),
                          ChoiceChip(
                            label: const Text('Expense'),
                            selected: type == 'debit',
                            selectedColor: theme.colorScheme.primary.withOpacity(0.12),
                            onSelected: (val) {
                              if (val) setModalState(() => type = 'debit');
                            },
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: const Text('Income'),
                            selected: type == 'credit',
                            selectedColor: theme.colorScheme.primary.withOpacity(0.12),
                            onSelected: (val) {
                              if (val) setModalState(() => type = 'credit');
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Category Dropdown
                      DropdownButtonFormField<String>(
                        initialValue: category,
                        decoration: const InputDecoration(labelText: 'Category'),
                        items: AIExpenseCategorizer.categories.map((c) {
                          return DropdownMenuItem<String>(value: c, child: Text(c));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setModalState(() => category = val);
                          }
                        },
                      ),
                      const SizedBox(height: 12),

                      // Notes
                      TextFormField(
                        initialValue: notes,
                        decoration: const InputDecoration(labelText: 'Notes'),
                        maxLines: 2,
                        onSaved: (val) => notes = val ?? '',
                      ),
                      const SizedBox(height: 24),

                      // Save Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (formKey.currentState!.validate()) {
                              formKey.currentState!.save();
                              
                              // Check if category was modified from parsed default, and save as override correction
                              if (category != pending.category) {
                                await finance.saveCategoryCorrection(merchant, category);
                              }

                              final updatedTx = TransactionModel(
                                userId: finance.userId,
                                amount: amount,
                                merchant: merchant,
                                category: category,
                                type: type,
                                paymentMethod: pending.paymentMethod,
                                upiReference: pending.upiReference,
                                timestamp: pending.timestamp,
                                notes: notes,
                                source: pending.source,
                              );

                              await finance.addTransaction(updatedTx);
                              finance.setPendingTransaction(null); // Clear buffer
                              _lastShownPending = null;
                              if (context.mounted) {
                                Navigator.pop(context); // Close edit modal
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Transaction saved successfully'),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            }
                          },
                          child: const Text('Save & Confirm'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Graphics Mappings
  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'grocery':
        return Icons.shopping_basket_outlined;
      case 'food':
        return Icons.restaurant_outlined;
      case 'shopping':
        return Icons.shopping_bag_outlined;
      case 'fuel':
        return Icons.local_gas_station_outlined;
      case 'travel':
        return Icons.directions_car_outlined;
      case 'bills':
        return Icons.receipt_outlined;
      case 'entertainment':
        return Icons.movie_outlined;
      case 'healthcare':
        return Icons.medical_services_outlined;
      default:
        return Icons.more_horiz_outlined;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'grocery':
        return const Color(0xFFEAF2E8);
      case 'food':
        return const Color(0xFFFAF1EC);
      case 'shopping':
        return const Color(0xFFF7F4EB);
      case 'fuel':
        return const Color(0xFFEBF1F7);
      case 'travel':
        return const Color(0xFFECEFF1);
      case 'bills':
        return const Color(0xFFFAF1F0);
      case 'entertainment':
        return const Color(0xFFECEBF7);
      case 'healthcare':
        return const Color(0xFFEBF7F2);
      default:
        return const Color(0xFFF6F5EE);
    }
  }
}
