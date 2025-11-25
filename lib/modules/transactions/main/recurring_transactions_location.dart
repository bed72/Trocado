import 'package:duck_router/duck_router.dart';

import 'package:trocado/modules/core/core.dart';

import 'package:trocado/modules/transactions/presentation/screens/recurring_transactions_screen.dart';

final class RecurringTransactionsLocation extends Location {
  @override
  String get path => RoutesConstant.recurringTransactions.path;

  @override
  LocationBuilder? get builder =>
      (_) => const RecurringTransactionsScreen();
}
