import 'package:duck_router/duck_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:trocado/app_route.dart';

import 'package:trocado/src/main/locations/date_location.dart';
import 'package:trocado/src/main/locations/category_location.dart';
import 'package:trocado/src/main/locations/calculator_location.dart';

import 'package:trocado/src/presentation/pages/screen_page.dart';
import 'package:trocado/src/presentation/screens/expense_screen.dart';
import 'package:trocado/src/presentation/extensions/context_extension.dart';

import 'package:trocado/src/presentation/bloc/expense_form/expense_form_bloc.dart';

final class ExpenseLocation extends Location {
  final int? id;

  const ExpenseLocation({this.id});

  @override
  String get path => '${AppRoutes.expense.path}/$id';

  @override
  LocationPageBuilder get pageBuilder =>
      (context) => screenPage(
        ExpenseScreen(
          id: id,
          bloc: context.read<ExpenseFormBloc>(),
          navigateToDate: () => context.navigate(DateLocation()),
          navigateToCategory: () => context.navigate(CategoryLocation()),
          navigateToCalculator: () => context.navigate(CalculatorLocation()),
        ),
      );
}
