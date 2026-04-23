import 'package:equatable/equatable.dart';

enum ExpenseStatus { initial, loading, success, failure }

final class ExpenseState extends Equatable {
  final int value;
  final int? date;
  final String message;
  final String description;
  final String? dateFailure;
  final ExpenseStatus status;
  final String? valueFailure;
  final String? descriptionFailure;

  const ExpenseState({
    this.date,
    this.value = 0,
    this.dateFailure,
    this.valueFailure,
    this.message = '',
    this.description = '',
    this.status = .initial,
    this.descriptionFailure,
  });

  ExpenseState copyWith({
    int? date,
    int? value,
    String? message,
    String? description,
    String? dateFailure,
    String? valueFailure,
    ExpenseStatus? status,
    String? descriptionFailure,
    bool clearDateFailure = false,
    bool clearValueFailure = false,
    bool clearDescriptionFailure = false,
  }) => ExpenseState(
    date: date ?? this.date,
    value: value ?? this.value,
    status: status ?? this.status,
    message: message ?? this.message,
    description: description ?? this.description,
    dateFailure: clearDateFailure ? null : dateFailure ?? this.dateFailure,
    valueFailure: clearValueFailure ? null : valueFailure ?? this.valueFailure,
    descriptionFailure: clearDescriptionFailure
        ? null
        : descriptionFailure ?? this.descriptionFailure,
  );

  @override
  List<Object?> get props => [
    date,
    value,
    status,
    message,
    description,
    dateFailure,
    valueFailure,
    descriptionFailure,
  ];
}
