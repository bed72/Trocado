import 'package:duck_router/duck_router.dart';

import 'package:trocado/modules/core/core.dart';
import 'package:trocado/modules/transaction/presentation/screens/type_transaction_screen.dart';

final class TypeTransactionLocation extends Location {
  final String title;

  const TypeTransactionLocation({required this.title});

  @override
  List<Object?> get props => [title];

  @override
  String get path => RoutesConstant.typeTransaction.path;

  @override
  LocationBuilder? get builder =>
      (_) => TypeTransactionScreen(title: title);
}
