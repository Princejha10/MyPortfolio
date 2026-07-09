import 'package:cloud_firestore/cloud_firestore.dart';

abstract class UserRepository {
  Future<void> updateManualBalance({
    required String uid,
    required double newBalance,
    required double oldBalance,
    required String reason,
  });
}

class FirestoreUserRepository implements UserRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<void> updateManualBalance({
    required String uid,
    required double newBalance,
    required double oldBalance,
    required String reason,
  }) async {
    final now = FieldValue.serverTimestamp();
    final batch = _firestore.batch();

    // 1. Update user document
    final userRef = _firestore.collection('users').doc(uid);
    batch.set(userRef, {
      'currentBalance': newBalance,
      'updatedAt': now,
      'reason': reason,
    }, SetOptions(merge: true));

    // 2. Add history record
    final historyRef = _firestore
        .collection('users')
        .doc(uid)
        .collection('balanceHistory')
        .doc();
        
    batch.set(historyRef, {
      'oldBalance': oldBalance,
      'newBalance': newBalance,
      'reason': reason,
      'updatedAt': now,
    });

    await batch.commit();
  }
}
