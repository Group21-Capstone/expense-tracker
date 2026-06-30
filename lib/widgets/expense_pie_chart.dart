import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/transaction_model.dart';
import '../core/categories.dart';

class ExpensePieChart extends StatelessWidget {
  final List<Transaction> transactions;

  const ExpensePieChart({super.key, required this.transactions});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // SUM EXPENSES BY CATEGORY
    final Map<String, double> categoryTotals = {};

    for (var t in transactions) {
      if (t.type == TransactionType.expense) {
        categoryTotals[t.category] =
            (categoryTotals[t.category] ?? 0) + t.amount;
      }
    }

    if (categoryTotals.isEmpty) {
      return Center(
        child: Text("No expenses yet", style: theme.textTheme.bodyMedium),
      );
    }

    final total = categoryTotals.values.fold(0.0, (a, b) => a + b);

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              startDegreeOffset: -90,
              borderData: FlBorderData(show: false),
              sections: categoryTotals.entries.map((entry) {
                final category = entry.key;
                final amount = entry.value;
                final percentage = (amount / total) * 100;

                return PieChartSectionData(
                  color: Categories.colorFor(category),
                  value: amount,
                  title: "${percentage.toStringAsFixed(1)}%",
                  radius: 60,
                  titleStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 12,
                  ),
                );
              }).toList(),
            ),
          ),
        ),

        const SizedBox(height: 20),

        // LEGEND
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: categoryTotals.entries.map((entry) {
            final category = entry.key;
            final color = Categories.colorFor(category);

            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(category, style: theme.textTheme.bodyMedium),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}
