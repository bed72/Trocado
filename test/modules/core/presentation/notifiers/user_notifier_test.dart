import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/modules/core/core.dart';

import 'package:trocado/modules/core/data/dtos/user_dto.dart';

import '../../../../fakes/fakes.dart';
import '../../../../mocks/mocks.dart';

void main() {
  late UserDto user;
  late UserNotifier notifier;
  late IUserRepository repository;

  setUpAll(() {
    registerFallbackValue(FakeUserDto());
  });

  setUp(() {
    repository = MockUserRepository();
    notifier = UserNotifier(repository: repository);
    user = UserDto(id: '1', name: 'Gabriel', image: 'image.webp');
  });

  group('UserNotifier - find', () {
    test('It should load the user when `find` returns `Right`.', () async {
      when(
        () => repository.find(data: any(named: 'data')),
      ).thenAnswer((_) async => Right(user));

      await notifier.find(user);

      expect(notifier.hasUser, isTrue);
      expect(notifier.success, equals(user));
    });

    test('You should ignore the error when `find` returns `Left`.', () async {
      when(
        () => repository.find(data: any(named: 'data')),
      ).thenAnswer((_) async => const Left('erro'));

      await notifier.find(user);

      expect(notifier.success, isNull);
      expect(notifier.hasUser, isFalse);
    });
  });

  group('UserNotifier - insert', () {
    test(
      'You must call `insert` on the repository and update it successfully.',
      () async {
        when(
          () => repository.insert(data: any(named: 'data')),
        ).thenAnswer((_) async => Future.value());

        await notifier.insert(user);

        expect(notifier.hasUser, isTrue);
        expect(notifier.success, equals(user));
        verify(() => repository.insert(data: user)).called(1);
      },
    );
  });

  group('UserNotifier - update', () {
    test(
      'You should call `update` on the repository and update the success event.',
      () async {
        when(
          () => repository.update(data: any(named: 'data')),
        ).thenAnswer((_) async => Future.value());

        await notifier.update(user);

        expect(notifier.hasUser, isTrue);
        expect(notifier.success, equals(user));
        verify(() => repository.update(data: user)).called(1);
      },
    );
  });

  group('UserNotifier - delete', () {
    test(
      'You should call delete on the repository and clear success.',
      () async {
        when(
          () => repository.delete(data: any(named: 'data')),
        ).thenAnswer((_) async => Future.value());

        notifier.success = user;

        await notifier.delete(user);

        expect(notifier.success, isNull);
        expect(notifier.hasUser, isFalse);
        verify(() => repository.delete(data: user)).called(1);
      },
    );
  });
}
