import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_transaction_model.dart';

class NotificationInboxRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Stream notifications for a user filtered by status ('pending', 'confirmed', 'ignored')
  Stream<List<NotificationTransaction>> getNotificationsStream(String userId, String status) {
    if (userId.isEmpty) return Stream.value([]);
    
    return _firestore
        .collection('notificationInbox')
        .doc(userId)
        .collection('transactions')
        .where('status', isEqualTo: status)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => NotificationTransaction.fromFirestore(doc)).toList();
    });
  }

  /// Check if a notification ID already exists in the database to prevent duplicates
  Future<bool> hasTransaction(String userId, String id) async {
    if (userId.isEmpty || id.isEmpty) return false;
    
    try {
      final doc = await _firestore
          .collection('notificationInbox')
          .doc(userId)
          .collection('transactions')
          .doc(id)
          .get();
      return doc.exists;
    } catch (_) {
      return false;
    }
  }

  /// Save a newly detected notification transaction in Firestore
  Future<void> saveNotification(String userId, NotificationTransaction transaction) async {
    if (userId.isEmpty) return;
    
    await _firestore
        .collection('notificationInbox')
        .doc(userId)
        .collection('transactions')
        .doc(transaction.id)
        .set(transaction.toMap(), SetOptions(merge: true));
  }

  /// Update the status of an intercepted notification ('confirmed' or 'ignored')
  Future<void> updateNotificationStatus(String userId, String id, String status) async {
    if (userId.isEmpty || id.isEmpty) return;
    
    await _firestore
        .collection('notificationInbox')
        .doc(userId)
        .collection('transactions')
        .doc(id)
        .update({'status': status});
  }

  /// Permanently delete an intercepted notification record
  Future<void> deleteNotification(String userId, String id) async {
    if (userId.isEmpty || id.isEmpty) return;
    
    await _firestore
        .collection('notificationInbox')
        .doc(userId)
        .collection('transactions')
        .doc(id)
        .delete();
  }
}
