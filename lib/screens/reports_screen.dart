import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:exp/widgets/monthly_category_chart.dart';
import '../services/transaction_service.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final TransactionService _transactionService = TransactionService();
  DateTime _selectedDate = DateTime.now();
  Map<String, dynamic>? _analyticsData;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchAnalytics();
  }

  void _handleMonthChange(int months) {
    setState(() {
      _selectedDate = DateTime(
        _selectedDate.year,
        _selectedDate.month + months,
      );
    });
    _fetchAnalytics();
  }

  Future<void> _fetchAnalytics() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      if (userProvider.user == null) return;

      final formattedMonth = DateFormat('yyyy-MM').format(_selectedDate);
      final data = await _transactionService.getAnalytics(
          userProvider.user!.id, formattedMonth);

      if (!mounted) return;
      setState(() {
        _analyticsData = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load analytics: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchAnalytics,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Monthly Overview",
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              // Month selector (chevron-style, matches Home).
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => _handleMonthChange(-1),
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Text(
                    DateFormat.yMMMM().format(_selectedDate),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => _handleMonthChange(1),
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_analyticsData != null) ...[
                _buildSummaryRow(theme),
                const SizedBox(height: 24),
                Text(
                  "Spending by Category",
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: SizedBox(
                    height: 320,
                    child: MonthlyCategoryBarChart(
                      categoryBreakdown: Map<String, double>.from(
                          _analyticsData!['categoryBreakdown'] ?? {}),
                      selectedMonth:
                          DateFormat.yMMMM().format(_selectedDate),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(ThemeData theme) {
    final income = (_analyticsData!['totalIncome'] as num).toDouble();
    final expense = (_analyticsData!['totalExpense'] as num).toDouble();
    final balance = (_analyticsData!['balance'] as num).toDouble();
    return Row(
      children: [
        Expanded(
          child: _statTile(theme, 'Income', income, Colors.green),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _statTile(theme, 'Expense', expense, Colors.red),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _statTile(theme, 'Balance', balance,
              balance >= 0 ? Colors.green : Colors.red),
        ),
      ],
    );
  }

  Widget _statTile(ThemeData theme, String label, double value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.bodySmall),
          const SizedBox(height: 4),
          Text(
            '\$${value.toStringAsFixed(0)}',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
