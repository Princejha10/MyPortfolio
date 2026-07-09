import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/finance_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import 'notification_sources_screen.dart';
import '../core/theme.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final finance = ref.watch(financeProvider);
    final isAndroidPlatform = !kIsWeb && Platform.isAndroid;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section: Platform Diagnostics
            _buildSectionHeader(theme, 'Notification Access'),
            const SizedBox(height: 8),
            _buildNotificationAccessCard(context, ref, isAndroidPlatform),
            const SizedBox(height: 24),

            // Section: Notification Reader Settings
            if (isAndroidPlatform) ...[
              _buildSectionHeader(theme, 'Notification Reader Settings'),
              const SizedBox(height: 8),
              _buildNotificationReaderSettingsCard(context, ref),
              const SizedBox(height: 24),
            ],

            // Section: Data & Demo Mode
            _buildSectionHeader(theme, 'Demo Database controls'),
            const SizedBox(height: 8),
            _buildDatabaseControlsCard(context, finance),
            const SizedBox(height: 24),

            // Section: Preferences
            _buildSectionHeader(theme, 'App Preferences'),
            const SizedBox(height: 8),
            _buildPreferencesCard(context, ref),
            const SizedBox(height: 24),

            // Section: System Info
            _buildSectionHeader(theme, 'System Diagnostics'),
            const SizedBox(height: 8),
            _buildSystemDiagnosticsCard(theme),
            const SizedBox(height: 24),

            // Section: Account Settings
            _buildSectionHeader(theme, 'Account'),
            const SizedBox(height: 8),
            _buildAccountControlsCard(context, ref),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Text(
      title.toUpperCase(),
      style: theme.textTheme.bodyMedium?.copyWith(
        fontWeight: FontWeight.bold,
        letterSpacing: 0.8,
        fontSize: 11,
      ),
    );
  }

  // 1. Android Notification Service Setup Card
  Widget _buildNotificationAccessCard(BuildContext context, WidgetRef ref, bool isAndroid) {
    final theme = Theme.of(context);

    if (isAndroid) {
      return FutureBuilder<bool>(
        future: ref.read(notificationServiceProvider).isPermissionGranted(),
        builder: (context, snapshot) {
          final isGranted = snapshot.data ?? false;
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.borderLight, width: 1.0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.android_rounded, 
                      color: isGranted ? AppTheme.accentGreen : theme.colorScheme.primary
                    ),
                    const SizedBox(width: 12),
                    Text(
                      isGranted ? 'SMS Interceptor Active' : 'Android SMS Interceptor Hook',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  isGranted
                      ? 'FinSense AI has notification access permission and is successfully listening for bank SMS alerts in the background.'
                      : 'Enabling notification listener access allows native Android code to intercept incoming bank SMS receipts in the background, automatically parsing transaction amounts and merchants.',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textMuted, height: 1.35),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () async {
                        final granted = await ref.read(notificationServiceProvider).requestPermission();
                        if (granted) {
                          await ref.read(notificationServiceProvider).startListening();
                        }
                      },
                      icon: Icon(isGranted ? Icons.check_circle_rounded : Icons.settings_suggest_rounded, size: 18),
                      label: Text(isGranted ? 'Access Granted' : 'Configure Listener'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );
    } else {
      // iOS / Web restrictions explain card
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.borderLight, width: 1.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.apple_rounded, color: AppTheme.textMuted),
                SizedBox(width: 12),
                Text(
                  'iOS Security Sandboxing Active',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textDark),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'iOS security models forbid third-party apps from reading other applications\' notification streams or SMS logs. To test FinSense AI on iOS, utilize Manual Transaction entries or trigger the Demo Mode below.',
              style: TextStyle(fontSize: 12, color: AppTheme.textMuted, height: 1.35),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.cardBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.info_outline_rounded, size: 14, color: AppTheme.textMuted),
                  SizedBox(width: 8),
                  Text(
                    'Use Demo Mode / Manual entry for evaluation.',
                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppTheme.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
  }

  // 1b. Notification Reader Settings Card
  Widget _buildNotificationReaderSettingsCard(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderLight, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Enable reader switch
          SwitchListTile(
            title: const Text('Enable Notification Reader', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold)),
            subtitle: const Text('Read incoming notification logs for transaction patterns.', style: TextStyle(fontSize: 11)),
            value: settings.isNotificationReaderEnabled,
            activeThumbColor: theme.colorScheme.primary,
            contentPadding: EdgeInsets.zero,
            onChanged: (val) async {
              if (val) {
                // Verify permission first
                final granted = await ref.read(notificationServiceProvider).isPermissionGranted();
                if (!granted) {
                  // Prompt to request permission
                  if (context.mounted) {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Permission Required'),
                        content: const Text('To enable this feature, you must grant FinSense AI notification access in your device settings.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              Navigator.pop(context);
                              final ok = await ref.read(notificationServiceProvider).requestPermission();
                              if (ok) {
                                await settingsNotifier.toggleNotificationReader(true);
                                await ref.read(notificationServiceProvider).startListening();
                              }
                            },
                            child: const Text('Open Settings'),
                          ),
                        ],
                      ),
                    );
                  }
                } else {
                  await settingsNotifier.toggleNotificationReader(true);
                  await ref.read(notificationServiceProvider).startListening();
                }
              } else {
                await settingsNotifier.toggleNotificationReader(false);
                await ref.read(notificationServiceProvider).stopListening();
              }
            },
          ),
          const Divider(color: AppTheme.borderLight, height: 20),

          // 2. Auto-save switch
          SwitchListTile(
            title: const Text('Auto-Save Transactions', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold)),
            subtitle: const Text('Automatically write verified alerts directly to expenses.', style: TextStyle(fontSize: 11)),
            value: settings.isAutoSaveEnabled,
            activeThumbColor: theme.colorScheme.primary,
            contentPadding: EdgeInsets.zero,
            onChanged: (val) {
              settingsNotifier.toggleAutoSave(val);
            },
          ),
          const Divider(color: AppTheme.borderLight, height: 20),

          // 3. Monitored Apps list trigger
          ListTile(
            title: const Text('Monitored Apps', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold)),
            subtitle: Text(
              'Configure app selection filters (${settings.monitoredApps.length} enabled)',
              style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
            ),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
            contentPadding: EdgeInsets.zero,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NotificationSourcesScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  // 2. Local Database Actions Card
  Widget _buildDatabaseControlsCard(BuildContext context, FinanceProvider finance) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderLight, width: 1.0),
      ),
      child: Column(
        children: [

          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _exportToCSV(context, finance),
                  icon: const Icon(Icons.download_rounded, size: 18),
                  label: const Text('Export CSV'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _showClearConfirmation(context, finance),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.accentOrange,
                    side: const BorderSide(color: AppTheme.accentOrange, width: 1.2),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Clear All', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 3. User Styling / Mode Preferences Card
  Widget _buildPreferencesCard(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderLight, width: 1.0),
      ),
      child: Column(
        children: [
          // Dark Mode Switch
          SwitchListTile(
            title: const Text('Dark Mode Display', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold)),
            subtitle: const Text('Switches the background between light and dark palettes.', style: TextStyle(fontSize: 11)),
            value: settings.themeMode == ThemeMode.dark,
            onChanged: (val) {
              settingsNotifier.toggleTheme(val);
            },
            activeThumbColor: theme.colorScheme.primary,
            contentPadding: EdgeInsets.zero,
          ),
          const Divider(color: AppTheme.borderLight, height: 20),
          // Currency Selector
          ListTile(
            title: const Text('Standard Currency Symbol', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: theme.brightness == Brightness.dark ? AppTheme.darkCardBg : AppTheme.cardBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Currency (${settings.currency})',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: theme.brightness == Brightness.dark ? AppTheme.darkText : AppTheme.textDark,
                ),
              ),
            ),
            contentPadding: EdgeInsets.zero,
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Select Currency'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        title: const Text('Indian Rupee (₹)'),
                        onTap: () {
                          settingsNotifier.changeCurrency('₹');
                          Navigator.pop(context);
                        },
                      ),
                      ListTile(
                        title: const Text('US Dollar (\$)'),
                        onTap: () {
                          settingsNotifier.changeCurrency('\$');
                          Navigator.pop(context);
                        },
                      ),
                      ListTile(
                        title: const Text('Euro (€)'),
                        onTap: () {
                          settingsNotifier.changeCurrency('€');
                          Navigator.pop(context);
                        },
                      ),
                      ListTile(
                        title: const Text('British Pound (£)'),
                        onTap: () {
                          settingsNotifier.changeCurrency('£');
                          Navigator.pop(context);
                        },
                      ),
                      ListTile(
                        title: const Text('Japanese Yen (¥)'),
                        onTap: () {
                          settingsNotifier.changeCurrency('¥');
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // 4. App/System metadata
  Widget _buildSystemDiagnosticsCard(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderLight, width: 1.0),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('FinSense AI MVP • Version 1.0.0-Demo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          SizedBox(height: 4),
          Text(
            'Built with Flutter, Material 3, and SQLite. Sub-systems configured for Android NotificationListener service bindings.',
            style: TextStyle(fontSize: 11.5, color: AppTheme.textMuted, height: 1.35),
          ),
        ],
      ),
    );
  }

  // 5. Account Settings Panel
  Widget _buildAccountControlsCard(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(authStateChangesProvider).value;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderLight, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: theme.colorScheme.primary.withOpacity(0.08),
                radius: 20,
                child: Text(
                  (user?.email ?? 'U').substring(0, 1).toUpperCase(),
                  style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.email ?? 'Guest Account',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'UID: ${user?.uid ?? "Offline Guest Mode"}',
                      style: const TextStyle(fontSize: 9.5, color: AppTheme.textMuted, fontFamily: 'monospace'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(color: AppTheme.borderLight, height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.errorContainer,
                foregroundColor: theme.colorScheme.onErrorContainer,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () => ref.read(authRepositoryProvider).signOut(),
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: const Text('Log Out', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  // CSV Generation logic
  void _exportToCSV(BuildContext context, FinanceProvider finance) {
    final txs = finance.transactions;
    if (txs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No transaction logs found to export.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final buffer = StringBuffer();
    buffer.writeln('ID,Merchant,Amount,Category,Type,PaymentMethod,Reference,Date,Notes,Source');
    for (final tx in txs) {
      buffer.writeln(
        '${tx.id ?? ""},'
        '"${tx.merchant.replaceAll('"', '""')}",'
        '${tx.amount},'
        '${tx.category},'
        '${tx.type},'
        '${tx.paymentMethod},'
        '${tx.upiReference ?? ""},'
        '${tx.timestamp.toIso8601String()},'
        '"${tx.notes.replaceAll('"', '""')}",'
        '${tx.source}'
      );
    }

    _showCSVDialog(context, buffer.toString());
  }

  // Dialog showing CSV file representation
  void _showCSVDialog(BuildContext context, String csv) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('CSV Export Results'),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Your local transaction history converted to CSV format is displayed below:',
                  style: TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  constraints: const BoxConstraints(maxHeight: 180),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppTheme.cardBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      csv,
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 10, color: AppTheme.textDark),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: csv));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Copied CSV details to clipboard.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: const Text('Copy to Clipboard'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showClearConfirmation(BuildContext context, FinanceProvider finance) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Transactions?'),
        content: const Text('This action will permanently delete all your transaction entries from the database. This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentOrange, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(context);
              await finance.clearAllTransactions();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Cleared all transactions.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
  }
}


