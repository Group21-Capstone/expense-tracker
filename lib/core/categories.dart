import 'package:flutter/material.dart';

/// Single source of truth for transaction categories and their display colors.
/// Used by the add/edit form and the chart widgets so the three never drift.
class Categories {
  static const List<String> all = [
    'Food',
    'Transport',
    'Shopping',
    'Entertainment',
    'Bills',
    'Health',
    'Salary',
    'Investment',
    'Other',
  ];

  static const Map<String, Color> colors = {
    'Food': Colors.orange,
    'Transport': Colors.blue,
    'Shopping': Colors.pink,
    'Entertainment': Colors.purple,
    'Bills': Colors.red,
    'Health': Colors.green,
    'Salary': Colors.teal,
    'Investment': Colors.indigo,
    'Other': Colors.grey,
  };

  static Color colorFor(String category) => colors[category] ?? Colors.grey;
}
