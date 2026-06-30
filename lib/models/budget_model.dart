class Budget {
  final int? id;
  final String userId;
  final double amount;
  final String month; // YYYY-MM

  Budget({
    this.id,
    required this.userId,
    required this.amount,
    required this.month,
  });

  factory Budget.fromJson(Map<String, dynamic> json) {
    return Budget(
      id: json['id'] as int?,
      userId: (json['user_id'] ?? json['userId'] ?? '').toString(),
      amount: (json['amount'] as num).toDouble(),
      month: json['month'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'amount': amount,
      'month': month,
    };
  }
}
