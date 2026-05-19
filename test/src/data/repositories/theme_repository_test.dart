import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/src/data/repositories/theme_repository.dart';

import 'package:trocado/src/domain/enums/theme/theme_mode_enum.dart';
import 'package:trocado/src/domain/repositories/interface_theme_repository.dart';

import 'package:trocado/src/infrastructure/datasources/local/local_theme_data_source.dart';

import '../../../mocks/mocks.dart';

void main() {
  late ILocalThemeDataSource dataSource;
  late IThemeRepository repository;

  setUpAll(() {
    registerFallbackValue(ThemeModeEnum.system);
  });

  setUp(() {
    dataSource = MockLocalThemeDataSource();
    repository = ThemeRepository(dataSource: dataSource);
  });

  group('get', () {
    test(
      'returns Right with stored mode when datasource resolves dark',
      () async {
        when(
          () => dataSource.get(),
        ).thenAnswer((_) async => ThemeModeEnum.dark);

        final data = await repository.get();

        expect(data.isRight, isTrue);
        expect(data.right, ThemeModeEnum.dark);
      },
    );

    test(
      'returns Right with stored mode when datasource resolves light',
      () async {
        when(() => dataSource.get()).thenAnswer((_) async => .light);

        final data = await repository.get();

        expect(data.isRight, isTrue);
        expect(data.right, ThemeModeEnum.light);
      },
    );

    test(
      'returns Right with system as default when datasource resolves null',
      () async {
        when(() => dataSource.get()).thenAnswer((_) async => null);

        final data = await repository.get();

        expect(data.isRight, isTrue);
        expect(data.right, ThemeModeEnum.system);
      },
    );
  });

  group('save', () {
    test('forwards mode to datasource and returns Right', () async {
      when(
        () => dataSource.save(mode: any(named: 'mode')),
      ).thenAnswer((_) async {});

      final data = await repository.save(mode: ThemeModeEnum.dark);

      expect(data.isRight, isTrue);
      verify(() => dataSource.save(mode: ThemeModeEnum.dark)).called(1);
    });

    test('forwards system mode to datasource', () async {
      when(
        () => dataSource.save(mode: any(named: 'mode')),
      ).thenAnswer((_) async {});

      final data = await repository.save(mode: ThemeModeEnum.system);

      expect(data.isRight, isTrue);
      verify(() => dataSource.save(mode: ThemeModeEnum.system)).called(1);
    });
  });
}
