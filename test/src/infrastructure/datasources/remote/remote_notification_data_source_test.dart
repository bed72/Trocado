import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/src/domain/either/either.dart';

import 'package:trocado/src/infrastructure/clients/http/http_client.dart';
import 'package:trocado/src/infrastructure/clients/http/requests/requests.dart';
import 'package:trocado/src/infrastructure/clients/messaging/messaging_client.dart';
import 'package:trocado/src/infrastructure/datasources/remote/remote_notification_data_source.dart';

import '../../../../mocks/mocks.dart';

void main() {
  late IHttpClient httpClient;
  late IMessagingClient messagingClient;
  late IRemoteNotificationDataSource dataSource;

  setUp(() {
    httpClient = MockHttpClient();
    messagingClient = MockMessagingClient();
    dataSource = RemoteNotificationDataSource(
      httpClient: httpClient,
      messagingClient: messagingClient,
    );

    registerFallbackValue(const Requests('/'));
    when(() => messagingClient.platform).thenReturn('android');
  });

  group('registerToken', () {
    test('returns Right without POST when token is null', () async {
      when(() => messagingClient.getToken()).thenAnswer((_) async => null);

      final data = await dataSource.registerToken();

      expect(data.isRight, isTrue);
      verifyNever(() => httpClient.post(parameter: any(named: 'parameter')));
    });

    test('POSTs token + platform and returns Right on 2xx', () async {
      when(
        () => messagingClient.getToken(),
      ).thenAnswer((_) async => 'fcm-token-abc');
      when(
        () => httpClient.post(parameter: any(named: 'parameter')),
      ).thenAnswer((_) async => const Right({}));

      final data = await dataSource.registerToken();

      expect(data.isRight, isTrue);
      final captured =
          verify(
                () =>
                    httpClient.post(parameter: captureAny(named: 'parameter')),
              ).captured.single
              as Requests;
      expect(captured.path, '/api/v1/me/fcm-token');
      expect(captured.body, {'token': 'fcm-token-abc', 'platform': 'android'});
    });

    test('returns Left with FailureResponse on backend error', () async {
      when(
        () => messagingClient.getToken(),
      ).thenAnswer((_) async => 'fcm-token-abc');
      when(
        () => httpClient.post(parameter: any(named: 'parameter')),
      ).thenAnswer(
        (_) async => const Left({
          'errors': [
            {
              'code': 'network_error',
              'message': 'Network error',
              'field': 'non_field_errors',
            },
          ],
        }),
      );

      final data = await dataSource.registerToken();

      expect(data.isLeft, isTrue);
      expect(data.left.errors.first.code, 'network_error');
    });
  });

  group('revokeToken', () {
    test('returns Right without DELETE when token is null', () async {
      when(() => messagingClient.getToken()).thenAnswer((_) async => null);

      final data = await dataSource.revokeToken();

      expect(data.isRight, isTrue);
      verifyNever(() => httpClient.delete(parameter: any(named: 'parameter')));
    });

    test('DELETEs with body containing only token on 2xx', () async {
      when(
        () => messagingClient.getToken(),
      ).thenAnswer((_) async => 'fcm-token-abc');
      when(
        () => httpClient.delete(parameter: any(named: 'parameter')),
      ).thenAnswer((_) async => const Right({}));

      final data = await dataSource.revokeToken();

      expect(data.isRight, isTrue);
      final captured =
          verify(
                () => httpClient.delete(
                  parameter: captureAny(named: 'parameter'),
                ),
              ).captured.single
              as Requests;
      expect(captured.path, '/api/v1/me/fcm-token');
      expect(captured.body, {'token': 'fcm-token-abc'});
    });

    test('returns Left with FailureResponse on backend error', () async {
      when(
        () => messagingClient.getToken(),
      ).thenAnswer((_) async => 'fcm-token-abc');
      when(
        () => httpClient.delete(parameter: any(named: 'parameter')),
      ).thenAnswer(
        (_) async => const Left({
          'errors': [
            {
              'code': 'network_error',
              'message': 'Network error',
              'field': 'non_field_errors',
            },
          ],
        }),
      );

      final data = await dataSource.revokeToken();

      expect(data.isLeft, isTrue);
      expect(data.left.errors.first.code, 'network_error');
    });
  });

  group('deleteAll', () {
    test('DELETEs without body on 2xx', () async {
      when(
        () => httpClient.delete(parameter: any(named: 'parameter')),
      ).thenAnswer((_) async => const Right({}));

      final data = await dataSource.deleteAll();

      expect(data.isRight, isTrue);
      final captured =
          verify(
                () => httpClient.delete(
                  parameter: captureAny(named: 'parameter'),
                ),
              ).captured.single
              as Requests;

      expect(captured.body, isNull);
      expect(captured.path, '/api/v1/notifications');
    });

    test('returns Left with FailureResponse on backend error', () async {
      when(
        () => httpClient.delete(parameter: any(named: 'parameter')),
      ).thenAnswer(
        (_) async => const Left({
          'errors': [
            {
              'code': 'server_error',
              'field': 'non_field_errors',
              'message': 'Internal server error',
            },
          ],
        }),
      );

      final data = await dataSource.deleteAll();

      expect(data.isLeft, isTrue);
      expect(data.left.errors.first.code, 'server_error');
    });
  });

  group('findAll', () {
    test('GETs without cursor on first page', () async {
      when(() => httpClient.get(parameter: any(named: 'parameter'))).thenAnswer(
        (_) async => const Right({
          'next': null,
          'previous': null,
          'results': <Map<String, dynamic>>[],
        }),
      );

      final data = await dataSource.findAll();

      expect(data.isRight, isTrue);

      final captured =
          verify(
                () => httpClient.get(parameter: captureAny(named: 'parameter')),
              ).captured.single
              as Requests;

      expect(captured.path, '/api/v1/notifications');
    });

    test('GETs with cursor as query param on subsequent page', () async {
      when(() => httpClient.get(parameter: any(named: 'parameter'))).thenAnswer(
        (_) async => const Right({
          'next': null,
          'previous': null,
          'results': <Map<String, dynamic>>[],
        }),
      );

      await dataSource.findAll(cursor: 'abc123');

      final captured =
          verify(
                () => httpClient.get(parameter: captureAny(named: 'parameter')),
              ).captured.single
              as Requests;
      expect(captured.path, '/api/v1/notifications?cursor=abc123');
    });

    test('returns Left with FailureResponse on backend error', () async {
      when(() => httpClient.get(parameter: any(named: 'parameter'))).thenAnswer(
        (_) async => const Left({
          'errors': [
            {
              'code': 'network_error',
              'message': 'Network error',
              'field': 'non_field_errors',
            },
          ],
        }),
      );

      final data = await dataSource.findAll();

      expect(data.isLeft, isTrue);
      expect(data.left.errors.first.code, 'network_error');
    });
  });
}
