import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/budget_model.dart';

abstract class BudgetRepository {
  /// Stream to listen to real-time budget config updates for a specific user.
  Stream<BudgetModel> getBudgetStream(String userId);

  /// Fetch budget details synchronously or from cache.
  Future<BudgetModel> getBudget(String userId);

  /// Save budget configurations.
  Future<void> saveBudget(BudgetModel budget);
}

class FirestoreBudgetRepository implements BudgetRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Stream<BudgetModel> getBudgetStream(String userId) {
    return _firestore
        .collection('budgets')
        .doc(userId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        return BudgetModel(
          userId: userId,
          monthlyBudget: 30000.0,
          categoryBudgets: const {},
        );
      }
      return BudgetModel.fromFirestore(snapshot);
    });
  }

  @override
  Future<BudgetModel> getBudget(String userId) async {
    final doc = await _firestore.collection('budgets').doc(userId).get();
    if (!doc.exists || doc.data() == null) {
      return BudgetModel(
        userId: userId,
        monthlyBudget: 30000.0,
        categoryBudgets: const {},
      );
    }
    return BudgetModel.fromFirestore(doc);
  }

  @override
  Future<void> saveBudget(BudgetModel budget) async {
    await _firestore.collection('budgets').doc(budget.userId).set(budget.toMap());
  }
}
