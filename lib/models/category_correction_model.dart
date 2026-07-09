import 'package:cloud_firestore/cloud_firestore.dart';

class CategoryCorrectionModel {
  final String userId;
  final String merchant; // Case-insensitive merchant name key
  final String correctedCategory;

  CategoryCorrectionModel({
    required this.userId,
    required this.merchant,
    required this.correctedCategory,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'merchant': merchant.trim().toLowerCase(),
      'correctedCategory': correctedCategory,
    };
  }

  factory CategoryCorrectionModel.fromMap(Map<String, dynamic> map) {
    return CategoryCorrectionModel(
      userId: map['userId'] as String? ?? '',
      merchant: map['merchant'] as String? ?? '',
      correctedCategory: map['correctedCategory'] as String? ?? 'Others',
    );
  }

  factory CategoryCorrectionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return CategoryCorrectionModel.fromMap(data);
  }
}
