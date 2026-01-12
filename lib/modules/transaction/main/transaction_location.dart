import 'package:duck_router/duck_router.dart';

import 'package:trocado/modules/core/core.dart';
import 'package:trocado/modules/date/date.dart';
import 'package:trocado/modules/category/category.dart';

import 'package:trocado/modules/transaction/presentation/screens/transactions_screen.dart';

final class TransactionLocation extends Location {
  @override
  String get path => RoutesConstant.transactions.path;

  @override
  LocationBuilder? get builder =>
      (context) => TransactionsScreen(
        navigateToDate: () => context.navigate(DateLocation()),
        navigateToCategory: () =>
            context.navigate(CategoryLocation(type: .expense)),
      );
}
