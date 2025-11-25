import 'package:duck_router/duck_router.dart';

import 'package:trocado/modules/core/core.dart';

import 'package:trocado/modules/home/presentation/screens/home_screen.dart';

final class HomeLocation extends Location {
  @override
  String get path => RoutesConstant.home.path;

  @override
  LocationBuilder? get builder =>
      (_) => HomeScreen();
}
