import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/transaction_model.dart';
// TransactionScreenResult is now also exported from this file — needed to
// handle both save and delete results from AddTransactionScreen.
import 'add_transaction_screen.dart';
import 'package:exp/widgets/expense_pie_chart.dart';
import '../services/transaction_service.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Full list of all transactions fetched from Supabase.
  List<Transaction> _transactions = [];
  bool _isLoading = true;
  String? _error;
  final TransactionService _transactionService = TransactionService();

  // Controls which month is displayed in the dashboard.
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    // Load transactions as soon as the screen opens.
    _fetchTransactions();
  }

  // Fetches all transactions for the signed-in user from Supabase.
  Future<void> _fetchTransactions() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      if (userProvider.user == null) return;

      final transactions =
          await _transactionService.getTransactions(userProvider.user!.id);
      setState(() {
        _transactions = transactions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
        // Fallback to mock data for demo if API fails (optional, but good for dev)
        //_transactions = List.from(mockTransactions);
      });
    }
  }

  // Returns only transactions that belong to the currently selected month.
  List<Transaction> get _filteredTransactions {
    return _transactions.where((t) {
      return t.date.year == _selectedDate.year &&
          t.date.month == _selectedDate.month;
    }).toList();
  }

  // Shifts the dashboard view forward or backward by [months] months.
  void _handleMonthChange(int months) {
    setState(() {
      _selectedDate = DateTime(
        _selectedDate.year,
        _selectedDate.month + months,
      );
    });
  }

  // Saves a brand-new transaction to Supabase and inserts it at the top
  // of the local list so the UI updates immediately without a full re-fetch.
  void _addNewTransaction(Transaction newTransaction) async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      if (userProvider.user == null) return;

      final addedTransaction = await _transactionService.addTransaction(
          newTransaction, userProvider.user!.id);
      setState(() {
        _transactions.insert(0, addedTransaction);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add transaction: $e')),
      );
    }
  }

  // Deletes a transaction from Supabase by [id] and removes it from the
  // local list so the UI updates without a full re-fetch.
  void _deleteTransaction(String id) async {
    try {
      await _transactionService.deleteTransaction(id);
      setState(() {
        _transactions.removeWhere((t) => t.id == id);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete transaction: $e')),
      );
    }
  }

  // Sends the updated transaction to Supabase and replaces the old version
  // in the local list so the UI reflects the change immediately.
  void _updateTransaction(Transaction updatedTransaction) async {
    try {
      final transaction =
          await _transactionService.updateTransaction(updatedTransaction);
      setState(() {
        final index = _transactions.indexWhere((t) => t.id == transaction.id);
        if (index != -1) {
          _transactions[index] = transaction;
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update transaction: $e')),
      );
    }
  }

  // Handles the result returned by AddTransactionScreen when it pops.
  // The result is a TransactionScreenResult which carries either a saved
  // transaction or a deleted flag — we act accordingly.
  void _handleTransactionScreenResult(
      TransactionScreenResult? result, String? existingId) {
    if (result == null) return;

    if (result.deleted && existingId != null) {
      // User tapped the Delete button — remove from Supabase and local list.
      _deleteTransaction(existingId);
    } else if (result.transaction != null) {
      if (existingId != null) {
        // User saved an edit to an existing transaction.
        _updateTransaction(result.transaction!);
      } else {
        // User saved a brand-new transaction.
        _addNewTransaction(result.transaction!);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Compute summary totals from the filtered (current month) transactions.
    final double totalIncome = _filteredTransactions
        .where((t) => t.type == TransactionType.income)
        .fold(0, (sum, t) => sum + t.amount);

    final double totalExpense = _filteredTransactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0, (sum, t) => sum + t.amount);

    final double balance = totalIncome - totalExpense;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        automaticallyImplyLeading: false,
      ),
      body: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeOutQuart,
        // Fade + slide-up animation when the screen first loads.
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, 50 * (1 - value)),
              child: child,
            ),
          );
        },
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Error: $_error'),
                        ElevatedButton(
                          onPressed: _fetchTransactions,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // MONTH SELECTOR
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Left arrow — go to previous month.
                            IconButton(
                              onPressed: () => _handleMonthChange(-1),
                              icon: const Icon(Icons.chevron_left),
                            ),
                            // Currently selected month label e.g. "June 2026".
                            Text(
                              DateFormat.yMMMM().format(_selectedDate),
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            // Right arrow — go to next month.
                            IconButton(
                              onPressed: () => _handleMonthChange(1),
                              icon: const Icon(Icons.chevron_right),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // BALANCE CARD
                        _buildBalanceCard(
                            context, balance, totalIncome, totalExpense),

                        const SizedBox(height: 32),

                        // PIE CHART
                        Text(
                          'Spending Breakdown',
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
                          child: ExpensePieChart(
                              transactions: _filteredTransactions),
                        ),

                        const SizedBox(height: 32),

                        // RECENT TRANSACTIONS
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Recent Transactions',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            // TextButton(
                            //   onPressed: () {},
                            //   child: const Text('See All'),
                            // ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        ListView.builder(
                          shrinkWrap: true,
                          // Disable ListView's own scrolling — the parent
                          // SingleChildScrollView handles scrolling instead.
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _filteredTransactions.length,
                          itemBuilder: (context, index) {
                            final t = _filteredTransactions[index];
                            return Dismissible(
                              key: ValueKey(t.id),
                              // Red delete background revealed on swipe-left.
                              background: Container(
                                color: Theme.of(context).colorScheme.error,
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 15,
                                  vertical: 4,
                                ),
                                child: const Icon(
                                  Icons.delete,
                                  color: Colors.white,
                                  size: 40,
                                ),
                              ),
                              // Only allow swiping from right to left.
                              direction: DismissDirection.endToStart,
                              // Called after the swipe animation completes —
                              // removes the transaction from Supabase and the list.
                              onDismissed: (direction) {
                                _deleteTransaction(t.id);
                              },
                              child: Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListTile(
                                  // Tapping a transaction opens the Edit screen.
                                  onTap: () async {
                                    // Now expects TransactionScreenResult instead
                                    // of a raw Transaction, to support both save
                                    // and delete actions from the edit screen.
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            AddTransactionScreen(
                                          transactionToEdit: t,
                                        ),
                                      ),
                                    );
                                    // Pass the existing transaction ID so the
                                    // handler knows whether this is an edit or delete.
                                    _handleTransactionScreenResult(result, t.id);
                                  },
                                  leading: CircleAvatar(
                                    backgroundColor:
                                        (t.type == TransactionType.income
                                                ? Colors.green
                                                : Colors.red)
                                            .withOpacity(0.1),
                                    child: Icon(
                                      t.type == TransactionType.income
                                          ? Icons.arrow_downward
                                          : Icons.arrow_upward,
                                      color: t.type == TransactionType.income
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                  ),
                                  title: Text(
                                    t.title,
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        DateFormat.yMMMd().format(t.date),
                                        style: theme.textTheme.bodyMedium,
                                      ),
                                      if (t.notes != null &&
                                          t.notes!.isNotEmpty)
                                        Text(
                                          t.notes!,
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                            color: theme
                                                .textTheme.bodySmall!.color!
                                                .withOpacity(0.7),
                                          ),
                                        ),
                                    ],
                                  ),
                                  trailing: Text(
                                    '${t.type == TransactionType.income ? '+' : '-'} \$${t.amount.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: t.type == TransactionType.income
                                          ? Colors.green
                                          : Colors.red,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
      ),

      // FAB — opens AddTransactionScreen for creating a new transaction.
      floatingActionButton: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 800),
        // Elastic bounce animation when the FAB appears.
        curve: Curves.elasticOut,
        builder: (context, value, child) {
          return Transform.scale(scale: value, child: child);
        },
        child: FloatingActionButton(
          onPressed: () async {
            // No transactionToEdit passed — this is an "add new" flow.
            // existingId is null because there's no existing transaction to
            // delete or update.
            final result = await Navigator.push<TransactionScreenResult>(
              context,
              MaterialPageRoute(
                builder: (context) => const AddTransactionScreen(),
              ),
            );
            _handleTransactionScreenResult(result, null);
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  // Builds the gradient balance card showing total balance, income, expense.
  Widget _buildBalanceCard(
      BuildContext context, double balance, double income, double expense) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total Balance',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '\$${balance.toStringAsFixed(2)}',
            style: theme.textTheme.displayMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryItem(
                  'Income', income, Icons.arrow_downward, Colors.greenAccent),
              _buildSummaryItem(
                  'Expense', expense, Icons.arrow_upward, Colors.redAccent),
            ],
          ),
        ],
      ),
    );
  }

  // Builds a single income/expense summary item inside the balance card.
  Widget _buildSummaryItem(
      String label, double amount, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: color.withOpacity(0.2), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(color: Colors.white70, fontSize: 12)),
            Text(
              '\$${amount.toStringAsFixed(2)}',
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16),
            ),
          ],
        ),
      ],
    );
  }
}