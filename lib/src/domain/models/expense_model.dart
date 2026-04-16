import 'package:equatable/equatable.dart';

final class ExpenseModel extends Equatable {
  final int id;
  final int date;
  final int value;
  final String description;

  const ExpenseModel({
    required this.id,
    required this.date,
    required this.value,
    required this.description,
  });

  ExpenseModel copyWith({
    int? id,
    int? date,
    int? value,
    String? description,
  }) => ExpenseModel(
    id: id ?? this.id,
    date: date ?? this.date,
    value: value ?? this.value,
    description: description ?? this.description,
  );

  @override
  List<Object?> get props => [id, value, date, description];
}
