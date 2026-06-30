import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/transaction_model.dart';
import '../models/budget_model.dart';

class TransactionService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<Transaction>> getTransactions(String userId) async {
    final data = await _client
        .from('transactions')
        .select()
        .eq('user_id', userId)
        .order('date', ascending: false);
    return (data as List)
        .map((row) => Transaction.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<Transaction> addTransaction(
      Transaction transaction, String userId) async {
    final payload = {
      ...transaction.toJson(),
      'user_id': userId,
    };
    final row =
        await _client.from('transactions').insert(payload).select().single();
    return Transaction.fromJson(row);
  }

  Future<Transaction> updateTransaction(Transaction transaction) async {
    final row = await _client
        .from('transactions')
        .update(transaction.toJson())
        .eq('id', transaction.id)
        .select()
        .single();
    return Transaction.fromJson(row);
  }

  Future<void> deleteTransaction(String id) async {
    await _client.from('transactions').delete().eq('id', id);
  }

  /// Computes monthly analytics client-side (replaces the old backend
  /// /api/analytics endpoint). [month] is `YYYY-MM`.
  Future<Map<String, dynamic>> getAnalytics(
      String userId, String month) async {
    final parts = month.split('-');
    final year = int.parse(parts[0]);
    final mon = int.parse(parts[1]);
    final start = DateTime(year, mon, 1);
    final end = DateTime(year, mon + 1, 0); // last day of month

    String fmt(DateTime d) =>
        '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

    final data = await _client
        .from('transactions')
        .select()
        .eq('user_id', userId)
        .gte('date', fmt(start))
        .lte('date', fmt(end));

    double totalIncome = 0;
    double totalExpense = 0;
    final Map<String, double> categoryBreakdown = {};
    final Map<String, double> dailyBreakdown = {};

    for (final row in (data as List)) {
      final map = row as Map<String, dynamic>;
      final type = (map['type'] ?? '').toString().toLowerCase();
      final amount = (map['amount'] as num).toDouble();
      final day = map['date'].toString();
      final category = (map['category'] ?? 'Other').toString();

      if (type == 'income') {
        totalIncome += amount;
      } else {
        totalExpense += amount;
        categoryBreakdown.update(category, (v) => v + amount,
            ifAbsent: () => amount);
        dailyBreakdown.update(day, (v) => v + amount, ifAbsent: () => amount);
      }
    }

    final budget = await getBudget(userId, month);
    final budgetLimit = budget?.amount ?? 0.0;

    return {
      'totalIncome': totalIncome,
      'totalExpense': totalExpense,
      'balance': totalIncome - totalExpense,
      'budgetLimit': budgetLimit,
      'budgetPercentage':
          budgetLimit > 0 ? (totalExpense / budgetLimit) * 100 : 0.0,
      'categoryBreakdown': categoryBreakdown,
      'dailyBreakdown': dailyBreakdown,
    };
  }

  Future<Budget?> getBudget(String userId, String month) async {
    final row = await _client
        .from('budgets')
        .select()
        .eq('user_id', userId)
        .eq('month', month)
        .maybeSingle();
    if (row == null) return null;
    return Budget.fromJson(row);
  }

  Future<Budget> setBudget(String userId, double amount, String month) async {
    final row = await _client
        .from('budgets')
        .upsert(
          {'user_id': userId, 'amount': amount, 'month': month},
          onConflict: 'user_id,month',
        )
        .select()
        .single();
    return Budget.fromJson(row);
  }
}
