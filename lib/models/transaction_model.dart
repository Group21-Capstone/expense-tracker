enum TransactionType { income, expense }

class Transaction {
  final String id;
  final String title;
  final double amount;
  final DateTime date;
  final String category;
  final TransactionType type;
  final String? notes;

  Transaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.category,
    required this.type,
    this.notes,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'].toString(),
      title: json['title'] ?? '',
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date']), // Assumes YYYY-MM-DD format
      category: json['category'] ?? '',
      type: json['type'].toString().toLowerCase() == 'income'
          ? TransactionType.income
          : TransactionType.expense,
      notes: json['notes'],
    );
  }

  /// Data columns only — excludes `id` (DB-generated UUID) and `user_id`
  /// (added by the service). Used for Supabase insert/update payloads.
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'amount': amount,
      'date': date.toIso8601String().split('T')[0], // YYYY-MM-DD
      'category': category,
      'type': type == TransactionType.income ? 'income' : 'expense',
      'notes': notes,
    };
  }
}
