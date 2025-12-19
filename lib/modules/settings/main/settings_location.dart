import 'package:duck_router/duck_router.dart';

import 'package:trocado/modules/core/core.dart';

import 'package:trocado/modules/settings/presentation/dtos/settings_dto.dart';
import 'package:trocado/modules/settings/presentation/screens/settings_screen.dart';

final class SettingsLocation extends Location {
  @override
  String get path => RoutesConstant.settings.path;

  @override
  LocationBuilder? get builder =>
      (context) => SettingsScreen(dto: SettingsDto.build(context));
}
