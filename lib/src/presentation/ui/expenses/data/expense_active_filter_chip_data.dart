import 'package:flutter/widgets.dart';
import 'package:equatable/equatable.dart';

import 'package:trocado/src/presentation/ui/expenses/data/expense_filter_chip_kind.dart';

final class ExpenseActiveFilterChipData extends Equatable {
  final String label;
  final IconData? icon;
  final ExpenseFilterChipKind kind;

  const ExpenseActiveFilterChipData({
    required this.kind,
    required this.label,
    this.icon,
  });

  @override
  List<Object?> get props => [label, icon, kind];
}
