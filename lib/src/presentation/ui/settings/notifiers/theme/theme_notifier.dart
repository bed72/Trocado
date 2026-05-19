import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:trocado/src/main/providers/repositories_provider.dart';

import 'package:trocado/src/domain/enums/theme/theme_mode_enum.dart';
import 'package:trocado/src/domain/repositories/interface_theme_repository.dart';

import 'package:trocado/src/presentation/ui/settings/notifiers/theme/theme_state.dart';
import 'package:trocado/src/presentation/ui/settings/notifiers/theme/theme_intent.dart';

part 'theme_notifier.g.dart';

@Riverpod(keepAlive: true)
final class ThemeNotifier extends _$ThemeNotifier {
  late IThemeRepository _repository;

  @override
  Future<ThemeState> build() async {
    _repository = ref.watch(themeRepositoryProvider);

    final data = await _repository.get();

    return data.fold(
      (_) => const ThemeState(),
      (mode) => ThemeState(mode: mode),
    );
  }

  void dispatch(ThemeIntent intent) => switch (intent) {
    ToggleTheme() => _toggle(),
    SetTheme(:final mode) => _set(mode),
  };

  Future<void> _toggle() async {
    final current = state.value?.mode ?? .system;
    final next = switch (current) {
      .light => ThemeModeEnum.dark,
      .dark => ThemeModeEnum.light,
      .system => ThemeModeEnum.dark,
    };

    await _set(next);
  }

  Future<void> _set(ThemeModeEnum mode) async {
    state = AsyncData(ThemeState(mode: mode));
    await _repository.save(mode: mode);
  }
}
