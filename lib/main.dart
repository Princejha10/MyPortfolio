import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme.dart';
import 'services/notification_service.dart';
import 'services/transaction_sync_manager.dart';
import 'services/initialization_service.dart';
import 'providers/finance_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/settings_provider.dart';
import 'utils/formatters.dart';
import 'screens/main_screen.dart';
import 'screens/auth/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Cross-platform safe service resolution
  NotificationService notificationService;
  if (kIsWeb) {
    notificationService = IosNotificationService();
  } else {
    try {
      if (Platform.isAndroid) {
        notificationService = AndroidNotificationService();
      } else {
        notificationService = IosNotificationService();
      }
    } catch (_) {
      notificationService = IosNotificationService();
    }
  }

  runApp(
    ProviderScope(
      overrides: [
        // Inject the safe notification service instance into the global Riverpod system
        notificationServiceProvider.overrideWithValue(notificationService),
      ],
      child: const FinSenseApp(),
    ),
  );
}

class FinSenseApp extends ConsumerStatefulWidget {
  const FinSenseApp({super.key});

  @override
  ConsumerState<FinSenseApp> createState() => _FinSenseAppState();
}

class _FinSenseAppState extends ConsumerState<FinSenseApp> {
  bool _syncManagerInitialized = false;

  @override
  Widget build(BuildContext context) {
    final init = ref.watch(InitializationService.provider);

    return init.when(
      data: (_) {
        final authState = ref.watch(authStateChangesProvider);
        final settings = ref.watch(settingsProvider);
        Formatters.activeSymbol = settings.currency;

        return MaterialApp(
          title: 'FinSense AI',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: settings.themeMode,
          home: authState.when(
            data: (user) {
              if (user != null) {
                // Lazy-initialize the transaction listener once logged in
                if (!_syncManagerInitialized) {
                  _syncManagerInitialized = true;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    final finance = ref.read(financeProvider);
                    final notification = ref.read(notificationServiceProvider);
                    TransactionSyncManager(
                      notificationService: notification,
                      financeProvider: finance,
                    ).startSyncing();
                  });
                }
                return const MainScreen();
              }
              _syncManagerInitialized = false;
              return const LoginScreen();
            },
            loading: () => const SplashScreen(),
            error: (err, stack) => Scaffold(
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(28.0),
                  child: Text(
                    'Authentication error: $err',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppTheme.accentOrange),
                  ),
                ),
              ),
            ),
          ),
        );
      },
      loading: () => MaterialApp(
        title: 'FinSense AI',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const SplashScreen(),
      ),
      error: (err, stack) => MaterialApp(
        title: 'FinSense AI',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(28.0),
              child: Text(
                'Initialization error: $err\n\nPlease check your internet connection and try again.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.accentOrange, fontSize: 13, height: 1.5),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                Icons.analytics_rounded,
                color: theme.colorScheme.primary,
                size: 64,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'FinSense AI',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your Premium Financial Companion',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 48),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
