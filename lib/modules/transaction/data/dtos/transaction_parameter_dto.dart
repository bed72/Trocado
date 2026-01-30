import 'package:flutter/material.dart';

import 'package:trocado/modules/date/date.dart';
import 'package:trocado/modules/category/category.dart';
import 'package:trocado/modules/calculator/calculator.dart';

import 'package:trocado/modules/transaction/data/dtos/transaction_dto.dart';

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

  final ValueChanged<int> onTypeSelected;
  final ValueChanged<DateTime> onDateSelected;
  final ValueChanged<double> onAmountSelected;
  final ValueChanged<String> onCategorySelected;
  final ValueChanged<String> onDescriptionSelected;
  final ValueChanged<String> onObservationSelected;

  final TransactionDto? transaction;

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
