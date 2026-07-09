import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionModel {
  final String? id; // Firestore Document ID
  final String userId;
  final double amount;
  final String merchant;
  final String category;
  final String type; // 'credit' | 'debit'
  final String paymentMethod;
  final String? upiReference;
  final DateTime timestamp;
  final String notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String source; // 'SMS' | 'Manual' | 'Import'

  TransactionModel({
    this.id,
    required this.userId,
    required this.amount,
    required this.merchant,
    required this.category,
    required this.type,
    required this.paymentMethod,
    this.upiReference,
    required this.timestamp,
    required this.notes,
    this.createdAt,
    this.updatedAt,
    required this.source,
  });

  // Convert a Transaction into a Map for Firestore insertion
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'amount': amount,
      'merchant': merchant,
      'category': category,
      'type': type,
      'paymentMethod': paymentMethod,
      'upiReference': upiReference,
      'timestamp': Timestamp.fromDate(timestamp),
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt ?? DateTime.now()),
      'updatedAt': Timestamp.fromDate(updatedAt ?? DateTime.now()),
      'source': source,
    };
  }

  // Create a Transaction from a Firestore Map
  factory TransactionModel.fromMap(Map<String, dynamic> map, [String? docId]) {
    DateTime parseDateTime(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is String) return DateTime.parse(value);
      if (value is Timestamp) return value.toDate();
      return DateTime.now();
    }

    return TransactionModel(
      id: docId,
      userId: map['userId'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      merchant: map['merchant'] as String? ?? 'Unknown Merchant',
      category: map['category'] as String? ?? 'Others',
      type: map['type'] as String? ?? 'debit',
      paymentMethod: map['paymentMethod'] as String? ?? 'Unknown',
      upiReference: map['upiReference'] as String?,
      timestamp: parseDateTime(map['timestamp']),
      notes: map['notes'] as String? ?? '',
      createdAt: parseDateTime(map['createdAt']),
      updatedAt: parseDateTime(map['updatedAt']),
      source: map['source'] as String? ?? 'Manual',
    );
  }

  // Helper factory to parse direct Firestore Query Document Snapshots
  factory TransactionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return TransactionModel.fromMap(data, doc.id);
  }

  TransactionModel copyWith({
    String? id,
    String? userId,
    double? amount,
    String? merchant,
    String? category,
    String? type,
    String? paymentMethod,
    String? upiReference,
    DateTime? timestamp,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? source,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      merchant: merchant ?? this.merchant,
      category: category ?? this.category,
      type: type ?? this.type,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      upiReference: upiReference ?? this.upiReference,
      timestamp: timestamp ?? this.timestamp,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      source: source ?? this.source,
    );
  }
}
