final class ActiveBudgetResponse {
  final int id;
  final String value;
  final String startDate;
  final String endDate;
  final String description;
  final String totalSpent;
  final String remaining;

  const ActiveBudgetResponse({
    required this.id,
    required this.value,
    required this.startDate,
    required this.endDate,
    required this.description,
    required this.totalSpent,
    required this.remaining,
  });

  factory ActiveBudgetResponse.fromJson(Map<String, dynamic> json) =>
      ActiveBudgetResponse(
        id: json['id'] as int,
        value: json['value'] as String,
        startDate: json['start_date'] as String,
        endDate: json['end_date'] as String,
        description: json['description'] as String,
        totalSpent: json['total_spent'] as String,
        remaining: json['remaining'] as String,
      );
}
