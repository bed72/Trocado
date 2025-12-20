import 'package:duck_router/duck_router.dart';

import 'package:trocado/modules/core/domain/constant/routes_constant.dart';
import 'package:trocado/modules/core/presentation/stores/bottom_bar_store.dart';

final class BottomBarVisibilityIntercptor extends LocationInterceptor {
  final BottomBarStore _store;

  BottomBarVisibilityIntercptor({
    super.pushesOnTop,
    required BottomBarStore store,
  }) : _store = store;

  @override
  Location? execute(Location to, Location? _) {
    final visible = RoutesConstant.needsShowBottomNavigation(to.path);

    _store.onChanged(visible);

    return null;
  }
}
