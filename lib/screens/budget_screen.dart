import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/transaction_service.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  final TransactionService _transactionService = TransactionService();
  final TextEditingController _budgetController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  double _budgetLimit = 0.0;
  double _currentSpending = 0.0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    _budgetController.dispose();
    super.dispose();
  }

  void _handleMonthChange(int months) {
    setState(() {
      _selectedDate = DateTime(
        _selectedDate.year,
        _selectedDate.month + months,
      );
    });
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
    });

    final formattedMonth = DateFormat('yyyy-MM').format(_selectedDate);

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      if (userProvider.user == null) return;

      final budget = await _transactionService.getBudget(
          userProvider.user!.id, formattedMonth);
      final analytics = await _transactionService.getAnalytics(
          userProvider.user!.id, formattedMonth);

      if (!mounted) return;
      setState(() {
        _budgetLimit = budget?.amount ?? 0.0;
        _currentSpending = (analytics['totalExpense'] as num).toDouble();
        _budgetController.text =
            _budgetLimit > 0 ? _budgetLimit.toStringAsFixed(0) : '';
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load budget: $e')),
      );
    }
  }

  Future<void> _updateBudget(String value) async {
    final amount = double.tryParse(value);
    if (amount == null) return;

    final formattedMonth = DateFormat('yyyy-MM').format(_selectedDate);

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      if (userProvider.user == null) return;

      final updatedBudget = await _transactionService.setBudget(
          userProvider.user!.id, amount, formattedMonth);
      if (!mounted) return;
      setState(() {
        _budgetLimit = updatedBudget.amount;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Budget updated')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update budget: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final double progress = _budgetLimit > 0
        ? (_currentSpending / _budgetLimit).clamp(0.0, 1.0)
        : 0.0;
    final bool isOverBudget =
        _budgetLimit > 0 && _currentSpending > _budgetLimit;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Month picker (chevron-style, same UX as Home/Reports).
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

                  const SizedBox(height: 16),

                  // ======================= BUDGET OVERVIEW CARD =======================
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isOverBudget
                            ? theme.colorScheme.error.withOpacity(0.5)
                            : Colors.transparent,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: theme.shadowColor.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Monthly Budget',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.7),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Icon(Icons.account_balance_wallet,
                                color: theme.colorScheme.primary),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _budgetLimit > 0
                              ? '\$${_budgetLimit.toStringAsFixed(0)}'
                              : 'Not set',
                          style: theme.textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 24),
                        LinearProgressIndicator(
                          value: progress,
                          minHeight: 10,
                          backgroundColor: theme.dividerColor.withOpacity(0.2),
                          color: isOverBudget
                              ? theme.colorScheme.error
                              : theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Spent: \$${_currentSpending.toStringAsFixed(0)}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: isOverBudget
                                    ? theme.colorScheme.error
                                    : theme.colorScheme.onSurface
                                        .withOpacity(0.7),
                              ),
                            ),
                            if (_budgetLimit > 0)
                              Text(
                                '${(progress * 100).toStringAsFixed(1)}%',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.7),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (_budgetLimit > 0 && !isOverBudget)
                          Text(
                            'Remaining: \$${(_budgetLimit - _currentSpending).toStringAsFixed(0)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color:
                                  theme.colorScheme.onSurface.withOpacity(0.5),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ======================= SET BUDGET SECTION =======================
                  Text(
                    'Set Budget for ${DateFormat.yMMMM().format(_selectedDate)}',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: TextField(
                      controller: _budgetController,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        prefixText: "\$ ",
                        filled: true,
                        fillColor:
                            theme.colorScheme.surfaceVariant.withOpacity(0.2),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        hintText: "Enter monthly limit",
                      ),
                      onSubmitted: _updateBudget,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _updateBudget(_budgetController.text),
                      child: const Text('Save'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
