import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_provider.dart';

class SettingsState {
  final ThemeMode themeMode;
  final String currency;
  final bool isNotificationReaderEnabled;
  final List<String> monitoredApps;
  final bool isAutoSaveEnabled;

  SettingsState({
    required this.themeMode,
    required this.currency,
    required this.isNotificationReaderEnabled,
    required this.monitoredApps,
    required this.isAutoSaveEnabled,
  });

  SettingsState copyWith({
    ThemeMode? themeMode,
    String? currency,
    bool? isNotificationReaderEnabled,
    List<String>? monitoredApps,
    bool? isAutoSaveEnabled,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      currency: currency ?? this.currency,
      isNotificationReaderEnabled: isNotificationReaderEnabled ?? this.isNotificationReaderEnabled,
      monitoredApps: monitoredApps ?? this.monitoredApps,
      isAutoSaveEnabled: isAutoSaveEnabled ?? this.isAutoSaveEnabled,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  final Ref _ref;

  SettingsNotifier(this._ref)
      : super(SettingsState(
          themeMode: ThemeMode.light,
          currency: '₹',
          isNotificationReaderEnabled: false,
          monitoredApps: const [
            'Google Pay', 'PhonePe', 'Paytm', 'BHIM', 'Amazon Pay', 'WhatsApp',
            'SBI', 'HDFC', 'ICICI', 'Axis', 'Kotak', 'PNB', 'Canara', 'Bank of Baroda', 'Union Bank', 'Airtel Payments Bank'
          ],
          isAutoSaveEnabled: false,
        )) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isDark = prefs.getBool('isDarkMode') ?? false;
      final cur = prefs.getString('currency') ?? '₹';
      final readerEnabled = prefs.getBool('isNotificationReaderEnabled') ?? false;
      final autoSave = prefs.getBool('isAutoSaveEnabled') ?? false;
      final apps = prefs.getStringList('monitoredApps') ?? [
        'Google Pay', 'PhonePe', 'Paytm', 'BHIM', 'Amazon Pay', 'WhatsApp',
        'SBI', 'HDFC', 'ICICI', 'Axis', 'Kotak', 'PNB', 'Canara', 'Bank of Baroda', 'Union Bank', 'Airtel Payments Bank'
      ];

      state = SettingsState(
        themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
        currency: cur,
        isNotificationReaderEnabled: readerEnabled,
        monitoredApps: apps,
        isAutoSaveEnabled: autoSave,
      );

      // Sync the enabled packages to CSV on launch if not present
      final csv = prefs.getString('enabledPackagesCsv') ?? '';
      if (csv.isEmpty) {
        final packagesList = <String>[];
        for (final app in apps) {
          packagesList.addAll(_getPackagesForAppName(app));
        }
        await prefs.setString('enabledPackagesCsv', packagesList.join(','));
      }
    } catch (_) {}
  }

  Future<void> _syncToFirestore() async {
    try {
      final user = _ref.read(authStateChangesProvider).value;
      if (user != null && user.uid.isNotEmpty) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'monitoredApps': state.monitoredApps,
          'isNotificationReaderEnabled': state.isNotificationReaderEnabled,
          'isAutoSaveEnabled': state.isAutoSaveEnabled,
          'currency': state.currency,
        }, SetOptions(merge: true));
      }
    } catch (_) {}
  }

  Future<void> toggleTheme(bool isDark) async {
    state = state.copyWith(themeMode: isDark ? ThemeMode.dark : ThemeMode.light);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isDarkMode', isDark);
    } catch (_) {}
  }

  Future<void> changeCurrency(String newCurrency) async {
    state = state.copyWith(currency: newCurrency);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('currency', newCurrency);
      await _syncToFirestore();
    } catch (_) {}
  }

  Future<void> toggleNotificationReader(bool enabled) async {
    state = state.copyWith(isNotificationReaderEnabled: enabled);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isNotificationReaderEnabled', enabled);
      await _syncToFirestore();
    } catch (_) {}
  }

  Future<void> toggleAutoSave(bool enabled) async {
    state = state.copyWith(isAutoSaveEnabled: enabled);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isAutoSaveEnabled', enabled);
      await _syncToFirestore();
    } catch (_) {}
  }

  Future<void> updateMonitoredApps(List<String> apps) async {
    state = state.copyWith(monitoredApps: apps);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('monitoredApps', apps);

      final packagesList = <String>[];
      for (final app in apps) {
        packagesList.addAll(_getPackagesForAppName(app));
      }
      await prefs.setString('enabledPackagesCsv', packagesList.join(','));
      await _syncToFirestore();
    } catch (_) {}
  }

  List<String> _getPackagesForAppName(String appName) {
    switch (appName) {
      case 'Google Pay':
        return ['com.google.android.apps.nbu.paisa.user'];
      case 'PhonePe':
        return ['com.phonepe.app'];
      case 'Paytm':
        return ['net.one97.paytm'];
      case 'BHIM':
        return ['in.org.npci.upiapp'];
      case 'Amazon Pay':
        return ['com.amazon.mShop.android.shopping'];
      case 'WhatsApp':
        return ['com.whatsapp'];
      case 'SBI':
        return ['com.sbi.upi', 'com.sbi.SBIOnyx', 'com.sbi.yono'];
      case 'HDFC':
        return ['com.snapwork.hdfc', 'com.hdfcbank.smartbuy'];
      case 'ICICI':
        return ['com.csam.icici.bank.imobile'];
      case 'Axis':
        return ['com.axis.mobile'];
      case 'Kotak':
        return ['com.msf.kbank.mobile'];
      case 'PNB':
        return ['com.pnb.mbanking'];
      case 'Canara':
        return ['com.canarabank.onetouch'];
      case 'Bank of Baroda':
        return ['com.bobworld.mobile'];
      case 'Union Bank':
        return ['com.unionbank.online'];
      case 'Airtel Payments Bank':
        return ['com.myairtelapp'];
      default:
        return [];
    }
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier(ref);
});
