import 'package:equatable/equatable.dart';

enum BudgetFormStatus { initial, loading, success, failure }

final class BudgetFormState extends Equatable {
  final int value;
  final int? endDate;
  final int? startDate;
  final String message;
  final String description;
  final String? dateFailure;
  final String? valueFailure;
  final BudgetFormStatus status;
  final String? descriptionFailure;

  const BudgetFormState({
    this.endDate,
    this.value = 0,
    this.startDate,
    this.dateFailure,
    this.message = '',
    this.valueFailure,
    this.description = '',
    this.status = .initial,
    this.descriptionFailure,
  });

  BudgetFormState copyWith({
    int? value,
    int? endDate,
    int? startDate,
    String? message,
    String? description,
    String? dateFailure,
    String? valueFailure,
    BudgetFormStatus? status,
    String? descriptionFailure,
    bool clearDateFailure = false,
    bool clearValueFailure = false,
    bool clearDescriptionFailure = false,
  }) => BudgetFormState(
    value: value ?? this.value,
    status: status ?? this.status,
    endDate: endDate ?? this.endDate,
    message: message ?? this.message,
    startDate: startDate ?? this.startDate,
    description: description ?? this.description,
    dateFailure: clearDateFailure ? null : dateFailure ?? this.dateFailure,
    valueFailure: clearValueFailure ? null : valueFailure ?? this.valueFailure,
    descriptionFailure: clearDescriptionFailure
        ? null
        : descriptionFailure ?? this.descriptionFailure,
  );

  @override
  List<Object?> get props => [
    value,
    status,
    endDate,
    message,
    startDate,
    description,
    dateFailure,
    valueFailure,
    descriptionFailure,
  ];
}
