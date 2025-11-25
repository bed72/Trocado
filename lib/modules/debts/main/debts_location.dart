import 'package:duck_router/duck_router.dart';

import 'package:trocado/modules/core/core.dart';
import 'package:trocado/modules/debts/presentation/screens/debts_screen.dart';

final class DebtsLocation extends Location {
  @override
  String get path => RoutesConstant.reports.path;

  @override
  LocationBuilder? get builder =>
      (_) => DebtsScreen();
}
