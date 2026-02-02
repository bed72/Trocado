import 'package:flutter/material.dart';
import 'package:trocado/src/domain/models/transaction_model.dart';

import 'package:trocado/src/presentation/cubits/date/date_cubit.dart';
import 'package:trocado/src/presentation/cubits/category/category_cubit.dart';
import 'package:trocado/src/presentation/cubits/calculator/calculator_cubit.dart';

final class TransactionParameterDto {
  final GlobalKey<FormState> formKey;

  final double Function(String) parse;
  final String Function(double) format;

  final DateCubit dateCubit;
  final CategoryCubit categoryCubit;
  final CalculatorCubit calculatorCubit;

  final VoidCallback navigateToDate;
  final VoidCallback navigateToCategory;
  final VoidCallback navigateToCalculator;

  final ValueChanged<String> onTypeSelected;
  final ValueChanged<DateTime> onDateSelected;
  final ValueChanged<double> onAmountSelected;
  final ValueChanged<String> onCategorySelected;
  final ValueChanged<String> onDescriptionSelected;
  final ValueChanged<String> onObservationSelected;

  final TransactionModel? transaction;

  const TransactionParameterDto({
    required this.parse,
    required this.format,
    required this.formKey,
    required this.dateCubit,
    required this.transaction,
    required this.categoryCubit,
    required this.calculatorCubit,
    required this.navigateToDate,
    required this.navigateToCategory,
    required this.navigateToCalculator,
    required this.onTypeSelected,
    required this.onDateSelected,
    required this.onAmountSelected,
    required this.onCategorySelected,
    required this.onDescriptionSelected,
    required this.onObservationSelected,
  });
}
