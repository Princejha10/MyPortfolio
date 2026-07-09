import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/settings_provider.dart';
import '../providers/notification_inbox_controller.dart';
import '../core/theme.dart';

class NotificationSourcesScreen extends ConsumerStatefulWidget {
  const NotificationSourcesScreen({super.key});

  @override
  ConsumerState<NotificationSourcesScreen> createState() => _NotificationSourcesScreenState();
}

class _NotificationSourcesScreenState extends ConsumerState<NotificationSourcesScreen> {
  static const _methodChannel = MethodChannel('com.finsense.ai/notifications');
  
  List<Map<String, dynamic>> _installedApps = [];
  bool _isLoadingApps = true;
  String _searchQuery = '';
  Map<String, String> _lastNotifications = {};
  
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadInstalledAppsAndLogs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInstalledAppsAndLogs() async {
    setState(() {
      _isLoadingApps = true;
    });

    try {
      // 1. Fetch installed banking apps from native Android layer
      final List<dynamic>? appsResult = await _methodChannel.invokeMethod<List<dynamic>>('getInstalledBankingApps');
      if (appsResult != null) {
        _installedApps = appsResult.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }

      // 2. Fetch last received notification logs from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final Map<String, String> tempLogs = {};
      
      for (final app in _installedApps) {
        final appName = app['name'] as String? ?? '';
        final text = prefs.getString('lastNotificationText_$appName') ?? '';
        if (text.isNotEmpty) {
          tempLogs[appName] = text;
        }
      }

      setState(() {
        _lastNotifications = tempLogs;
        _isLoadingApps = false;
      });
    } catch (e) {
      debugPrint("[NOTIFICATION SOURCES] Failed to load apps: $e");
      setState(() {
        _isLoadingApps = false;
      });
    }
  }

