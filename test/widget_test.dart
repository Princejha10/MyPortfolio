import 'package:flutter_test/flutter_test.dart';
import 'package:finsense_ai/services/ai_expense_categorizer.dart';
import 'package:finsense_ai/services/notification_parser.dart';
import 'package:finsense_ai/models/transaction_model.dart';
import 'package:finsense_ai/repositories/transaction_repository.dart';

class FakeTransactionRepository implements TransactionRepository {
  final Map<String, String> corrections = {};
  
  @override
  Stream<List<TransactionModel>> getTransactionsStream(String userId) => Stream.value([]);
  
  @override
  Future<Map<String, String>> getAllCategoryCorrections(String userId) async => corrections;
  
  @override
  Future<void> saveCategoryCorrection(String userId, String merchant, String category) async {
    corrections[merchant.toLowerCase()] = category;
  }
  
  Future<String?> getCategoryCorrection(String merchant) async => corrections[merchant.toLowerCase()];

  @override
  Future<TransactionModel> insertTransaction(TransactionModel transaction) async => transaction;
  
  @override
  Future<void> deleteTransaction(String userId, String id) async {}
  
  @override
  Future<void> updateTransaction(TransactionModel transaction) async {}
  
  @override
  Future<void> clearAllTransactions(String userId) async {}
}

void main() {
  group('NotificationParser Regex Tests', () {
    test('Should parse: ₹450 paid to Blinkit', () {
      final parsed = NotificationParser.parse('₹450 paid to Blinkit', 'Google Pay');
      expect(parsed, isNotNull);
      expect(parsed!.amount, equals(450.0));
      expect(parsed.merchant, equals('Blinkit'));
      expect(parsed.type, equals('debit'));
      expect(parsed.paymentMethod, equals('Google Pay'));
    });

    test('Should parse: Paid ₹250 to Swiggy', () {
      final parsed = NotificationParser.parse('Paid ₹250 to Swiggy', 'PhonePe');
      expect(parsed, isNotNull);
      expect(parsed!.amount, equals(250.0));
      expect(parsed.merchant, equals('Swiggy'));
      expect(parsed.type, equals('debit'));
      expect(parsed.paymentMethod, equals('PhonePe'));
    });

    test('Should parse: Received ₹1000 from Rahul', () {
      final parsed = NotificationParser.parse('Received ₹1000 from Rahul', 'BHIM');
      expect(parsed, isNotNull);
      expect(parsed!.amount, equals(1000.0));
      expect(parsed.merchant, equals('Rahul'));
      expect(parsed.type, equals('credit'));
      expect(parsed.paymentMethod, equals('BHIM'));
    });

    test('Should parse UPI Reference Code', () {
      final parsed = NotificationParser.parse('Paid ₹120 to Swiggy Ref: 123456789012', 'Paytm');
      expect(parsed, isNotNull);
      expect(parsed!.upiReference, equals('123456789012'));
    });

    test('Should return null for non-financial notification: UPI payment successful', () {
      final parsed = NotificationParser.parse('UPI payment successful', 'Google Pay');
      expect(parsed, isNull);
    });
  });

  group('AIExpenseCategorizer Memory Correction Tests', () {
    final fakeRepo = FakeTransactionRepository();
    const testUserId = "test_user_id";

    test('Default categorization should check mappings', () async {
      await AIExpenseCategorizer.loadUserCorrections(fakeRepo, testUserId);
      expect(AIExpenseCategorizer.categorize('Swiggy'), equals('Food'));
    });

    test('Should apply user-corrected override mapping', () async {
      await AIExpenseCategorizer.saveUserCorrection('Swiggy', 'Bills', fakeRepo, testUserId);
      expect(AIExpenseCategorizer.categorize('Swiggy'), equals('Bills'));
    });
  });
}
