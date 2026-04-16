final class ExpenseResponse {
  final int id;
  final String date;
  final String value;
  final String description;

  const ExpenseResponse({
    required this.id,
    required this.date,
    required this.value,
    required this.description,
  });

  factory ExpenseResponse.fromJson(Map<String, dynamic> json) =>
      ExpenseResponse(
        id: json['id'] as int,
        date: json['date'] as String,
        value: json['value'] as String,
        description: json['description'] as String,
      );
}
