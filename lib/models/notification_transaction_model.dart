import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationTransaction {
  final String id; // Generated hash for deduplication
  final String userId;
  final double amount;
  final String merchant;
  final DateTime timestamp;
  final String type; // 'credit' | 'debit'
  final String appName; // Google Pay, PhonePe, Paytm, etc.
  final String? upiReference;
  final String rawMessage;
  final String status; // 'pending' | 'confirmed' | 'ignored'
  final String category;

  NotificationTransaction({
    required this.id,
    required this.userId,
    required this.amount,
    required this.merchant,
    required this.timestamp,
    required this.type,
    required this.appName,
    this.upiReference,
    required this.rawMessage,
    required this.status,
    required this.category,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'amount': amount,
      'merchant': merchant,
      'timestamp': timestamp.toIso8601String(),
      'type': type,
      'appName': appName,
      'upiReference': upiReference,
      'rawMessage': rawMessage,
      'status': status,
      'category': category,
    };
  }

  factory NotificationTransaction.fromMap(Map<String, dynamic> map) {
    DateTime parseDateTime(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is String) return DateTime.parse(value);
      if (value is Timestamp) return value.toDate();
      return DateTime.now();
    }

    return NotificationTransaction(
      id: map['id'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      merchant: map['merchant'] as String? ?? 'Unknown Merchant',
      timestamp: parseDateTime(map['timestamp']),
      type: map['type'] as String? ?? 'debit',
      appName: map['appName'] as String? ?? 'Unknown App',
      upiReference: map['upiReference'] as String?,
      rawMessage: map['rawMessage'] as String? ?? '',
      status: map['status'] as String? ?? 'pending',
      category: map['category'] as String? ?? 'Others',
    );
  }

  factory NotificationTransaction.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return NotificationTransaction.fromMap(data);
  }

  NotificationTransaction copyWith({
    String? id,
    String? userId,
    double? amount,
    String? merchant,
    DateTime? timestamp,
    String? type,
    String? appName,
    String? upiReference,
    String? rawMessage,
    String? status,
    String? category,
  }) {
    return NotificationTransaction(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      merchant: merchant ?? this.merchant,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      appName: appName ?? this.appName,
      upiReference: upiReference ?? this.upiReference,
      rawMessage: rawMessage ?? this.rawMessage,
      status: status ?? this.status,
      category: category ?? this.category,
    );
  }
}
