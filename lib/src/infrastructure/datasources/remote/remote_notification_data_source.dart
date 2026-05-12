import 'package:trocado/src/domain/either/either.dart';

import 'package:trocado/src/infrastructure/clients/messaging/messaging_client.dart';

import 'package:trocado/src/infrastructure/clients/http/http_client.dart';
import 'package:trocado/src/infrastructure/clients/http/endpoint_key.dart';
import 'package:trocado/src/infrastructure/clients/http/requests/requests.dart';
import 'package:trocado/src/infrastructure/clients/http/requests/fcm_token_request.dart';
import 'package:trocado/src/infrastructure/clients/http/responses/failure/failure_response.dart';

abstract interface class IRemoteNotificationDataSource {
  Future<Either<FailureResponse, void>> registerToken();
}

final class RemoteNotificationDataSource
    implements IRemoteNotificationDataSource {
  final IHttpClient _httpClient;
  final IMessagingClient _messagingClient;

  RemoteNotificationDataSource({
    required IHttpClient httpClient,
    required IMessagingClient messagingClient,
  }) : _httpClient = httpClient,
       _messagingClient = messagingClient;

  @override
  Future<Either<FailureResponse, void>> registerToken() async {
    final token = await _messagingClient.getToken();
    if (token == null) return const Right(null);

    final response = await _httpClient.post(
      parameter: Requests(
        EndpointKey.fcmToken.path,
        body: FcmTokenRequest(
          token: token,
          platform: _messagingClient.platform,
        ).toJson(),
      ),
    );

    return response.either(FailureResponse.fromJson, (_) {});
  }
}
