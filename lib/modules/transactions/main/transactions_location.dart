import 'package:duck_router/duck_router.dart';

import 'package:trocado/modules/core/core.dart';

import 'package:trocado/modules/transactions/presentation/screens/transactions_screen.dart';

final class TransactionLocation extends Location {
  @override
  String get path => RoutesConstant.transactions.path;

  @override
  LocationBuilder? get builder =>
      (_) => TransactionsScreen();
}
