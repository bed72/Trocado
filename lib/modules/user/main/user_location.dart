import 'package:duck_router/duck_router.dart';
import 'package:trocado/modules/core/core.dart';
import 'package:trocado/modules/user/presentation/screens/user_screen.dart';

final class UserLocation extends Location {
  @override
  String get path => RoutesConstant.user.path;

  @override
  LocationBuilder? get builder =>
      (_) => const UserScreen();
}
