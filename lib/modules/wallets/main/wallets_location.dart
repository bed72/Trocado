import 'package:duck_router/duck_router.dart';

import 'package:trocado/modules/core/core.dart';
import 'package:trocado/modules/wallets/presentation/screens/wallets_screen.dart';

final class WalletsLocation extends Location {
  @override
  String get path => RoutesConstant.wallets.path;

  @override
  LocationBuilder? get builder =>
      (_) => WalletsScreen();
}
