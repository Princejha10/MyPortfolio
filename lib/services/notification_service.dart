import 'dart:async';
import 'package:flutter/services.dart';
import '../models/transaction_model.dart';
import '../services/notification_parser.dart';
import '../services/ai_expense_categorizer.dart';

/// Abstract interface for application notification parsing services.
/// Defines contracts for requesting permission, starting/stopping listener,
/// and retrieving parsed transactions.
abstract class NotificationService {
  /// Request system permission for observing notifications (e.g. notification access on Android).
  Future<bool> requestPermission();

  /// Check whether the listener permission is currently granted.
  Future<bool> isPermissionGranted();

  /// Start observing notifications.
  Future<void> startListening();

  /// Stop observing notifications.
  Future<void> stopListening();

  /// Fetch recently intercepted or processed transactions.
  Future<List<TransactionModel>> getTransactions();

  /// Stream of new transactions parsed from notifications in real-time.
  Stream<TransactionModel> get onNotificationTransaction;

  /// Stream of raw notifications (message and package name) received in real-time.
  Stream<Map<String, String>> get onRawNotification;
}

/// Android-specific listener implementation.
/// Binds platform channels targeting Android's NotificationListenerService.
class AndroidNotificationService implements NotificationService {
  static const MethodChannel _methodChannel = MethodChannel('com.finsense.ai/notifications');
  static const EventChannel _eventChannel = EventChannel('com.finsense.ai/notification_stream');

  final StreamController<TransactionModel> _controller = StreamController<TransactionModel>.broadcast();
  final StreamController<Map<String, String>> _rawController = StreamController<Map<String, String>>.broadcast();
  StreamSubscription? _subscription;
  bool _isListening = false;

  AndroidNotificationService() {
    // Connect event stream subscription
    _subscription = _eventChannel.receiveBroadcastStream().listen(
      (event) {
        try {
          if (event is Map) {
            final message = event['message'] as String?;
            final packageName = event['packageName'] as String?;
            
            if (message != null && message.trim().isNotEmpty && packageName != null) {
              // 1. Emit raw notification event
              _rawController.add({
                'message': message,
                'packageName': packageName,
              });

              // 2. Backward compatibility: parse locally and emit TransactionModel if enabled
              if (!_isListening) return;
              final parsed = NotificationParser.parse(message, packageName);
              if (parsed != null) {
                final category = AIExpenseCategorizer.categorize(parsed.merchant);
                final tx = TransactionModel(
                  userId: '',
                  amount: parsed.amount,
                  merchant: parsed.merchant,
                  category: category,
                  type: parsed.type,
                  paymentMethod: parsed.paymentMethod,
                  upiReference: parsed.upiReference,
                  timestamp: DateTime.now(),
                  notes: 'Auto-captured via $packageName',
                  source: 'SMS',
                );
                _controller.add(tx);
              }
            }
          }
        } catch (_) {}
      },
      onError: (_) {},
    );
  }

  @override
  Future<bool> requestPermission() async {
    try {
      final bool? result = await _methodChannel.invokeMethod<bool>('requestPermission');
      return result ?? false;
    } on PlatformException catch (_) {
      return false;
    }
  }

  @override
  Future<bool> isPermissionGranted() async {
    try {
      final bool? result = await _methodChannel.invokeMethod<bool>('checkPermission');
      return result ?? false;
    } on PlatformException catch (_) {
      return false;
    }
  }

  /// Retrieve package name from native side for debugging audit
  Future<String> getPackageName() async {
    try {
      final String? result = await _methodChannel.invokeMethod<String>('getPackageName');
      return result ?? 'Unknown Package';
    } on PlatformException catch (e) {
      return 'Error: ${e.message}';
    }
  }

  @override
  Future<void> startListening() async {
    _isListening = true;
    try {
      await _methodChannel.invokeMethod('startListening');
    } on PlatformException catch (_) {}
  }

  @override
  Future<void> stopListening() async {
    _isListening = false;
    try {
      await _methodChannel.invokeMethod('stopListening');
    } on PlatformException catch (_) {}
  }

  @override
  Future<List<TransactionModel>> getTransactions() async {
    return [];
  }

  @override
  Stream<TransactionModel> get onNotificationTransaction => _controller.stream;

  @override
  Stream<Map<String, String>> get onRawNotification => _rawController.stream;

  /// Helper to trigger a simulated notification intercept inside the app.
  void simulateNotificationIntercept(TransactionModel transaction) {
    _controller.add(transaction);
  }

  void dispose() {
    _subscription?.cancel();
    _controller.close();
    _rawController.close();
  }
}

/// iOS-specific implementation. iOS sandboxing forbids reading notification lists from other apps.
/// Relies entirely on Manual Input, CSV imports, or Demo Data mode.
class IosNotificationService implements NotificationService {
  @override
  Future<bool> requestPermission() async {
    return false;
  }

  @override
  Future<bool> isPermissionGranted() async {
    return false;
  }

  @override
  Future<void> startListening() async {
    // No-op on iOS
  }

  @override
  Future<void> stopListening() async {
    // No-op on iOS
  }

  @override
  Future<List<TransactionModel>> getTransactions() async {
    return [];
  }

  @override
  Stream<TransactionModel> get onNotificationTransaction => const Stream.empty();

  @override
  Stream<Map<String, String>> get onRawNotification => const Stream.empty();
}
