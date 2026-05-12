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
}
