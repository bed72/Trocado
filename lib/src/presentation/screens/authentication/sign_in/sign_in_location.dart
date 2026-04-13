import 'package:duck_router/duck_router.dart';

import 'package:trocado/app_route.dart';

import 'package:trocado/src/main/locations/home_location.dart';

import 'package:trocado/src/presentation/screens/authentication/sign_in/sign_in_screen.dart';
import 'package:trocado/src/presentation/extensions/context_extension.dart';

final class SignInLocation extends Location {
  @override
  String get path => AppRoutes.signIn.path;

  @override
  LocationBuilder? get builder =>
      (context) => SignInScreen(
        onSuccess: () =>
            context.navigate(HomeLocation(), root: true, replace: true),
      );
}
