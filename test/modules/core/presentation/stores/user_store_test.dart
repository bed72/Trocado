import 'dart:io';

import 'package:mocktail/mocktail.dart';
import 'package:mobx/mobx.dart' hide when;
import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/modules/core/core.dart';

import '../../../../mocks/mocks.dart';
import '../../../../fakes/fakes.dart';

void main() {
  late UserDto user;
  late UserStore store;
  late IUserRepository userRepository;
  late IImageRepository imageRepository;

  setUpAll(() {
    registerFallbackValue(FakeUserDto());
    registerFallbackValue(ImagesConstant.gallery);
  });

  setUp(() {
    userRepository = MockUserRepository();
    imageRepository = MockImageRepository();
    store = UserStore(
      userRepository: userRepository,
      imageRepository: imageRepository,
    );
    user = UserDto(id: 1, name: 'Gabriel', image: 'image.webp');
  });

  group('UserStore - find', () {
    test('should load user when repository returns Right(user)', () async {
      when(() => userRepository.find()).thenAnswer((_) async => Right(user));

      await store.find();

      expect(store.user, equals(user));
    });

    test(
      'should set user = empty when repository returns Left(error)',
      () async {
        when(
          () => userRepository.find(),
        ).thenAnswer((_) async => const Left('erro'));

        await store.find();

        expect(store.user.name, 'Troqueiro');
      },
    );

    test('find should toggle loading flag', () async {
      when(() => userRepository.find()).thenAnswer((_) async => Right(user));

      final loadingStates = <bool>[];

      final dispose = reaction<bool>(
        (_) => store.isLoading,
        (value) => loadingStates.add(value),
      );

      await store.find();

      expect(loadingStates.length, 2);
      expect(loadingStates.first, true);
      expect(loadingStates.last, false);

      dispose();
    });
  });

  group('UserStore - insert', () {
    test('should call repository.insert and update user', () async {
      when(
        () => userRepository.insert(data: any(named: 'data')),
      ).thenAnswer((_) async => true);

      await store.insert(user);

      expect(store.user, equals(user));
      verify(() => userRepository.insert(data: user)).called(1);
    });

    test('insert should toggle loading', () async {
      when(
        () => userRepository.insert(data: any(named: 'data')),
      ).thenAnswer((_) async => true);

      final states = <bool>[];

      final dispose = reaction<bool>(
        (_) => store.isLoading,
        (value) => states.add(value),
      );

      await store.insert(user);

      expect(states.first, true);
      expect(states.last, false);

      dispose();
    });
  });

  group('UserStore - update', () {
    test('should call repository.update and update user', () async {
      when(
        () => userRepository.update(data: any(named: 'data')),
      ).thenAnswer((_) async => true);

      await store.update(user);

      expect(store.user, equals(user));
      verify(() => userRepository.update(data: user)).called(1);
    });

    test('update should toggle loading', () async {
      when(
        () => userRepository.update(data: any(named: 'data')),
      ).thenAnswer((_) async => true);

      final states = <bool>[];

      final dispose = reaction<bool>(
        (_) => store.isLoading,
        (v) => states.add(v),
      );

      await store.update(user);

      expect(states.first, true);
      expect(states.last, false);

      dispose();
    });
  });

  group('UserStore - delete', () {
    test('should call repository.delete and reset user', () async {
      when(
        () => userRepository.delete(data: any(named: 'data')),
      ).thenAnswer((_) async => true);

      store.user = user;

      await store.delete(user);

      expect(store.user.name, 'Troqueiro');
      verify(() => userRepository.delete(data: user)).called(1);
    });

    test('delete should toggle loading', () async {
      when(
        () => userRepository.delete(data: any(named: 'data')),
      ).thenAnswer((_) async => true);

      final states = <bool>[];

      final dispose = reaction<bool>(
        (_) => store.isLoading,
        (v) => states.add(v),
      );

      await store.delete(user);

      expect(states.first, true);
      expect(states.last, false);

      dispose();
    });
  });

  group('UserStore - toggle (image)', () {
    test('should update user image when repository returns file', () async {
      final fakeFile = File('path/to/image.png');

      when(
        () => imageRepository(type: any(named: 'type')),
      ).thenAnswer((_) async => fakeFile);

      await store.toggle(ImagesConstant.gallery);

      expect(store.user.image, equals(fakeFile.path));
    });

    test('should NOT update image when repository returns null', () async {
      when(
        () => imageRepository(type: any(named: 'type')),
      ).thenAnswer((_) async => null);

      final initial = store.user;

      await store.toggle(ImagesConstant.gallery);

      expect(store.user, equals(initial));
    });

    test('toggle should toggle loading state', () async {
      final fakeFile = File('image.png');

      when(
        () => imageRepository(type: any(named: 'type')),
      ).thenAnswer((_) async => fakeFile);

      final calls = <bool>[];

      final dispose = reaction<bool>(
        (_) => store.isLoading,
        (v) => calls.add(v),
      );

      await store.toggle(ImagesConstant.camera);

      expect(calls.first, true);
      expect(calls.last, false);

      dispose();
    });
  });
}
