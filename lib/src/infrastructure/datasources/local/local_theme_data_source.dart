import 'package:trocado/src/domain/enums/theme/theme_mode_enum.dart';

import 'package:trocado/src/infrastructure/clients/storage/storage_key.dart';
import 'package:trocado/src/infrastructure/clients/storage/storage_client.dart';

abstract interface class ILocalThemeDataSource {
  Future<ThemeModeEnum?> get();
  Future<void> save({required ThemeModeEnum mode});
}

final class LocalThemeDataSource implements ILocalThemeDataSource {
  final IStorageClient _client;

  LocalThemeDataSource({required this._client});

  @override
  Future<ThemeModeEnum?> get() async {
    final value = await _client.read(key: StorageKey.themeMode.value);

    return value == null ? null : .fromString(value);
  }

  @override
  Future<void> save({required ThemeModeEnum mode}) =>
      _client.write(key: StorageKey.themeMode.value, value: mode.value);
}
