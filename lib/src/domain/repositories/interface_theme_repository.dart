import 'package:trocado/src/domain/either/either.dart';

import 'package:trocado/src/domain/failures/failure.dart';
import 'package:trocado/src/domain/enums/theme/theme_mode_enum.dart';

abstract interface class IThemeRepository {
  Future<Either<Failure, ThemeModeEnum>> get();
  Future<Either<Failure, void>> save({required ThemeModeEnum mode});
}
