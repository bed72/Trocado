import 'package:duck_router/duck_router.dart';

import 'package:trocado/src/domain/constants/routes_constant.dart';

import 'package:trocado/src/main/locations/date_location.dart';
import 'package:trocado/src/main/locations/category_location.dart';
import 'package:trocado/src/main/locations/calculator_location.dart';

import 'package:trocado/src/presentation/pages/screen_page.dart';
import 'package:trocado/src/presentation/screens/transactions_screen.dart';
import 'package:trocado/src/presentation/extensions/context_extension.dart';

import 'package:trocado/src/presentation/cubits/date/date_cubit.dart';
import 'package:trocado/src/presentation/cubits/category/category_cubit.dart';
import 'package:trocado/src/presentation/cubits/calculator/calculator_cubit.dart';
import 'package:trocado/src/presentation/cubits/transaction/transaction_cubit.dart';

final class TransactionLocation extends Location {
  final int? id;

  const TransactionLocation({this.id});

  @override
  String get path => '${RoutesConstant.transactions.path}/$id';

  @override
  LocationPageBuilder get pageBuilder =>
      (context) => screenPage(
        TransactionsScreen(
          id: id,
          dateCubit: context.get<DateCubit>(),
          categoryCubit: context.get<CategoryCubit>(),
          caculatorCubit: context.get<CalculatorCubit>(),
          transactionCubit: context.get<TransactionCubit>(),
          navigateToDate: () => context.navigate(DateLocation()),
          navigateToCategory: () => context.navigate(CategoryLocation()),
          navigateToCalculator: () => context.navigate(CalculatorLocation()),
        ),
      );
}
