import 'package:equatable/equatable.dart';

final class PartnerBudgetSliceModel extends Equatable {
  final int value;
  final String name;
  final String email;
  final int remaining;
  final int totalSpent;

  const PartnerBudgetSliceModel({
    required this.name,
    required this.email,
    required this.value,
    required this.remaining,
    required this.totalSpent,
  });

  PartnerBudgetSliceModel copyWith({
    int? value,
    String? name,
    String? email,
    int? remaining,
    int? totalSpent,
  }) => PartnerBudgetSliceModel(
    name: name ?? this.name,
    email: email ?? this.email,
    value: value ?? this.value,
    remaining: remaining ?? this.remaining,
    totalSpent: totalSpent ?? this.totalSpent,
  );

  @override
  List<Object?> get props => [name, email, value, remaining, totalSpent];
}
