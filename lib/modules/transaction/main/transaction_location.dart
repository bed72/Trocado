import 'package:duck_router/duck_router.dart';
import 'package:trocado/modules/calculator/presentation/cubits/calculator_cubit.dart';

import 'package:trocado/modules/core/core.dart';
import 'package:trocado/modules/date/date.dart';
import 'package:trocado/modules/category/category.dart';
import 'package:trocado/modules/calculator/calculator.dart';

import 'package:trocado/modules/transaction/presentation/screens/transactions_screen.dart';

final class TransactionLocation extends Location {
  @override
  String get path => RoutesConstant.transactions.path;

  @override
  LocationBuilder? get builder => (context) {
    final cubit = context.get<CalculatorCubit>();

    return TransactionsScreen(
      cubit: cubit,
      navigateToDate: () => context.navigate(DateLocation()),
      navigateToCalculator: () => context.navigate(CalculatorLocation()),
      navigateToCategory: () =>
          context.navigate(CategoryLocation(type: .expense)),
    );
  };
}
