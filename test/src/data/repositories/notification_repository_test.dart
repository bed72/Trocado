import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/src/domain/either/either.dart';
import 'package:trocado/src/domain/failures/failure.dart';
import 'package:trocado/src/domain/repositories/interface_notification_repository.dart';

import 'package:trocado/src/data/repositories/notification_repository.dart';

import 'package:trocado/src/infrastructure/clients/http/responses/failure/failure_response.dart';
import 'package:trocado/src/infrastructure/datasources/remote/remote_notification_data_source.dart';

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
}
