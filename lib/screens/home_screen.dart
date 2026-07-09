import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/finance_provider.dart';
import '../providers/notification_inbox_controller.dart';
import '../models/transaction_model.dart';
import '../utils/formatters.dart';
import '../core/theme.dart';
import 'notification_inbox_screen.dart';
import 'payment_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final finance = ref.watch(financeProvider);
    final inbox = ref.watch(notificationInboxControllerProvider);

    // List of recent transactions (max 3)
    final recentTransactions = finance.transactions.take(3).toList();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.analytics_rounded,
                color: theme.colorScheme.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'FinSense AI',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        actions: [
          // Notification Inbox Bell with Badge
          Badge(
            isLabelVisible: inbox.pending.isNotEmpty,
            label: Text(inbox.pending.length.toString()),
            child: IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const NotificationInboxScreen()),
                );
              },
              icon: Icon(
                Icons.notifications_none_rounded,
                color: theme.colorScheme.onSurface,
              ),
              tooltip: 'Notification Inbox',
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () {
              // Trigger a simulated transaction easily from home screen
              _showSimulationSheet(context, finance);
            },
            icon: Icon(
              Icons.flash_on_rounded,
              color: theme.colorScheme.primary,
            ),
            tooltip: 'Simulate SMS Notification',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: finance.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Greeting & Date
                  Text(
                    'Welcome back,',
                    style: theme.textTheme.bodyMedium,
                  ),
                  Text(
                    Formatters.date(DateTime.now()),
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Main Balance Card
                  _buildBalanceCard(context, finance),
                  const SizedBox(height: 16),

                  // Send Money Action Button
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                              ),
                              builder: (context) => const PaymentOptionsSheet(),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: AppTheme.softShadow,
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.send_rounded, color: Colors.white, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Send Money',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Today & Budget Stats Cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          context,
                          title: 'Spent Today',
                          amount: finance.todaySpent,
                          icon: Icons.trending_up_rounded,
                          color: AppTheme.accentOrange.withOpacity(0.08),
                          textColor: AppTheme.accentOrange,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMetricCard(
                          context,
                          title: 'Remaining Budget',
                          amount: finance.remainingBudget,
                          icon: Icons.pie_chart_outline_rounded,
                          color: AppTheme.accentGreen.withOpacity(0.08),
                          textColor: AppTheme.accentGreen,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Budget Progress Section
                  _buildBudgetProgress(context, finance),
                  const SizedBox(height: 28),

                  // Quick Insights Section
                  _buildQuickInsights(context, finance),
                  const SizedBox(height: 28),

                  // Recent Transactions Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent Activity',
                        style: theme.textTheme.titleMedium,
                      ),
                      if (finance.transactions.isNotEmpty)
                        Text(
                          'Last 3 logs',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textMuted,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Recent Transactions List
                  if (recentTransactions.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 30),
                      alignment: Alignment.center,
                      child: Text(
                        'No transactions recorded.\nUse the SMS simulator icon above to seed data.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium,
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: recentTransactions.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        return _buildTransactionItem(context, recentTransactions[index]);
                      },
                    ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  // 1. Balance Display Card
  Widget _buildBalanceCard(BuildContext context, FinanceProvider finance) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'CURRENT BALANCE',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withOpacity(0.6),
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  finance.demoMode ? 'Demo Mode' : 'Live Mode',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  Formatters.currency(finance.balance),
                  style: theme.textTheme.displayMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _showEditBalanceSheet(context, finance),
                icon: const Icon(Icons.edit_outlined, color: Colors.white),
                tooltip: 'Edit Balance',
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Divider(color: Colors.white.withOpacity(0.15), height: 1),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TOTAL INCOME',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      Formatters.currency(finance.totalIncome),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                height: 30,
                width: 1,
                color: Colors.white.withOpacity(0.15),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TOTAL SPENT',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      Formatters.currency(finance.totalExpense),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 2. Metric Highlight Box
  Widget _buildMetricCard(
    BuildContext context, {
    required String title,
    required double amount,
    required IconData icon,
    required Color color,
    required Color textColor,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderLight, width: 1.2),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: textColor, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            Formatters.currency(amount),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  // 3. Monthly Budget Progress Widget
  Widget _buildBudgetProgress(BuildContext context, FinanceProvider finance) {
    final theme = Theme.of(context);
    final percent = finance.budgetProgress * 100;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Monthly Budget Progress',
                    style: theme.textTheme.titleMedium?.copyWith(fontSize: 15),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Limit: ${Formatters.currency(finance.monthlyBudget)}',
                    style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
                  ),
                ],
              ),
              Text(
                '${percent.toStringAsFixed(0)}%',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: percent > 90 ? AppTheme.accentOrange : theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: finance.budgetProgress,
              minHeight: 8,
              backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(
                percent > 90 ? AppTheme.accentOrange : theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Spent ${Formatters.currency(finance.monthlySpent)} of ${Formatters.currency(finance.monthlyBudget)} this month',
            style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
          ),
        ],
      ),
    );
  }

  // 4. Quick Insights Carousel
  Widget _buildQuickInsights(BuildContext context, FinanceProvider finance) {
    final theme = Theme.of(context);

    // Dynamic insights generation
    final List<Map<String, dynamic>> insights = [
      {
        'title': 'Delivery Optimization',
        'desc': 'You can save approximately ${Formatters.activeSymbol}2,000 next month by reducing food delivery.',
        'icon': Icons.savings_outlined,
        'color': const Color(0xFFFAF2ED),
        'textColor': const Color(0xFFC7622A),
      },
      {
        'title': 'Frequent Merchants',
        'desc': 'Blinkit is your most visited store this month. Try ordering weekly in bulk.',
        'icon': Icons.insights_rounded,
        'color': const Color(0xFFEDF5EA),
        'textColor': const Color(0xFF4C7540),
      },
      {
        'title': 'Budget Diagnostics',
        'desc': finance.monthlySpent > finance.monthlyBudget
            ? 'Alert: You have exceeded your monthly threshold limit.'
            : 'You are currently on track to stay within your budget limit.',
        'icon': Icons.track_changes_rounded,
        'color': const Color(0xFFEEECFB),
        'textColor': const Color(0xFF564CBE),
      }
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Insights',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: insights.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final item = insights[index];
              return Container(
                width: 280,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: item['color'],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        item['icon'],
                        color: item['textColor'],
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['title'],
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: item['textColor'],
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Expanded(
                            child: Text(
                              item['desc'],
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: item['textColor'].withOpacity(0.85),
                                fontSize: 11.5,
                                height: 1.3,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // 5. Transaction list item helper
  Widget _buildTransactionItem(BuildContext context, TransactionModel tx) {
    final theme = Theme.of(context);
    final isDebit = tx.type.toLowerCase() == 'debit';
    final sign = isDebit ? '-' : '+';
    final amountColor = isDebit ? AppTheme.accentOrange : AppTheme.accentGreen;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderLight, width: 1.0),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          // Category Icon
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _getCategoryColor(tx.category),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getCategoryIcon(tx.category),
              color: theme.colorScheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),

          // Merchant & Time details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.merchant,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      tx.category,
                      style: theme.textTheme.bodyMedium?.copyWith(fontSize: 11),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 3,
                      height: 3,
                      decoration: const BoxDecoration(
                        color: AppTheme.textMuted,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      Formatters.time(tx.timestamp),
                      style: theme.textTheme.bodyMedium?.copyWith(fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Amount & Sign
          Text(
            '$sign${Formatters.currency(tx.amount)}',
            style: theme.textTheme.titleMedium?.copyWith(
              color: amountColor,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  // 6. Category metadata mappings
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

  // SMS Notification Simulation Bottom Sheet
  void _showSimulationSheet(BuildContext context, FinanceProvider finance) {
    final theme = Theme.of(context);
    final textController = TextEditingController(text: 'Swiggy');
    final amountController = TextEditingController(text: '350');
    String selectedType = 'debit';

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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Simulate SMS Notification Intercept',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Trigger a simulated notification. The AIExpenseCategorizer will resolve it, record it to Firestore, and update the UI.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 20),

                  // Merchant Field
                  TextField(
                    controller: textController,
                    decoration: const InputDecoration(
                      labelText: 'Merchant Name',
                      hintText: 'e.g. Swiggy, Uber, Amazon, Blinkit',
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Amount Field
                  TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Amount (${Formatters.activeSymbol})',
                      hintText: 'e.g. 450',
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Credit/Debit Picker
                  Row(
                    children: [
                      const Text('Type:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 16),
                      ChoiceChip(
                        label: const Text('Debit (Expense)'),
                        selected: selectedType == 'debit',
                        selectedColor: theme.colorScheme.primary.withOpacity(0.12),
                        onSelected: (val) {
                          if (val) setModalState(() => selectedType = 'debit');
                        },
                      ),
                      const SizedBox(width: 10),
                      ChoiceChip(
                        label: const Text('Credit (Income)'),
                        selected: selectedType == 'credit',
                        selectedColor: theme.colorScheme.primary.withOpacity(0.12),
                        onSelected: (val) {
                          if (val) setModalState(() => selectedType = 'credit');
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        final merchant = textController.text.trim();
                        final amount = double.tryParse(amountController.text) ?? 0.0;
                        if (merchant.isNotEmpty && amount > 0) {
                          finance.simulateIncomingSMS(merchant, amount, selectedType);
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Intercepted SMS for $merchant: ${Formatters.currency(amount)}'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                      child: const Text('Fire Notification SMS'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showEditBalanceSheet(BuildContext context, FinanceProvider finance) {
    final theme = Theme.of(context);
    final currentVal = finance.balance;
    final formKey = GlobalKey<FormState>();
    final newBalanceController = TextEditingController(text: currentVal.toStringAsFixed(2));
    String selectedReason = 'Manual Correction';
    final List<String> reasons = [
      'Salary',
      'Cash Deposit',
      'Bank Adjustment',
      'Manual Correction',
      'Other'
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 24,
                right: 24,
                top: 24,
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: theme.brightness == Brightness.dark
                                ? Colors.white24
                                : Colors.black12,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Adjust Current Balance',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Current Balance (calculated)',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textMuted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        Formatters.currency(currentVal),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: newBalanceController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'New Balance',
                          hintText: '0.00',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter the new balance amount';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Please enter a valid number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: selectedReason,
                        decoration: const InputDecoration(
                          labelText: 'Reason for Adjustment',
                        ),
                        items: reasons.map((r) {
                          return DropdownMenuItem<String>(
                            value: r,
                            child: Text(r),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              selectedReason = val;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                if (formKey.currentState!.validate()) {
                                  final newVal = double.parse(newBalanceController.text);
                                  Navigator.pop(context);
                                  try {
                                    await finance.updateManualBalance(newVal, selectedReason);
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Failed to update balance: $e')),
                                      );
                                    }
                                  }
                                }
                              },
                              child: const Text('Save'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
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
}
