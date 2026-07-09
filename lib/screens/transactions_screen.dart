import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/finance_provider.dart';
import '../models/transaction_model.dart';
import '../utils/formatters.dart';
import '../core/theme.dart';
import '../services/ai_expense_categorizer.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final finance = ref.watch(financeProvider);
    final filteredList = finance.filteredTransactions;
    debugPrint("[LOG] UI Updated: TransactionsScreen rebuilt with ${finance.transactions.length} items for UID: ${finance.userId}");
    debugPrint("[LOG] 9. Transaction list passed to Transactions screen: length=${filteredList.length}, raw=${filteredList.map((e) => e.toMap()).toList()}");

    // Categories list starting with 'All'
    final categories = ['All', ...AIExpenseCategorizer.categories];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Transactions',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        actions: [
          // Sort Button
          IconButton(
            onPressed: () => _showSortDialog(context, finance),
            icon: const Icon(Icons.sort_rounded),
            tooltip: 'Sort List',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // 1. Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => finance.setSearchQuery(val),
              decoration: InputDecoration(
                hintText: 'Search merchant, notes or category...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                          finance.setSearchQuery('');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

          // 2. Debit/Credit Selector Tab bar-like chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(
              children: [
                _buildTypeTabChip(finance, label: 'All Logs', value: 'All'),
                const SizedBox(width: 8),
                _buildTypeTabChip(finance, label: 'Expenses', value: 'debit'),
                const SizedBox(width: 8),
                _buildTypeTabChip(finance, label: 'Income', value: 'credit'),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // 3. Category Filter Chips (Horizontal)
          SizedBox(
            height: 38,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                final isSelected = finance.selectedCategory.toLowerCase() == category.toLowerCase();
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    selectedColor: theme.colorScheme.primary.withOpacity(0.12),
                    checkmarkColor: theme.colorScheme.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? theme.colorScheme.primary : AppTheme.textMuted,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 13,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: BorderSide(
                      color: isSelected ? theme.colorScheme.primary : AppTheme.borderLight,
                      width: 1.0,
                    ),
                    onSelected: (selected) {
                      finance.setSelectedCategory(category);
                    },
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // 4. Transactions List
          Expanded(
            child: filteredList.isEmpty
                ? Center(
                    child: Text(
                      'No matching transactions found.',
                      style: theme.textTheme.bodyMedium,
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      final tx = filteredList[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Dismissible(
                          key: Key(tx.id.toString()),
                          direction: DismissDirection.endToStart,
                          onDismissed: (direction) {
                            if (tx.id != null) {
                              finance.deleteTransaction(tx.id!);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Deleted ${tx.merchant} transaction'),
                                  behavior: SnackBarBehavior.floating,
                                  action: SnackBarAction(
                                    label: 'Undo',
                                    textColor: theme.colorScheme.primary,
                                    onPressed: () {
                                      finance.addTransaction(tx);
                                    },
                                  ),
                                ),
                              );
                            }
                          },
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            decoration: BoxDecoration(
                              color: AppTheme.accentOrange.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.delete_sweep_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          child: _buildTransactionTile(context, tx),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTransactionSheet(context, finance),
        child: const Icon(Icons.add_rounded, size: 28),
      ),
    );
  }

  // Type Tab Chip Helper
  Widget _buildTypeTabChip(FinanceProvider finance, {required String label, required String value}) {
    final isSelected = finance.selectedType == value;
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => finance.setSelectedType(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary : AppTheme.cardBg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.textMuted,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  // Sort Menu dialog
  void _showSortDialog(BuildContext context, FinanceProvider finance) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Sort Transactions By'),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSortOption(finance, 'Date (Newest)', 'date_desc'),
              _buildSortOption(finance, 'Date (Oldest)', 'date_asc'),
              _buildSortOption(finance, 'Amount (Highest)', 'amount_desc'),
              _buildSortOption(finance, 'Amount (Lowest)', 'amount_asc'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSortOption(FinanceProvider finance, String label, String value) {
    return RadioListTile<String>(
      title: Text(label, style: const TextStyle(fontSize: 14)),
      value: value,
      groupValue: finance.sortBy,
      activeColor: Theme.of(context).colorScheme.primary,
      onChanged: (val) {
        if (val != null) {
          finance.setSortBy(val);
          Navigator.pop(context);
        }
      },
    );
  }

  // Beautiful list tile details
  Widget _buildTransactionTile(BuildContext context, TransactionModel tx) {
    final theme = Theme.of(context);
    final isDebit = tx.type.toLowerCase() == 'debit';
    final sign = isDebit ? '-' : '+';
    final amountColor = isDebit ? AppTheme.accentOrange : AppTheme.accentGreen;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderLight, width: 1.0),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          // Category Icon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _getCategoryColor(tx.category),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              _getCategoryIcon(tx.category),
              color: theme.colorScheme.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 16),

          // Merchant & details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.merchant,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      tx.category,
                      style: theme.textTheme.bodyMedium?.copyWith(fontSize: 11),
                    ),
                    const SizedBox(width: 6),
                    Container(width: 3, height: 3, decoration: const BoxDecoration(color: AppTheme.textMuted, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text(
                      Formatters.date(tx.timestamp),
                      style: theme.textTheme.bodyMedium?.copyWith(fontSize: 11),
                    ),
                  ],
                ),
                if (tx.notes.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    tx.notes,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),

          // Amount and method
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$sign${Formatters.currency(tx.amount)}',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: amountColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                tx.paymentMethod,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Metadata loaders
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

  // Adding manual transactions
  void _showAddTransactionSheet(BuildContext context, FinanceProvider finance) {
    final theme = Theme.of(context);
    final formKey = GlobalKey<FormState>();

    String merchant = '';
    double amount = 0.0;
    String type = 'debit';
    String category = 'Others';
    String paymentMethod = 'UPI';
    String notes = '';
    DateTime selectedDate = DateTime.now();

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
                          Text('Add Transaction', style: theme.textTheme.titleLarge),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Merchant Input with AI Autocomplete listener
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Merchant / Description',
                          hintText: 'e.g. Swiggy, Blinkit, Amazon',
                        ),
                        validator: (val) => val == null || val.trim().isEmpty ? 'Enter merchant name' : null,
                        onChanged: (val) {
                          merchant = val.trim();
                          // AI Categorization heuristic on typing
                          final suggested = AIExpenseCategorizer.categorize(merchant);
                          if (suggested != 'Others') {
                            setModalState(() {
                              category = suggested;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 12),

                      // Amount Input
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Amount (${Formatters.activeSymbol})',
                          hintText: '0.00',
                          prefixText: '${Formatters.activeSymbol} ',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'Enter amount';
                          if (double.tryParse(val) == null || double.parse(val) <= 0) return 'Enter a valid positive number';
                          return null;
                        },
                        onSaved: (val) => amount = double.parse(val!),
                      ),
                      const SizedBox(height: 16),

                      // Debit / Credit Toggle
                      Row(
                        children: [
                          const Text('Type:', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(width: 16),
                          ChoiceChip(
                            label: const Text('Expense'),
                            selected: type == 'debit',
                            selectedColor: theme.colorScheme.primary.withOpacity(0.12),
                            onSelected: (selected) {
                              if (selected) setModalState(() => type = 'debit');
                            },
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: const Text('Income'),
                            selected: type == 'credit',
                            selectedColor: theme.colorScheme.primary.withOpacity(0.12),
                            onSelected: (selected) {
                              if (selected) setModalState(() => type = 'credit');
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Category Dropdown Selection
                      DropdownButtonFormField<String>(
                        initialValue: category,
                        decoration: const InputDecoration(labelText: 'Category'),
                        items: AIExpenseCategorizer.categories.map((c) {
                          return DropdownMenuItem<String>(
                            value: c,
                            child: Text(c),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setModalState(() => category = val);
                          }
                        },
                      ),
                      const SizedBox(height: 12),

                      // Payment Method Selector
                      DropdownButtonFormField<String>(
                        initialValue: paymentMethod,
                        decoration: const InputDecoration(labelText: 'Payment Method'),
                        items: const [
                          DropdownMenuItem(value: 'UPI', child: Text('UPI')),
                          DropdownMenuItem(value: 'Credit Card', child: Text('Credit Card')),
                          DropdownMenuItem(value: 'Debit Card', child: Text('Debit Card')),
                          DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                          DropdownMenuItem(value: 'Netbanking', child: Text('Netbanking')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setModalState(() => paymentMethod = val);
                          }
                        },
                      ),
                      const SizedBox(height: 12),

                      // Notes Input
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Notes',
                          hintText: 'Add additional details...',
                        ),
                        maxLines: 2,
                        onSaved: (val) => notes = val ?? '',
                      ),
                      const SizedBox(height: 16),

                      // Date selector button
                      InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime(2025),
                            lastDate: DateTime(2030),
                          );
                          if (date != null) {
                            setModalState(() => selectedDate = date);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: AppTheme.cardBg,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Date:', style: TextStyle(fontWeight: FontWeight.w500)),
                              Row(
                                children: [
                                  Text(Formatters.date(selectedDate)),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.calendar_today_rounded, size: 16),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Submit button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            if (formKey.currentState!.validate()) {
                              formKey.currentState!.save();
                              final tx = TransactionModel(
                                userId: finance.userId,
                                amount: amount,
                                merchant: merchant,
                                category: category,
                                type: type,
                                paymentMethod: paymentMethod,
                                timestamp: selectedDate,
                                notes: notes,
                                source: 'Manual',
                              );
                              debugPrint("[LOG] 1. Transaction object before saving: ${tx.toMap()}");
                              debugPrint("[LOG] 2. Database path being written: users/${finance.userId}/transactions");
                              finance.addTransaction(tx);
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Transaction saved successfully'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                          child: const Text('Save Log'),
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
}
