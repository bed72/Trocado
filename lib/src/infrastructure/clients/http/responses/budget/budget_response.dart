final class BudgetResponse {
  final int id;
  final String value;
  final String startDate;
  final String endDate;
  final String description;

  const BudgetResponse({
    required this.id,
    required this.value,
    required this.startDate,
    required this.endDate,
    required this.description,
  });

  factory BudgetResponse.fromJson(Map<String, dynamic> json) => BudgetResponse(
    id: json['id'] as int,
    value: json['value'] as String,
    startDate: json['start_date'] as String,
    endDate: json['end_date'] as String,
    description: json['description'] as String,
  );
}
