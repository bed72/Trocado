import 'package:equatable/equatable.dart';

enum BudgetFormStatus { initial, loading, success, failure }

final class BudgetFormState extends Equatable {
  final int? id;
  final int value;
  final int? endDate;
  final int? startDate;
  final String message;
  final bool isDeleting;
  final String description;
  final String? dateFailure;
  final String? valueFailure;
  final BudgetFormStatus status;
  final String? descriptionFailure;

  const BudgetFormState({
    this.id,
    this.endDate,
    this.value = 0,
    this.startDate,
    this.dateFailure,
    this.message = '',
    this.valueFailure,
    this.description = '',
    this.status = .initial,
    this.isDeleting = false,
    this.descriptionFailure,
  });

  BudgetFormState copyWith({
    int? id,
    int? value,
    int? endDate,
    int? startDate,
    String? message,
    bool? isDeleting,
    String? description,
    String? dateFailure,
    String? valueFailure,
    BudgetFormStatus? status,
    String? descriptionFailure,
    bool clearDateFailure = false,
    bool clearValueFailure = false,
    bool clearDescriptionFailure = false,
  }) => BudgetFormState(
    id: id ?? this.id,
    value: value ?? this.value,
    status: status ?? this.status,
    endDate: endDate ?? this.endDate,
    message: message ?? this.message,
    startDate: startDate ?? this.startDate,
    isDeleting: isDeleting ?? this.isDeleting,
    description: description ?? this.description,
    dateFailure: clearDateFailure ? null : dateFailure ?? this.dateFailure,
    valueFailure: clearValueFailure ? null : valueFailure ?? this.valueFailure,
    descriptionFailure: clearDescriptionFailure
        ? null
        : descriptionFailure ?? this.descriptionFailure,
  );

  @override
  List<Object?> get props => [
    id,
    value,
    status,
    endDate,
    message,
    startDate,
    isDeleting,
    description,
    dateFailure,
    valueFailure,
    descriptionFailure,
  ];
}
