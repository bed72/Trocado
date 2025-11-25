import 'package:duck_router/duck_router.dart';

import 'package:trocado/modules/core/core.dart';

import 'package:trocado/modules/transactions/presentation/screens/all_transactions_screen.dart';

final class AllTransactionsLocation extends Location {
  @override
  String get path => RoutesConstant.allTransaction.path;

  @override
  LocationBuilder? get builder =>
      (_) => const AllTransactionsScreen();
}
