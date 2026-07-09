import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/finance_provider.dart';
import '../models/transaction_model.dart';
import '../utils/formatters.dart';
import '../core/theme.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  int _activeChartIndex = 0; // 0: Category Pie, 1: Weekly Bar, 2: Daily Line

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final finance = ref.watch(financeProvider);
    final debits = finance.transactions.where((t) => t.type.toLowerCase() == 'debit').toList();

    debugPrint("[LOG] Current UID: ${finance.userId}");
    debugPrint("[LOG] Analytics refresh: Recalculated ${debits.length} debits from Firestore transaction history.");

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Analytics Diagnostics',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
      body: finance.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Chart Type Selector
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppTheme.cardBg,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        _buildChartTab(0, 'Categories'),
                        _buildChartTab(1, 'Weekly Trends'),
                        _buildChartTab(2, 'Daily Spends'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 2. Main Chart Card
                  Container(
                    width: double.infinity,
                    height: 260,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppTheme.borderLight, width: 1.2),
                      boxShadow: AppTheme.cardShadow,
                    ),
                    child: _buildChart(debits),
                  ),
                  const SizedBox(height: 28),

                  // 3. AI Diagnostics / Insights Header
                  Text(
                    'AI Insights & Diagnostics',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  _buildAIInsights(debits, finance),
                  const SizedBox(height: 28),

                  // 4. Largest Expenses Header
                  Text(
                    'Largest Expenses',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  _buildLargestExpenses(debits, theme),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  // Segment Tab Helper
  Widget _buildChartTab(int index, String label) {
    final isSelected = _activeChartIndex == index;
    final theme = Theme.of(context);
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeChartIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? theme.colorScheme.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected ? AppTheme.cardShadow : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? theme.colorScheme.primary : AppTheme.textMuted,
            ),
          ),
        ),
      ),
    );
  }

  // Renders the selected chart
  Widget _buildChart(List<TransactionModel> debits) {
    if (debits.isEmpty) {
      return const Center(child: Text('No expenses recorded for charts.'));
    }

    switch (_activeChartIndex) {
      case 0:
        return _buildPieChart(debits);
      case 1:
        return _buildBarChart(debits);
      case 2:
        return _buildLineChart(debits);
      default:
        return Container();
    }
  }

  // PIE CHART: Category Breakdown
  Widget _buildPieChart(List<TransactionModel> debits) {
    final Map<String, double> categorySums = {};
    for (final tx in debits) {
      categorySums[tx.category] = (categorySums[tx.category] ?? 0.0) + tx.amount;
    }

    final total = categorySums.values.fold(0.0, (sum, val) => sum + val);

    final List<PieChartSectionData> sections = [];
    int index = 0;

    categorySums.forEach((category, sum) {
      final percentage = (sum / total) * 100;
      sections.add(
        PieChartSectionData(
          color: _getChartColor(index),
          value: sum,
          title: '${percentage.toStringAsFixed(0)}%',
          radius: 40,
          titleStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
      index++;
    });

    return Row(
      children: [
        Expanded(
          flex: 4,
          child: PieChart(
            PieChartData(
              sectionsSpace: 3,
              centerSpaceRadius: 45,
              sections: sections,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 3,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(categorySums.length, (i) {
                final category = categorySums.keys.elementAt(i);
                final sum = categorySums.values.elementAt(i);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: _getChartColor(i),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          category,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        Formatters.currency(sum),
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ),
      ],
    );
  }

  // BAR CHART: Weekly Trends (Daily spends over the last 7 days)
  Widget _buildBarChart(List<TransactionModel> debits) {
    final now = DateTime.now();
    final List<double> values = List.filled(7, 0.0);
    final List<String> labels = List.filled(7, '');

    for (int i = 0; i < 7; i++) {
      final date = now.subtract(Duration(days: 6 - i));
      labels[i] = _getDayOfWeekLabel(date.weekday);

      // Sum all debits matching this calendar day
      final daySum = debits
          .where((t) =>
              t.timestamp.year == date.year &&
              t.timestamp.month == date.month &&
              t.timestamp.day == date.day)
          .fold(0.0, (sum, t) => sum + t.amount);
      values[i] = daySum;
    }

    final maxVal = values.reduce((a, b) => a > b ? a : b);
    final maxY = maxVal == 0 ? 1000.0 : maxVal * 1.15;

    return Column(
      children: [
        const Text(
          'Past 7 Days Expenses',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textMuted),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: BarChart(
            BarChartData(
              maxY: maxY,
              barGroups: List.generate(7, (i) {
                return BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: values[i],
                      color: Theme.of(context).colorScheme.primary,
                      width: 14,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                );
              }),
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (val, meta) {
                      if (val.toInt() >= 0 && val.toInt() < 7) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            labels[val.toInt()],
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textMuted),
                          ),
                        );
                      }
                      return const Text('');
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // LINE CHART: Daily Spending Trend Curve
  Widget _buildLineChart(List<TransactionModel> debits) {
    final now = DateTime.now();
    final List<FlSpot> spots = [];
    final List<String> labels = List.filled(7, '');

    for (int i = 0; i < 7; i++) {
      final date = now.subtract(Duration(days: 6 - i));
      labels[i] = '${date.day}/${date.month}';

      final daySum = debits
          .where((t) =>
              t.timestamp.year == date.year &&
              t.timestamp.month == date.month &&
              t.timestamp.day == date.day)
          .fold(0.0, (sum, t) => sum + t.amount);

      spots.add(FlSpot(i.toDouble(), daySum));
    }

    final maxVal = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final maxY = maxVal == 0 ? 1000.0 : maxVal * 1.2;

    return Column(
      children: [
        const Text(
          'Daily Expense Volatility',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textMuted),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: LineChart(
            LineChartData(
              minY: 0,
              maxY: maxY,
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (val, meta) {
                      if (val.toInt() >= 0 && val.toInt() < 7) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            labels[val.toInt()],
                            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.textMuted),
                          ),
                        );
                      }
                      return const Text('');
                    },
                  ),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: AppTheme.accentOrange,
                  barWidth: 3,
                  dotData: const FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true,
                    color: AppTheme.accentOrange.withOpacity(0.08),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Helper colors for pie segments
  Color _getChartColor(int index) {
    const List<Color> colors = [
      AppTheme.primary,
      AppTheme.accentOrange,
      AppTheme.accentGreen,
      Color(0xFF8F7A6E),
      Color(0xFF6B5A7D),
      Color(0xFF90A4AE),
      Color(0xFF795548),
      Color(0xFF8D6E63),
      Color(0xFFB0BEC5),
    ];
    return colors[index % colors.length];
  }

  String _getDayOfWeekLabel(int day) {
    switch (day) {
      case DateTime.monday:
        return 'Mon';
      case DateTime.tuesday:
        return 'Tue';
      case DateTime.wednesday:
        return 'Wed';
      case DateTime.thursday:
        return 'Thu';
      case DateTime.friday:
        return 'Fri';
      case DateTime.saturday:
        return 'Sat';
      case DateTime.sunday:
        return 'Sun';
      default:
        return '';
    }
  }

  // 4. Dynamic AI Insights Section
  Widget _buildAIInsights(List<TransactionModel> debits, FinanceProvider finance) {
    final theme = Theme.of(context);
    
    // Heuristic calculations
    final foodTotal = debits.where((t) => t.category.toLowerCase() == 'food').fold(0.0, (sum, t) => sum + t.amount);
    final groceryTotal = debits.where((t) => t.category.toLowerCase() == 'grocery').fold(0.0, (sum, t) => sum + t.amount);
    
    // Find most visited merchant
    final Map<String, int> merchantCounts = {};
    for (final tx in debits) {
      merchantCounts[tx.merchant] = (merchantCounts[tx.merchant] ?? 0) + 1;
    }
    String topMerchant = 'None';
    int maxCount = 0;
    merchantCounts.forEach((merchant, count) {
      if (count > maxCount) {
        maxCount = count;
        topMerchant = merchant;
      }
    });

    final List<String> textInsights = [];
    if (foodTotal > 0) {
      textInsights.add('You spent ${Formatters.activeSymbol}${foodTotal.toStringAsFixed(0)} on food this month. Consider cooking at home to optimize savings.');
    }
    if (topMerchant != 'None') {
      textInsights.add('Most visited merchant: $topMerchant ($maxCount times).');
    }
    if (groceryTotal > 1500) {
      textInsights.add('You spent ${Formatters.activeSymbol}${groceryTotal.toStringAsFixed(0)} on groceries. Purchasing bulk grocery items once a week can save you up to 10%.');
    } else {
      textInsights.add('You can save approximately ${Formatters.activeSymbol}2,000 next month by reducing food delivery (like Swiggy).');
    }

    return Column(
      children: textInsights.map((insight) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderLight, width: 1.0),
            boxShadow: AppTheme.cardShadow,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.auto_awesome_rounded, color: theme.colorScheme.primary, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  insight,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textDark,
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // 5. Largest expenses layout
  Widget _buildLargestExpenses(List<TransactionModel> debits, ThemeData theme) {
    if (debits.isEmpty) {
      return const Center(child: Text('No expenses recorded.'));
    }

    final sorted = List<TransactionModel>.from(debits);
    sorted.sort((a, b) => b.amount.compareTo(a.amount));
    final topThree = sorted.take(3).toList();

    return Column(
      children: topThree.map((tx) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderLight, width: 1.0),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tx.merchant,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${tx.category} • ${Formatters.date(tx.timestamp)}',
                    style: const TextStyle(fontSize: 10.5, color: AppTheme.textMuted),
                  ),
                ],
              ),
              Text(
                Formatters.currency(tx.amount),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppTheme.accentOrange,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
