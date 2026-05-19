import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:trocado/src/main/providers/repositories_provider.dart';

import 'package:trocado/src/domain/either/either.dart';
import 'package:trocado/src/domain/failures/failure.dart';
import 'package:trocado/src/domain/enums/theme/theme_mode_enum.dart';
import 'package:trocado/src/domain/repositories/interface_theme_repository.dart';

import 'package:trocado/src/presentation/ui/settings/notifiers/theme/theme_state.dart';
import 'package:trocado/src/presentation/ui/settings/notifiers/theme/theme_intent.dart';
import 'package:trocado/src/presentation/ui/settings/notifiers/theme/theme_notifier.dart';

import '../../../mocks/mocks.dart';

void main() {
  late IThemeRepository repository;

  setUpAll(() {
    registerFallbackValue(ThemeModeEnum.system);
  });

  setUp(() {
    repository = MockThemeRepository();
    when(
      () => repository.save(mode: any(named: 'mode')),
    ).thenAnswer((_) async => const Right(null));
  });

  Future<ProviderContainer> makeContainer() async {
    final container = ProviderContainer(
      overrides: [themeRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    container.listen(themeProvider, (_, _) {});
    await container.read(themeProvider.future);
    return container;
  }

  group('build', () {
    test('returns ThemeState with system when repository resolves system', () async {
      when(
        () => repository.get(),
      ).thenAnswer((_) async => const Right(ThemeModeEnum.system));

      final container = await makeContainer();

      expect(
        container.read(themeProvider).asData?.value,
        const ThemeState(mode: ThemeModeEnum.system),
      );
    });

    test('returns ThemeState with dark when repository resolves dark', () async {
      when(
        () => repository.get(),
      ).thenAnswer((_) async => const Right(ThemeModeEnum.dark));

      final container = await makeContainer();

      expect(
        container.read(themeProvider).asData?.value,
        const ThemeState(mode: ThemeModeEnum.dark),
      );
    });

    test('returns ThemeState with light when repository resolves light', () async {
      when(
        () => repository.get(),
      ).thenAnswer((_) async => const Right(ThemeModeEnum.light));

      final container = await makeContainer();

      expect(
        container.read(themeProvider).asData?.value,
        const ThemeState(mode: ThemeModeEnum.light),
      );
    });

    test('falls back to system on repository failure', () async {
      when(
        () => repository.get(),
      ).thenAnswer((_) async => const Left(UnknownFailure()));

      final container = await makeContainer();

      expect(
        container.read(themeProvider).asData?.value,
        const ThemeState(mode: ThemeModeEnum.system),
      );
    });
  });

  group('dispatch(SetTheme)', () {
    test('updates state to selected mode and persists', () async {
      when(
        () => repository.get(),
      ).thenAnswer((_) async => const Right(ThemeModeEnum.system));

      final container = await makeContainer();

      container
          .read(themeProvider.notifier)
          .dispatch(const SetTheme(ThemeModeEnum.dark));

      await pumpEventQueue();

      expect(
        container.read(themeProvider).asData?.value.mode,
        ThemeModeEnum.dark,
      );
      verify(() => repository.save(mode: ThemeModeEnum.dark)).called(1);
    });

    test('persists system selection', () async {
      when(
        () => repository.get(),
      ).thenAnswer((_) async => const Right(ThemeModeEnum.dark));

      final container = await makeContainer();

      container
          .read(themeProvider.notifier)
          .dispatch(const SetTheme(ThemeModeEnum.system));

      await pumpEventQueue();

      expect(
        container.read(themeProvider).asData?.value.mode,
        ThemeModeEnum.system,
      );
      verify(() => repository.save(mode: ThemeModeEnum.system)).called(1);
    });
  });

  group('dispatch(CycleTheme)', () {
    test('cycles system to light and persists', () async {
      when(
        () => repository.get(),
      ).thenAnswer((_) async => const Right(ThemeModeEnum.system));

      final container = await makeContainer();

      container
          .read(themeProvider.notifier)
          .dispatch(const CycleTheme());

      await pumpEventQueue();

      expect(
        container.read(themeProvider).asData?.value.mode,
        ThemeModeEnum.light,
      );
      verify(() => repository.save(mode: ThemeModeEnum.light)).called(1);
    });

    test('cycles light to dark and persists', () async {
      when(
        () => repository.get(),
      ).thenAnswer((_) async => const Right(ThemeModeEnum.light));

      final container = await makeContainer();

      container
          .read(themeProvider.notifier)
          .dispatch(const CycleTheme());

      await pumpEventQueue();

      expect(
        container.read(themeProvider).asData?.value.mode,
        ThemeModeEnum.dark,
      );
      verify(() => repository.save(mode: ThemeModeEnum.dark)).called(1);
    });

    test('cycles dark to system and persists', () async {
      when(
        () => repository.get(),
      ).thenAnswer((_) async => const Right(ThemeModeEnum.dark));

      final container = await makeContainer();

      container
          .read(themeProvider.notifier)
          .dispatch(const CycleTheme());

      await pumpEventQueue();

      expect(
        container.read(themeProvider).asData?.value.mode,
        ThemeModeEnum.system,
      );
      verify(() => repository.save(mode: ThemeModeEnum.system)).called(1);
    });
  });

  group('dispatch(ToggleTheme)', () {
    test('switches light to dark and persists', () async {
      when(
        () => repository.get(),
      ).thenAnswer((_) async => const Right(ThemeModeEnum.light));

      final container = await makeContainer();

      container
          .read(themeProvider.notifier)
          .dispatch(const ToggleTheme());

      await pumpEventQueue();

      expect(
        container.read(themeProvider).asData?.value.mode,
        ThemeModeEnum.dark,
      );
      verify(() => repository.save(mode: ThemeModeEnum.dark)).called(1);
    });

    test('switches dark to light and persists', () async {
      when(
        () => repository.get(),
      ).thenAnswer((_) async => const Right(ThemeModeEnum.dark));

      final container = await makeContainer();

      container
          .read(themeProvider.notifier)
          .dispatch(const ToggleTheme());

      await pumpEventQueue();

      expect(
        container.read(themeProvider).asData?.value.mode,
        ThemeModeEnum.light,
      );
      verify(() => repository.save(mode: ThemeModeEnum.light)).called(1);
    });

    test('switches system to dark and persists', () async {
      when(
        () => repository.get(),
      ).thenAnswer((_) async => const Right(ThemeModeEnum.system));

      final container = await makeContainer();

      container
          .read(themeProvider.notifier)
          .dispatch(const ToggleTheme());

      await pumpEventQueue();

      expect(
        container.read(themeProvider).asData?.value.mode,
        ThemeModeEnum.dark,
      );
      verify(() => repository.save(mode: ThemeModeEnum.dark)).called(1);
    });
  });
}
