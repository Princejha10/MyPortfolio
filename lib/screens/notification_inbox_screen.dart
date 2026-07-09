import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification_transaction_model.dart';
import '../providers/notification_inbox_controller.dart';
import '../providers/settings_provider.dart';
import '../services/ai_expense_categorizer.dart';
import '../utils/formatters.dart';
import '../core/theme.dart';

class NotificationInboxScreen extends ConsumerStatefulWidget {
  const NotificationInboxScreen({super.key});

  @override
  ConsumerState<NotificationInboxScreen> createState() => _NotificationInboxScreenState();
}

class _NotificationInboxScreenState extends ConsumerState<NotificationInboxScreen> {
  final TextEditingController _simulationController = TextEditingController();
  String _simulationApp = 'Google Pay';

  @override
  void dispose() {
    _simulationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final inbox = ref.watch(notificationInboxControllerProvider);
    final inboxNotifier = ref.read(notificationInboxControllerProvider.notifier);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Notification Inbox',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          bottom: TabBar(
            indicatorColor: theme.colorScheme.primary,
            labelColor: theme.colorScheme.primary,
            unselectedLabelColor: theme.hintColor,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            tabs: [
              Tab(text: 'Pending (${inbox.pending.length})'),
              Tab(text: 'Confirmed (${inbox.confirmed.length})'),
              Tab(text: 'Ignored (${inbox.ignored.length})'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.bolt_rounded),
              tooltip: 'Simulate Notification',
              onPressed: () => _showSimulationDialog(context, inboxNotifier),
            ),
          ],
        ),
        body: inbox.isProcessing
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'AI is analyzing notification...',
                      style: TextStyle(fontStyle: FontStyle.italic, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              )
            : TabBarView(
                children: [
                  _buildPendingTab(context, inbox.pending, inboxNotifier, theme),
                  _buildConfirmedTab(context, inbox.confirmed, inboxNotifier, theme),
                  _buildIgnoredTab(context, inbox.ignored, inboxNotifier, theme),
                ],
              ),
      ),
    );
  }

  // ----------------------------------------------------
  // Pending Review List Tab
  // ----------------------------------------------------
  Widget _buildPendingTab(
    BuildContext context,
    List<NotificationTransaction> list,
    NotificationInboxController notifier,
    ThemeData theme,
  ) {
    if (list.isEmpty) {
      return _buildEmptyState(
        icon: Icons.done_all_rounded,
        title: 'Inbox is Clean!',
        subtitle: 'All financial notifications have been processed.',
        theme: theme,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final tx = list[index];
        return _buildNotificationCard(context, tx, notifier, theme, isPending: true);
      },
    );
  }

  // ----------------------------------------------------
  // Confirmed History Tab
  // ----------------------------------------------------
  Widget _buildConfirmedTab(
    BuildContext context,
    List<NotificationTransaction> list,
    NotificationInboxController notifier,
    ThemeData theme,
  ) {
    if (list.isEmpty) {
      return _buildEmptyState(
        icon: Icons.check_circle_outline_rounded,
        title: 'No Confirmed Items',
        subtitle: 'Transactions confirmed from alerts will show up here.',
        theme: theme,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final tx = list[index];
        return _buildNotificationCard(context, tx, notifier, theme, isPending: false, isConfirmed: true);
      },
    );
  }

  // ----------------------------------------------------
  // Ignored / Skipped Tab
  // ----------------------------------------------------
  Widget _buildIgnoredTab(
    BuildContext context,
    List<NotificationTransaction> list,
    NotificationInboxController notifier,
    ThemeData theme,
  ) {
    if (list.isEmpty) {
      return _buildEmptyState(
        icon: Icons.block_rounded,
        title: 'No Ignored Alerts',
        subtitle: 'Alerts you dismiss or ignore will be logged here.',
        theme: theme,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final tx = list[index];
        return _buildNotificationCard(context, tx, notifier, theme, isPending: false, isIgnored: true);
      },
    );
  }

  // ----------------------------------------------------
  // Reusable Notification Details Card Widget
  // ----------------------------------------------------
  Widget _buildNotificationCard(
    BuildContext context,
    NotificationTransaction tx,
    NotificationInboxController notifier,
    ThemeData theme, {
    required bool isPending,
    bool isConfirmed = false,
    bool isIgnored = false,
  }) {
    final isDebit = tx.type.toLowerCase() == 'debit';
    final sign = isDebit ? '-' : '+';
    final amtColor = isDebit ? AppTheme.accentOrange : AppTheme.accentGreen;
    final currency = ref.watch(settingsProvider).currency;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppTheme.borderLight, width: 1.2),
      ),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _getCategoryColor(tx.category).withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getCategoryIcon(tx.category),
              color: _getCategoryColor(tx.category),
              size: 22,
            ),
          ),
          title: Text(
            tx.merchant,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.accentBeige,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      tx.appName,
                      style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    Formatters.date(tx.timestamp),
                    style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                  ),
                ],
              ),
            ],
          ),
          trailing: Text(
            '$sign$currency${tx.amount.toStringAsFixed(2)}',
            style: TextStyle(
              color: amtColor,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(color: AppTheme.borderLight),
                  const SizedBox(height: 4),
                  const Text(
                    'Raw Alert Text:',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textMuted),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.borderLight),
                    ),
                    child: Text(
                      tx.rawMessage,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: theme.textTheme.bodyMedium?.color?.withOpacity(0.85),
                      ),
                    ),
                  ),
                  if (tx.upiReference != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'UPI Ref ID: ${tx.upiReference}',
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: AppTheme.textMuted),
                    ),
                  ],
                  const SizedBox(height: 16),

                  // Button controls depending on Tab
                  if (isPending)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Ignore Trigger
                        OutlinedButton(
                          onPressed: () => notifier.ignoreNotification(tx.id),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.accentOrange,
                            side: const BorderSide(color: AppTheme.accentOrange),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Ignore', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                        const SizedBox(width: 8),

                        // Edit Trigger
                        OutlinedButton(
                          onPressed: () => _showEditNotificationDialog(context, tx, notifier),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.textDark,
                            side: const BorderSide(color: AppTheme.borderLight),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Edit', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                        const SizedBox(width: 8),

                        // Confirm Trigger
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () async {
                            await notifier.confirmNotification(tx);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Added to transactions: ${tx.merchant}'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                          child: const Text('Confirm', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ],
                    ),

                  if (isConfirmed)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppTheme.accentOrange),
                          label: const Text('Delete Log', style: TextStyle(color: AppTheme.accentOrange, fontSize: 12)),
                          onPressed: () => notifier.deleteNotification(tx.id),
                        ),
                      ],
                    ),

                  if (isIgnored)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppTheme.borderLight),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () => notifier.restoreNotification(tx.id),
                          child: const Text('Restore to Pending', style: TextStyle(color: AppTheme.textDark, fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 8),
                        TextButton.icon(
                          icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppTheme.accentOrange),
                          label: const Text('Delete Log', style: TextStyle(color: AppTheme.accentOrange, fontSize: 12)),
                          onPressed: () => notifier.deleteNotification(tx.id),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------
  // Edit Notification Alert Dialog
  // ----------------------------------------------------
  void _showEditNotificationDialog(
    BuildContext context,
    NotificationTransaction tx,
    NotificationInboxController notifier,
  ) {
    final amountController = TextEditingController(text: tx.amount.toString());
    final merchantController = TextEditingController(text: tx.merchant);
    String selectedCategory = tx.category;
    String selectedType = tx.type;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Edit Intercepted Expense', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: merchantController,
                      decoration: const InputDecoration(labelText: 'Merchant / Receiver'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Amount'),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: selectedCategory,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: AIExpenseCategorizer.categories.map((cat) {
                        return DropdownMenuItem(value: cat, child: Text(cat));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() {
                            selectedCategory = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text('Debit', style: TextStyle(fontSize: 13)),
                            value: 'debit',
                            groupValue: selectedType,
                            contentPadding: EdgeInsets.zero,
                            onChanged: (val) {
                              if (val != null) {
                                setDialogState(() {
                                  selectedType = val;
                                });
                              }
                            },
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text('Credit', style: TextStyle(fontSize: 13)),
                            value: 'credit',
                            groupValue: selectedType,
                            contentPadding: EdgeInsets.zero,
                            onChanged: (val) {
                              if (val != null) {
                                setDialogState(() {
                                  selectedType = val;
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final double finalAmt = double.tryParse(amountController.text) ?? tx.amount;
                    final updatedTx = tx.copyWith(
                      merchant: merchantController.text,
                      amount: finalAmt,
                      category: selectedCategory,
                      type: selectedType,
                    );
                    
                    Navigator.pop(context);
                    await notifier.confirmNotification(updatedTx);
                    
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Saved: ${updatedTx.merchant}'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  child: const Text('Save & Confirm'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ----------------------------------------------------
  // Push Notification Simulator Dialog
  // ----------------------------------------------------
  void _showSimulationDialog(BuildContext context, NotificationInboxController notifier) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Simulate Transaction Alert', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Simulate incoming push notifications from Google Pay, PhonePe, Paytm or banks. Test parsing and fallback Gemini AI classifications.',
                    style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _simulationApp,
                    decoration: const InputDecoration(labelText: 'Source App'),
                    items: ['Google Pay', 'PhonePe', 'Paytm', 'SBI', 'HDFC'].map((app) {
                      return DropdownMenuItem(value: app, child: Text(app));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() {
                          _simulationApp = val;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _simulationController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Enter alert text, e.g. "INR 350.00 spent at Swiggy via HDFC Bank on 08-Jul-26"',
                      alignLabelWithHint: true,
                      contentPadding: EdgeInsets.all(12),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
                ),
                ElevatedButton(
                  onPressed: () {
                    final text = _simulationController.text.trim();
                    if (text.isNotEmpty) {
                      notifier.simulateRawNotification(text, _simulationApp);
                      _simulationController.clear();
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Simulated alert dispatched to reader service.'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  child: const Text('Simulate Input'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ----------------------------------------------------
  // Empty State View Widget
  // ----------------------------------------------------
  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required ThemeData theme,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 54, color: theme.colorScheme.primary),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return AppTheme.accentGreen;
      case 'shopping':
        return Colors.blue;
      case 'bills':
        return Colors.purple;
      case 'entertainment':
        return Colors.pink;
      case 'transport':
      case 'travel':
        return Colors.teal;
      case 'healthcare':
        return Colors.red;
      case 'education':
        return Colors.indigo;
      case 'investment':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Icons.restaurant_rounded;
      case 'shopping':
        return Icons.shopping_bag_rounded;
      case 'bills':
        return Icons.receipt_rounded;
      case 'entertainment':
        return Icons.local_play_rounded;
      case 'transport':
      case 'travel':
        return Icons.directions_car_rounded;
      case 'healthcare':
        return Icons.medical_services_rounded;
      case 'education':
        return Icons.school_rounded;
      case 'investment':
        return Icons.trending_up_rounded;
      default:
        return Icons.category_rounded;
    }
  }
}


