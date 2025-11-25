import 'package:duck_router/duck_router.dart';

import 'package:trocado/modules/core/core.dart';
import 'package:trocado/modules/goals/presentation/screens/goals_screen.dart';

final class GoalsLocation extends Location {
  @override
  String get path => RoutesConstant.goals.path;

  @override
  LocationBuilder? get builder =>
      (_) => GoalsScreen();
}
