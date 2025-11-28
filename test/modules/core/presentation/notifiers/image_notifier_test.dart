import 'dart:io';

import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/modules/core/core.dart';

import '../../../../mocks/mocks.dart';

void main() {
  late ImageNotifier notifier;
  late IImageRepository imageRepository;
  late IStorageRepository storageRepository;

  setUpAll(() {
    registerFallbackValue(ImagesConstant.camera);
  });

  setUp(() {
    imageRepository = MockImageRepository();
    storageRepository = MockStorageRepository();
    notifier = ImageNotifier(
      imageRepository: imageRepository,
      storageRepository: storageRepository,
    );
  });

  group('ImageNotifier', () {
    test('initial state should be null', () {
      expect(notifier.success, isNull);
      expect(notifier.hasImage, isFalse);
    });

    test('call should do nothing when repository returns null', () async {
      when(
        () => imageRepository(type: any(named: 'type')),
      ).thenAnswer((_) async => null);

      await notifier.call(type: ImagesConstant.camera);

      expect(notifier.success, isNull);
      verifyNever(
        () => storageRepository.save(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      );
    });

    test('call should update state and save file path', () async {
      final file = File('/tmp/image.png');

      when(
        () => imageRepository(type: any(named: 'type')),
      ).thenAnswer((_) async => file);

      when(
        () => storageRepository.save(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      ).thenAnswer((_) async {});

      await notifier.call(type: ImagesConstant.camera);

      expect(notifier.hasImage, isTrue);
      expect(notifier.success, equals(file));

      verify(
        () => storageRepository.save(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      ).called(1);
    });

    test(
      'ensureInitialized should do nothing if storage returns null',
      () async {
        when(
          () => storageRepository.get(key: any(named: 'key')),
        ).thenAnswer((_) async => null);

        await notifier.ensureInitialized();

        expect(notifier.success, isNull);
      },
    );

    test(
      'ensureInitialized should do nothing if storage returns empty string',
      () async {
        when(
          () => storageRepository.get(key: any(named: 'key')),
        ).thenAnswer((_) async => '');

        await notifier.ensureInitialized();

        expect(notifier.success, isNull);
      },
    );

    test(
      'ensureInitialized should do nothing if file does not exist',
      () async {
        when(
          () => storageRepository.get(key: any(named: 'key')),
        ).thenAnswer((_) async => '/tmp/does_not_exist.png');

        final file = File('/tmp/does_not_exist.png');
        expect(await file.exists(), isFalse);

        await notifier.ensureInitialized();

        expect(notifier.success, isNull);
      },
    );

    test(
      'ensureInitialized should restore the image when file exists',
      () async {
        final dir = Directory.systemTemp.createTempSync();
        final file = File('${dir.path}/restored.png');
        file.writeAsStringSync('test');

        when(
          () => storageRepository.get(key: any(named: 'key')),
        ).thenAnswer((_) async => file.path);

        await notifier.ensureInitialized();

        expect(notifier.hasImage, isTrue);
        expect(notifier.success?.path, equals(file.path));
      },
    );
  });
}
