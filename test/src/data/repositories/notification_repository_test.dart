import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/src/domain/either/either.dart';
import 'package:trocado/src/domain/failures/failure.dart';
import 'package:trocado/src/domain/repositories/interface_notification_repository.dart';

import 'package:trocado/src/data/repositories/notification_repository.dart';

import 'package:trocado/src/infrastructure/datasources/remote/remote_notification_data_source.dart';

import 'package:trocado/src/infrastructure/clients/http/responses/failure/failure_response.dart';
import 'package:trocado/src/infrastructure/clients/http/responses/notification/notification_response.dart';
import 'package:trocado/src/infrastructure/clients/http/responses/notification/notifications_response.dart';

import '../../../mocks/mocks.dart';

FailureResponse _failure(String code, String message) => FailureResponse(
  errors: [
    FailureItemResponse(
      code: code,
      message: message,
      field: 'non_field_errors',
    ),
  ],
);

void main() {
  late INotificationRepository repository;
  late IRemoteNotificationDataSource dataSource;

  setUp(() {
    dataSource = MockRemoteNotificationDataSource();
    repository = NotificationRepository(dataSource: dataSource);
  });

  group('registerToken', () {
    test('returns Right when datasource succeeds', () async {
      when(
        () => dataSource.registerToken(),
      ).thenAnswer((_) async => const Right(null));

      final data = await repository.registerToken();

      expect(data.isRight, isTrue);
    });

    test('returns Left NetworkFailure on network error', () async {
      when(() => dataSource.registerToken()).thenAnswer(
        (_) async => Left(_failure('network_error', 'Network error')),
      );

      final data = await repository.registerToken();

      expect(data.isLeft, isTrue);
      expect(data.left, isA<NetworkFailure>());
    });

    test('returns Left ServerFailure on server error', () async {
      when(() => dataSource.registerToken()).thenAnswer(
        (_) async => Left(_failure('server_error', 'Internal server error')),
      );

      final data = await repository.registerToken();

      expect(data.isLeft, isTrue);
      expect(data.left, isA<ServerFailure>());
    });

    test('returns Left ValidationFailure on unknown code', () async {
      when(() => dataSource.registerToken()).thenAnswer(
        (_) async => Left(_failure('invalid', 'Invalid FCM token.')),
      );

      final data = await repository.registerToken();

      expect(data.isLeft, isTrue);
      expect(data.left, isA<ValidationFailure>());
      expect(data.left.message, 'Invalid FCM token.');
    });
  });

  group('revokeToken', () {
    test('returns Right when datasource succeeds', () async {
      when(
        () => dataSource.revokeToken(),
      ).thenAnswer((_) async => const Right(null));

      final data = await repository.revokeToken();

      expect(data.isRight, isTrue);
    });

    test('returns Left NetworkFailure on network error', () async {
      when(() => dataSource.revokeToken()).thenAnswer(
        (_) async => Left(_failure('network_error', 'Network error')),
      );

      final data = await repository.revokeToken();

      expect(data.isLeft, isTrue);
      expect(data.left, isA<NetworkFailure>());
    });

    test('returns Left ServerFailure on server error', () async {
      when(() => dataSource.revokeToken()).thenAnswer(
        (_) async => Left(_failure('server_error', 'Internal server error')),
      );

      final data = await repository.revokeToken();

      expect(data.isLeft, isTrue);
      expect(data.left, isA<ServerFailure>());
    });

    test('returns Left ValidationFailure on unknown code', () async {
      when(() => dataSource.revokeToken()).thenAnswer(
        (_) async => Left(_failure('invalid', 'Invalid FCM token.')),
      );

      final data = await repository.revokeToken();

      expect(data.isLeft, isTrue);
      expect(data.left, isA<ValidationFailure>());
      expect(data.left.message, 'Invalid FCM token.');
    });
  });

  group('deleteAll', () {
    test('returns Right when datasource succeeds', () async {
      when(
        () => dataSource.deleteAll(),
      ).thenAnswer((_) async => const Right(null));

      final data = await repository.deleteAll();

      expect(data.isRight, isTrue);
    });

    test('returns Left NetworkFailure on network error', () async {
      when(() => dataSource.deleteAll()).thenAnswer(
        (_) async => Left(_failure('network_error', 'Network error')),
      );

      final data = await repository.deleteAll();

      expect(data.isLeft, isTrue);
      expect(data.left, isA<NetworkFailure>());
    });

    test('returns Left ServerFailure on server error', () async {
      when(() => dataSource.deleteAll()).thenAnswer(
        (_) async => Left(_failure('server_error', 'Internal server error')),
      );

      final data = await repository.deleteAll();

      expect(data.isLeft, isTrue);
      expect(data.left, isA<ServerFailure>());
    });

    test('returns Left NotFoundFailure on not found', () async {
      when(
        () => dataSource.deleteAll(),
      ).thenAnswer((_) async => Left(_failure('not_found', 'Not found.')));

      final data = await repository.deleteAll();

      expect(data.isLeft, isTrue);
      expect(data.left, isA<NotFoundFailure>());
    });

    test('returns Left ValidationFailure on unknown code', () async {
      when(
        () => dataSource.deleteAll(),
      ).thenAnswer((_) async => Left(_failure('invalid', 'Invalid request.')));

      final data = await repository.deleteAll();

      expect(data.isLeft, isTrue);
      expect(data.left, isA<ValidationFailure>());
      expect(data.left.message, 'Invalid request.');
    });
  });

  group('deleteById', () {
    test('returns Right when datasource succeeds', () async {
      when(
        () => dataSource.deleteById(id: any(named: 'id')),
      ).thenAnswer((_) async => const Right(null));

      final data = await repository.deleteById(id: 42);

      expect(data.isRight, isTrue);
    });

    test('propagates id to datasource', () async {
      when(
        () => dataSource.deleteById(id: any(named: 'id')),
      ).thenAnswer((_) async => const Right(null));

      await repository.deleteById(id: 7);

      verify(() => dataSource.deleteById(id: 7)).called(1);
    });

    test('returns Left NetworkFailure on network error', () async {
      when(() => dataSource.deleteById(id: any(named: 'id'))).thenAnswer(
        (_) async => Left(_failure('network_error', 'Network error')),
      );

      final data = await repository.deleteById(id: 1);

      expect(data.isLeft, isTrue);
      expect(data.left, isA<NetworkFailure>());
    });

    test('returns Left ServerFailure on server error', () async {
      when(() => dataSource.deleteById(id: any(named: 'id'))).thenAnswer(
        (_) async => Left(_failure('server_error', 'Internal server error')),
      );

      final data = await repository.deleteById(id: 1);

      expect(data.isLeft, isTrue);
      expect(data.left, isA<ServerFailure>());
    });

    test('returns Left NotFoundFailure on not found', () async {
      when(() => dataSource.deleteById(id: any(named: 'id'))).thenAnswer(
        (_) async => Left(_failure('not_found', 'Notification not found.')),
      );

      final data = await repository.deleteById(id: 99);

      expect(data.isLeft, isTrue);
      expect(data.left, isA<NotFoundFailure>());
    });

    test('returns Left ValidationFailure on unknown code', () async {
      when(() => dataSource.deleteById(id: any(named: 'id'))).thenAnswer(
        (_) async => Left(_failure('invalid', 'Invalid request.')),
      );

      final data = await repository.deleteById(id: 1);

      expect(data.isLeft, isTrue);
      expect(data.left, isA<ValidationFailure>());
      expect(data.left.message, 'Invalid request.');
    });
  });

  group('findAll', () {
    test('returns Right with NotificationsPageModel on success', () async {
      when(() => dataSource.findAll(cursor: any(named: 'cursor'))).thenAnswer(
        (_) async => Right(
          NotificationsResponse(
            next: 'http://api.example.org/?cursor=next-token',
            previous: null,
            notifications: [
              NotificationResponse(
                id: 1,
                type: 'shared_expense_created',
                title: 'Nova despesa',
                description: 'Desc',
                createdAt: '2026-05-11T14:30:00Z',
              ),
            ],
          ),
        ),
      );

      final data = await repository.findAll();

      expect(data.isRight, isTrue);
      expect(data.right.nextCursor, 'next-token');
      expect(data.right.notifications, hasLength(1));
      expect(data.right.notifications.first.id, 1);
    });

    test('propagates cursor to datasource', () async {
      when(() => dataSource.findAll(cursor: any(named: 'cursor'))).thenAnswer(
        (_) async => const Right(
          NotificationsResponse(next: null, previous: null, notifications: []),
        ),
      );

      await repository.findAll(cursor: 'abc');

      verify(() => dataSource.findAll(cursor: 'abc')).called(1);
    });

    test('returns Left NetworkFailure on network error', () async {
      when(() => dataSource.findAll(cursor: any(named: 'cursor'))).thenAnswer(
        (_) async => Left(_failure('network_error', 'Network error')),
      );

      final data = await repository.findAll();

      expect(data.isLeft, isTrue);
      expect(data.left, isA<NetworkFailure>());
    });

    test('returns Left ServerFailure on server error', () async {
      when(() => dataSource.findAll(cursor: any(named: 'cursor'))).thenAnswer(
        (_) async => Left(_failure('server_error', 'Internal server error')),
      );

      final data = await repository.findAll();

      expect(data.isLeft, isTrue);
      expect(data.left, isA<ServerFailure>());
    });

    test('returns Left ValidationFailure on unknown code', () async {
      when(
        () => dataSource.findAll(cursor: any(named: 'cursor')),
      ).thenAnswer((_) async => Left(_failure('invalid', 'Invalid cursor.')));

      final data = await repository.findAll();

      expect(data.isLeft, isTrue);
      expect(data.left, isA<ValidationFailure>());
      expect(data.left.message, 'Invalid cursor.');
    });
  });
}
