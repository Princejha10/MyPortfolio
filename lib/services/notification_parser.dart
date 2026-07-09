class ParsedNotification {
  final double amount;
  final String merchant;
  final String type; // 'credit' | 'debit'
  final String? upiReference;
  final String paymentMethod;

  ParsedNotification({
    required this.amount,
    required this.merchant,
    required this.type,
    this.upiReference,
    required this.paymentMethod,
  });

  @override
  String toString() {
    return 'ParsedNotification(amount: $amount, merchant: $merchant, type: $type, upiReference: $upiReference, paymentMethod: $paymentMethod)';
  }
}

class NotificationParser {
  /// Parses standard notification text strings to extract financial parameters.
  static ParsedNotification? parse(String message, String sourceApp) {
    final cleaned = message.replaceAll(RegExp(r'\s+'), ' ').trim();
    
    // 1. Extract transaction amount (e.g. ₹450, Rs 500, INR 1250)
    final amountRegex = RegExp(
      r'(?:₹|Rs\.?|INR)\s*([0-9,]+(?:\.[0-9]{1,2})?)', 
      caseSensitive: false
    );
    final amountMatch = amountRegex.firstMatch(cleaned);
    if (amountMatch == null) {
      return null; // Financial text notifications must contain a currency string
    }
    
    final amountStr = amountMatch.group(1)!.replaceAll(',', '');
    final amount = double.tryParse(amountStr) ?? 0.0;
    if (amount <= 0.0) return null;

    // 2. Identify transaction type (debit vs credit)
    String type = 'debit'; 
    final creditKeywords = ['received', 'credited', 'refunded', 'added', 'received from'];
    for (final keyword in creditKeywords) {
      if (cleaned.toLowerCase().contains(keyword)) {
        type = 'credit';
        break;
      }
    }

    // 3. Extract Merchant Name
    String merchant = 'Unknown Merchant';
    
    final paidToRegex = RegExp(
      r'(?:paid\s+to|sent\s+to|transfer\s+to|spent\s+at|debited\s+at)\s+([a-zA-Z0-9\s&]+?)(?:\s+using|\s+via|\s+for|\s+on|\bRs\b|\bUPI\b|\bref\b|\.\s*|$)',
      caseSensitive: false
    );
    
    final receivedFromRegex = RegExp(
      r'(?:received\s+from|credited\s+by|from)\s+([a-zA-Z0-9\s&]+?)(?:\s+using|\s+via|\s+for|\s+on|\bRs\b|\bUPI\b|\bref\b|\.\s*|$)',
      caseSensitive: false
    );

    final paidMatch = paidToRegex.firstMatch(cleaned);
    final receivedMatch = receivedFromRegex.firstMatch(cleaned);

    if (type == 'debit' && paidMatch != null) {
      merchant = paidMatch.group(1)!.trim();
    } else if (type == 'credit' && receivedMatch != null) {
      merchant = receivedMatch.group(1)!.trim();
    } else {
      // Fallback simple "to/from" check
      final simpleToRegex = RegExp(
        r'(?:to|from)\s+([a-zA-Z0-9\s&]+?)(?:\s+using|\s+via|\s+for|\s+on|\.\s*|$)',
        caseSensitive: false
      );
      final simpleMatch = simpleToRegex.firstMatch(cleaned);
      if (simpleMatch != null) {
        merchant = simpleMatch.group(1)!.trim();
      }
    }

    // Sanitize merchant string length and discard numeric noise
    if (merchant.length > 30) {
      merchant = merchant.substring(0, 30).trim();
    }
    if (merchant.isEmpty || RegExp(r'^\d+$').hasMatch(merchant)) {
      merchant = 'Unknown Merchant';
    }

    // 4. Extract UPI reference (commonly a 12-digit transaction ID)
    String? upiReference;
    final upiRegex = RegExp(r'\b([0-9]{12})\b');
    final upiMatch = upiRegex.firstMatch(cleaned);
    if (upiMatch != null) {
      upiReference = upiMatch.group(1);
    }

    // 5. Deduce payment application
    String paymentMethod = sourceApp;
    final cleanApp = sourceApp.toLowerCase();
    
    if (cleanApp.contains('gpay') || cleanApp.contains('google') || cleaned.toLowerCase().contains('gpay')) {
      paymentMethod = 'Google Pay';
    } else if (cleanApp.contains('phonepe') || cleaned.toLowerCase().contains('phonepe')) {
      paymentMethod = 'PhonePe';
    } else if (cleanApp.contains('paytm') || cleaned.toLowerCase().contains('paytm')) {
      paymentMethod = 'Paytm';
    } else if (cleanApp.contains('bhim') || cleaned.toLowerCase().contains('bhim')) {
      paymentMethod = 'BHIM';
    } else if (cleanApp.contains('amazon') || cleaned.toLowerCase().contains('amazon pay')) {
      paymentMethod = 'Amazon Pay';
    }

    return ParsedNotification(
      amount: amount,
      merchant: merchant,
      type: type,
      upiReference: upiReference,
      paymentMethod: paymentMethod,
    );
  }
}
