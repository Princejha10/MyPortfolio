import '../services/notification_service.dart';
import '../providers/finance_provider.dart';

class TransactionSyncManager {
  final NotificationService _notificationService;
  final FinanceProvider _financeProvider;

  TransactionSyncManager({
    required NotificationService notificationService,
    required FinanceProvider financeProvider,
  })  : _notificationService = notificationService,
        _financeProvider = financeProvider;

  /// Starts listening to the notification stream and forwards parsed details to the finance state.
  void startSyncing() {
    _notificationService.onNotificationTransaction.listen((transaction) {
      // Pass the intercepted transaction to the pending buffer for UI confirmation
      _financeProvider.setPendingTransaction(transaction);
    });
  }
}
