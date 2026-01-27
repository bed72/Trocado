import 'package:duck_router/duck_router.dart';

import 'package:trocado/modules/core/core.dart';
import 'package:trocado/modules/date/date.dart';
import 'package:trocado/modules/category/category.dart';
import 'package:trocado/modules/calculator/calculator.dart';
import 'package:trocado/modules/transaction/data/dtos/transaction_dto.dart';

import 'package:trocado/modules/transaction/presentation/cubits/transaction_cubit.dart';
import 'package:trocado/modules/transaction/presentation/screens/transactions_screen.dart';

final class TransactionLocation extends Location {
  final TransactionDto? dto;

  const TransactionLocation({this.dto});

  @override
  String get path => RoutesConstant.transactions.path;

  @override
  LocationPageBuilder get pageBuilder =>
      (context) => screenPage(
        TransactionsScreen(
          dto: dto,
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
