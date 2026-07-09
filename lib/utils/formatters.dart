import 'package:intl/intl.dart';

class Formatters {
  static String activeSymbol = '₹';

  /// Formats double amount into a neat currency string (e.g. ₹28,450 or $28,450)
  static String currency(double amount, {String? symbol}) {
    final String active = symbol ?? activeSymbol;
    final String locale = active == '₹' ? 'en_IN' : 'en_US';
    final format = NumberFormat.currency(
      locale: locale,
      symbol: active,
      decimalDigits: amount % 1 == 0 ? 0 : 2,
    );
    return format.format(amount);
  }

  /// Formats date to a human-readable format (e.g. 05 Oct 2026)
  static String date(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  /// Formats time to a readable format (e.g. 10:45 AM)
  static String time(DateTime date) {
    return DateFormat('hh:mm a').format(date);
  }
}
