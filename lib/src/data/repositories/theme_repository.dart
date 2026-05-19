import 'package:trocado/src/domain/either/either.dart';

import 'package:trocado/src/domain/failures/failure.dart';
import 'package:trocado/src/domain/enums/theme/theme_mode_enum.dart';
import 'package:trocado/src/domain/repositories/interface_theme_repository.dart';

import 'package:trocado/src/infrastructure/datasources/local/local_theme_data_source.dart';

final class ThemeRepository implements IThemeRepository {
  final ILocalThemeDataSource _dataSource;

  ThemeRepository({required ILocalThemeDataSource dataSource})
    : _dataSource = dataSource;

  @override
  Future<Either<Failure, ThemeModeEnum>> get() async {
    final mode = await _dataSource.get();

    return Right(mode ?? .system);
  }

  @override
  Future<Either<Failure, void>> save({required ThemeModeEnum mode}) async {
    await _dataSource.save(mode: mode);

    return const Right(null);
  }
}
