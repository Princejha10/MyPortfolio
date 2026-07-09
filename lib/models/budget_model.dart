import 'package:cloud_firestore/cloud_firestore.dart';

class BudgetModel {
  final String userId;
  final double monthlyBudget;
  final Map<String, double> categoryBudgets;

  BudgetModel({
    required this.userId,
    required this.monthlyBudget,
    required this.categoryBudgets,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'monthlyBudget': monthlyBudget,
      'categoryBudgets': categoryBudgets,
    };
  }

  factory BudgetModel.fromMap(Map<String, dynamic> map) {
    final rawCategoryBudgets = map['categoryBudgets'] as Map<String, dynamic>? ?? {};
    final Map<String, double> categoryBudgets = {};
    rawCategoryBudgets.forEach((key, value) {
      categoryBudgets[key] = (value as num).toDouble();
    });

    return BudgetModel(
      userId: map['userId'] as String? ?? '',
      monthlyBudget: (map['monthlyBudget'] as num?)?.toDouble() ?? 30000.0,
      categoryBudgets: categoryBudgets,
    );
  }

  factory BudgetModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return BudgetModel.fromMap(data);
  }

  BudgetModel copyWith({
    String? userId,
    double? monthlyBudget,
    Map<String, double>? categoryBudgets,
  }) {
    return BudgetModel(
      userId: userId ?? this.userId,
      monthlyBudget: monthlyBudget ?? this.monthlyBudget,
      categoryBudgets: categoryBudgets ?? this.categoryBudgets,
    );
  }
}
