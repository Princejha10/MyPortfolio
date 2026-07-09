import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/transaction_model.dart';

abstract class TransactionRepository {
  /// Stream observing transaction lists in real-time under users/{userId}/transactions.
  Stream<List<TransactionModel>> getTransactionsStream(String userId);

  /// Insert a new transaction into Cloud Firestore.
  Future<TransactionModel> insertTransaction(TransactionModel transaction);

  /// Remove a transaction from Cloud Firestore by Document ID.
  Future<void> deleteTransaction(String userId, String id);

  /// Update an existing transaction in Cloud Firestore.
  Future<void> updateTransaction(TransactionModel transaction);

  /// Wipe all transactions belonging to a specific user (batch write).
  Future<void> clearAllTransactions(String userId);

  /// Retrieve all user-entered custom category corrections.
  Future<Map<String, String>> getAllCategoryCorrections(String userId);

  /// Save a user-defined category correction for a specific merchant name.
  Future<void> saveCategoryCorrection(String userId, String merchant, String category);
}

class FirestoreTransactionRepository implements TransactionRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  FirestoreTransactionRepository() {
    _firestore.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }

  @override
  Stream<List<TransactionModel>> getTransactionsStream(String userId) {
    debugPrint("[LOG] Transaction read (stream) for UID: $userId, path: users/$userId/transactions");
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('transactions')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      debugPrint("[LOG] Realtime update: Received ${snapshot.docs.length} transactions from users/$userId/transactions");
      return snapshot.docs
          .map((doc) => TransactionModel.fromFirestore(doc))
          .toList();
    });
  }

  @override
  Future<TransactionModel> insertTransaction(TransactionModel transaction) async {
    final uid = transaction.userId;
    final docRef = _firestore
        .collection('users')
        .doc(uid)
        .collection('transactions')
        .doc();

    final updatedTx = transaction.copyWith(
      id: docRef.id,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    debugPrint("[LOG] 2. Database path being written: users/$uid/transactions/${docRef.id}");
    await docRef.set(updatedTx.toMap());
    debugPrint("[LOG] 3. Save success with document ID: ${docRef.id}");
    return updatedTx;
  }

  @override
  Future<void> deleteTransaction(String userId, String id) async {
    debugPrint("[LOG] Transaction write (delete) at: users/$userId/transactions/$id");
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('transactions')
        .doc(id)
        .delete();
  }

  @override
  Future<void> updateTransaction(TransactionModel transaction) async {
    final uid = transaction.userId;
    final id = transaction.id;
    if (id == null) return;

    final docRef = _firestore
        .collection('users')
        .doc(uid)
        .collection('transactions')
        .doc(id);

    final updatedTx = transaction.copyWith(updatedAt: DateTime.now());
    debugPrint("[LOG] Transaction write (update) at: users/$uid/transactions/$id");
    await docRef.update(updatedTx.toMap());
  }

  @override
  Future<void> clearAllTransactions(String userId) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('transactions')
        .get();

    debugPrint("[LOG] Clearing ${snapshot.docs.length} transactions at users/$userId/transactions");
    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  @override
  Future<Map<String, String>> getAllCategoryCorrections(String userId) async {
    final snapshot = await _firestore
        .collection('merchantMappings')
        .where('userId', isEqualTo: userId)
        .get(const GetOptions(source: Source.serverAndCache));

    final Map<String, String> corrections = {};
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final merchant = data['merchant'] as String? ?? '';
      final category = data['correctedCategory'] as String? ?? '';
      if (merchant.isNotEmpty) {
        corrections[merchant.toLowerCase()] = category;
      }
    }
    return corrections;
  }

  @override
  Future<void> saveCategoryCorrection(String userId, String merchant, String category) async {
    final key = merchant.trim().toLowerCase();
    final docId = '${userId}_$key';

    await _firestore.collection('merchantMappings').doc(docId).set({
      'userId': userId,
      'merchant': key,
      'correctedCategory': category,
    }, SetOptions(merge: true));
  }
}
