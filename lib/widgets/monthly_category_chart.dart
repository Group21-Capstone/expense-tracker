import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../core/categories.dart';

class MonthlyCategoryBarChart extends StatelessWidget {
  final Map<String, double> categoryBreakdown;
  final String selectedMonth;

  const MonthlyCategoryBarChart({
    super.key,
    required this.categoryBreakdown,
    required this.selectedMonth,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (categoryBreakdown.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            "No expenses this month.",
            style: theme.textTheme.bodyMedium,
          ),
        ),
      );
    }

    final entries = categoryBreakdown.entries.toList();
    final maxValue = entries.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    final maxY = maxValue * 1.3;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => theme.colorScheme.surface,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final cat = entries[group.x].key;
              return BarTooltipItem(
                '$cat\n\$${rod.toY.toStringAsFixed(2)}',
                TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
        ),
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                if (value == meta.max) return const SizedBox();
                return Text(
                  '\$${value.toInt()}',
                  style: theme.textTheme.bodySmall,
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= entries.length) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    entries[i].key,
                    style: theme.textTheme.bodySmall,
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: List.generate(entries.length, (i) {
          final e = entries[i];
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: e.value,
                color: Categories.colorFor(e.key),
                width: 22,
                borderRadius: BorderRadius.circular(6),
              ),
            ],
          );
        }),
      ),
    );
  }
}
