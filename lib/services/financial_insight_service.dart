import '../providers/finance_provider.dart';
import '../utils/formatters.dart';

class FinancialInsightService {
  /// Generates a strict financial summary of the current user's statistics,
  /// including net balances, monthly budget, spending category breakdowns,
  /// and the 10 most recent transactions.
  static String generateSummary(FinanceProvider finance) {
    final balance = finance.balance;
    final budget = finance.monthlyBudget;
    final spent = finance.monthlySpent;
    final remaining = finance.remainingBudget;
    final income = finance.totalIncome;
    final expense = finance.totalExpense;
    final currency = Formatters.activeSymbol;

    // Calculate Monthly Income
    final now = DateTime.now();
    final monthlyIncome = finance.transactions
        .where((t) =>
            t.type.toLowerCase() == 'credit' &&
            t.timestamp.year == now.year &&
            t.timestamp.month == now.month)
        .fold(0.0, (sum, t) => sum + t.amount);

    // Calculate Category Spending
    final categoryTotals = <String, double>{};
    for (final tx in finance.transactions) {
      if (tx.type.toLowerCase() == 'debit') {
        categoryTotals[tx.category] = (categoryTotals[tx.category] ?? 0.0) + tx.amount;
      }
    }

    final categorySummary = categoryTotals.entries
        .map((e) => '- ${e.key}: $currency${e.value.toStringAsFixed(2)}')
        .join('\n');

    // Fetch the 10 most recent transactions
    final sortedTxs = List.from(finance.transactions)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    final recentList = sortedTxs.take(10);
    
    final txsSummary = recentList.map((t) {
      final sign = t.type.toLowerCase() == 'credit' ? '+' : '-';
      return '* [$sign$currency${t.amount.toStringAsFixed(2)}] ${t.merchant} (${t.category}) on ${t.timestamp.day}/${t.timestamp.month}';
    }).join('\n');

    return '''
[METRICS]
Current Net Savings (Balance): $currency${balance.toStringAsFixed(2)}
Monthly Income (Current Month): $currency${monthlyIncome.toStringAsFixed(2)}
Monthly Expenses (Current Month): $currency${spent.toStringAsFixed(2)}
Monthly Budget Limit: $currency${budget.toStringAsFixed(2)}
Remaining Monthly Budget: $currency${remaining.toStringAsFixed(2)}
Lifetime Total Income: $currency${income.toStringAsFixed(2)}
Lifetime Total Expenses: $currency${expense.toStringAsFixed(2)}

[CATEGORY SPENDING BREAKDOWN]
${categorySummary.isEmpty ? 'No category spendings registered.' : categorySummary}

[RECENT TRANSACTIONS (MAX 10)]
${txsSummary.isEmpty ? 'No recent transactions registered.' : txsSummary}
''';
  }
}
