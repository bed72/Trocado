import 'package:equatable/equatable.dart';

enum ExpenseStatus { initial, loading, success, failure }

final class ExpenseState extends Equatable {
  final int? id;
  final int value;
  final int? date;
  final String message;
  final bool isDeleting;
  final String description;
  final String? dateFailure;
  final ExpenseStatus status;
  final String? valueFailure;
  final String? formattedDate;
  final String? descriptionFailure;

  const ExpenseState({
    this.id,
    this.date,
    this.value = 0,
    this.dateFailure,
    this.valueFailure,
    this.message = '',
    this.formattedDate,
    this.description = '',
    this.status = .initial,
    this.isDeleting = false,
    this.descriptionFailure,
  });

  ExpenseState copyWith({
    int? id,
    int? date,
    int? value,
    String? message,
    bool? isDeleting,
    String? description,
    String? dateFailure,
    String? valueFailure,
    String? formattedDate,
    ExpenseStatus? status,
    String? descriptionFailure,
    bool clearDateFailure = false,
    bool clearValueFailure = false,
    bool clearDescriptionFailure = false,
  }) => ExpenseState(
    id: id ?? this.id,
    date: date ?? this.date,
    value: value ?? this.value,
    status: status ?? this.status,
    message: message ?? this.message,
    isDeleting: isDeleting ?? this.isDeleting,
    description: description ?? this.description,
    formattedDate: formattedDate ?? this.formattedDate,
    dateFailure: clearDateFailure ? null : dateFailure ?? this.dateFailure,
    valueFailure: clearValueFailure ? null : valueFailure ?? this.valueFailure,
    descriptionFailure: clearDescriptionFailure
        ? null
        : descriptionFailure ?? this.descriptionFailure,
  );

  @override
  List<Object?> get props => [
    id,
    date,
    value,
    status,
    message,
    isDeleting,
    description,
    dateFailure,
    valueFailure,
    formattedDate,
    descriptionFailure,
  ];
}
