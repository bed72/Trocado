final class ExpenseResponse {
  final int id;
  final String date;
  final String value;
  final String category;
  final String createdAt;
  final String description;

  const ExpenseResponse({
    required this.id,
    required this.date,
    required this.value,
    required this.category,
    required this.createdAt,
    required this.description,
  });

  factory ExpenseResponse.fromJson(Map<String, dynamic> json) =>
      ExpenseResponse(
        id: json['id'] as int,
        date: json['date'] as String,
        value: json['value'] as String,
        category: json['category'] as String,
        createdAt: json['created_at'] as String,
        description: json['description'] as String,
      );
}