  // Suggest enabling newly detected banking apps that are not currently enabled
  List<Map<String, dynamic>> _getSuggestions(List<String> enabledApps) {
    return _installedApps.where((app) {
      final name = app['name'] as String? ?? '';
      return !enabledApps.contains(name);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);
    final inboxNotifier = ref.read(notificationInboxControllerProvider.notifier);

    // Filter apps based on search query
    final filteredApps = _installedApps.where((app) {
      final name = (app['name'] as String? ?? '').toLowerCase();
      final pkg = (app['package'] as String? ?? '').toLowerCase();
      final query = _searchQuery.toLowerCase();
      return name.contains(query) || pkg.contains(query);
    }).toList();

    final suggestions = _getSuggestions(settings.monitoredApps);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Notification Sources',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Reload Installed Apps',
            onPressed: _loadInstalledAppsAndLogs,
          ),
        ],
      ),
      body: _isLoadingApps
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Scanning installed banking apps...', style: TextStyle(color: AppTheme.textMuted)),
                ],
              ),
            )
          : Column(
              children: [
                // 1. Search Bar & Simulator triggers
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Column(
                    children: [
                      TextField(
                        controller: _searchController,
                        onChanged: (val) {
                          setState(() {
                            _searchQuery = val;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Search installed payment apps...',
                          prefixIcon: const Icon(Icons.search_rounded),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {
                                      _searchQuery = '';
                                    });
                                  },
                                )
                              : null,
                          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                final installedNames = _installedApps.map((e) => e['name'] as String? ?? '').where((n) => n.isNotEmpty).toList();
                                settingsNotifier.updateMonitoredApps(installedNames);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Enabled all installed banking apps.')),
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: const Text('Select All', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                settingsNotifier.updateMonitoredApps([]);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Cleared all monitored apps.')),
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: const Text('Clear All', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _showSimulateDialog(context, inboxNotifier),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: const Text('Test Reader', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // 2. Privacy Policy & Permissions Explainer Card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: theme.colorScheme.primary.withOpacity(0.15)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.shield_outlined, color: theme.colorScheme.primary, size: 24),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Privacy & Security Guarantee',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textDark),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'FinSense only reads alerts from the apps you select below. Non-selected notifications are ignored natively on-device and never processed.',
                                style: TextStyle(fontSize: 11, color: AppTheme.textMuted, height: 1.35),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 3. Proactive Banner for newly detected apps
                if (suggestions.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.accentOrange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.accentOrange.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.new_releases_rounded, color: AppTheme.accentOrange),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Detected ${suggestions.length} banking apps not yet monitored. Tap to add them.',
                            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            final current = List<String>.from(settings.monitoredApps);
                            for (final sug in suggestions) {
                              final name = sug['name'] as String? ?? '';
                              if (name.isNotEmpty && !current.contains(name)) {
                                current.add(name);
                              }
                            }
                            settingsNotifier.updateMonitoredApps(current);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Added new apps to monitoring list.')),
                            );
                          },
                          child: const Text('Add All', style: TextStyle(color: AppTheme.accentOrange, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),

                // 4. Installed Apps List
                Expanded(
                  child: filteredApps.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.app_registration_rounded, size: 48, color: theme.hintColor),
                              const SizedBox(height: 12),
                              const Text('No installed banking apps detected.', style: TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              const Text('Ensure you have Google Pay, Paytm, or bank apps installed.', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredApps.length,
                          itemBuilder: (context, index) {
                            final app = filteredApps[index];
                            final name = app['name'] as String? ?? 'Unknown App';
                            final pkg = app['package'] as String? ?? '';
                            final base64Icon = app['icon'] as String? ?? '';
                            final isMonitored = settings.monitoredApps.contains(name);
                            final lastAlert = _lastNotifications[name] ?? '';

                            return Card(
                              elevation: 0,
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: const BorderSide(color: AppTheme.borderLight),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        // App Icon decoded from base64
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(10),
                                          child: base64Icon.isNotEmpty
                                              ? Image.memory(
                                                  base64Decode(base64Icon),
                                                  width: 38,
                                                  height: 38,
                                                  errorBuilder: (context, error, stackTrace) =>
                                                      const Icon(Icons.account_balance_wallet_rounded, color: AppTheme.textMuted),
                                                )
                                              : const Icon(Icons.account_balance_wallet_rounded, color: AppTheme.textMuted),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                name,
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                pkg,
                                                style: const TextStyle(fontSize: 10, color: AppTheme.textMuted, fontFamily: 'monospace'),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Switch(
                                          value: isMonitored,
                                          activeThumbColor: theme.colorScheme.primary,
                                          onChanged: (checked) {
                                            final currentApps = List<String>.from(settings.monitoredApps);
                                            if (checked) {
                                              if (!currentApps.contains(name)) currentApps.add(name);
                                            } else {
                                              currentApps.remove(name);
                                            }
                                            settingsNotifier.updateMonitoredApps(currentApps);
                                          },
                                        ),
                                      ],
                                    ),
                                    if (lastAlert.isNotEmpty) ...[
                                      const SizedBox(height: 10),
                                      const Divider(height: 1, color: AppTheme.borderLight),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          const Icon(Icons.history_rounded, size: 12, color: AppTheme.textMuted),
                                          const SizedBox(width: 6),
                                          const Text(
                                            'Last received log:',
                                            style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: AppTheme.textMuted),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        lastAlert,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontStyle: FontStyle.italic,
                                          color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  // Simulated Alert Modal Dialog
  void _showSimulateDialog(BuildContext context, NotificationInboxController notifier) {
    final simulateController = TextEditingController();
    String simulationApp = _installedApps.isNotEmpty ? (_installedApps[0]['name'] as String? ?? 'Google Pay') : 'Google Pay';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Test Notification Intercept', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Simulate incoming push notifications from monitored sources to verify parsing and fallback Gemini AI extractions.',
                    style: TextStyle(fontSize: 11.5, color: AppTheme.textMuted),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: simulationApp,
                    decoration: const InputDecoration(labelText: 'Target Application'),
                    items: _installedApps.map((e) => e['name'] as String? ?? 'Google Pay').toSet().map((app) {
                      return DropdownMenuItem(value: app, child: Text(app));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() {
                          simulationApp = val;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: simulateController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Enter test SMS body text, e.g. "Rs. 250 paid to Swiggy via SBI card"',
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
                    final text = simulateController.text.trim();
                    if (text.isNotEmpty) {
                      notifier.simulateRawNotification(text, simulationApp);
                      simulateController.clear();
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Simulated push notification dispatched.'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  child: const Text('Dispatched Alert'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
