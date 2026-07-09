import '../repositories/transaction_repository.dart';

class AIExpenseCategorizer {
  // In-memory cache of user category corrections
  static final Map<String, String> _userCorrections = {};

  /// Loads custom category overrides from Firestore into memory cache.
  static Future<void> loadUserCorrections(TransactionRepository repository, String userId) async {
    try {
      final corrections = await repository.getAllCategoryCorrections(userId);
      _userCorrections.clear();
      _userCorrections.addAll(corrections);
    } catch (_) {
      // Gracefully handle network offline states during startup
    }
  }

  /// Persists a merchant category override correction in Firestore and updates memory cache.
  static Future<void> saveUserCorrection(
    String merchant,
    String category,
    TransactionRepository repository,
    String userId,
  ) async {
    final key = merchant.trim().toLowerCase();
    _userCorrections[key] = category;
    try {
      await repository.saveCategoryCorrection(userId, merchant, category);
    } catch (_) {}
  }

  static const Map<String, String> _mappings = {
    'blinkit': 'Grocery',
    'reliance fresh': 'Grocery',
    'bigbasket': 'Grocery',
    'instamart': 'Grocery',
    'grofers': 'Grocery',
    'dmart': 'Grocery',
    
    'swiggy': 'Food',
    'zomato': 'Food',
    'starbucks': 'Food',
    'mcdonald': 'Food',
    'kfc': 'Food',
    'burger king': 'Food',
    'restaurant': 'Food',
    'cafe': 'Food',
    
    'amazon': 'Shopping',
    'flipkart': 'Shopping',
    'myntra': 'Shopping',
    'zara': 'Shopping',
    'meesho': 'Shopping',
    'ajio': 'Shopping',
    
    'uber': 'Travel',
    'ola': 'Travel',
    'rapido': 'Travel',
    'irctc': 'Travel',
    'metro': 'Travel',
    'indigo': 'Travel',
    
    'netflix': 'Entertainment',
    'spotify': 'Entertainment',
    'youtube': 'Entertainment',
    'bookmyshow': 'Entertainment',
    'hotstar': 'Entertainment',
    'prime video': 'Entertainment',
    
    'reliance energy': 'Bills',
    'airtel': 'Bills',
    'jio': 'Bills',
    'electricity': 'Bills',
    'gas': 'Bills',
    'broadband': 'Bills',
    
    'apollo': 'Healthcare',
    'practo': 'Healthcare',
    'pharmeasy': 'Healthcare',
    'max healthcare': 'Healthcare',
    'hospital': 'Healthcare',
    'clinic': 'Healthcare',
    'medical': 'Healthcare',

    'petrol': 'Fuel',
    'hpcl': 'Fuel',
    'bpcl': 'Fuel',
    'shell': 'Fuel',
    'fuel': 'Fuel',
  };

  /// Automatically categorizes a transaction based on the merchant name.
  static String categorize(String merchant) {
    final cleaned = merchant.trim().toLowerCase();
    
    // 1. Check user corrections cache first
    if (_userCorrections.containsKey(cleaned)) {
      return _userCorrections[cleaned]!;
    }
    for (final entry in _userCorrections.entries) {
      if (cleaned.contains(entry.key)) {
        return entry.value;
      }
    }
    
    // 2. Check default standard rules
    for (final entry in _mappings.entries) {
      if (cleaned.contains(entry.key)) {
        return entry.value;
      }
    }
    
    return 'Others';
  }

  /// Returns the default list of categories supported by the application.
  static List<String> get categories => [
    'Food',
    'Shopping',
    'Bills',
    'Entertainment',
    'Transport',
    'Healthcare',
    'Education',
    'Travel',
    'Investment',
    'Others',
  ];
}
