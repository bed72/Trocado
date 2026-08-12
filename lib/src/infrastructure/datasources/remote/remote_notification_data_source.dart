import 'package:trocado/src/domain/either/either.dart';

import 'package:trocado/src/infrastructure/clients/messaging/messaging_client.dart';

import 'package:trocado/src/infrastructure/clients/http/http_client.dart';
import 'package:trocado/src/infrastructure/clients/http/endpoint_key.dart';

import 'package:trocado/src/infrastructure/clients/http/requests/requests.dart';
import 'package:trocado/src/infrastructure/clients/http/requests/fcm_token_request.dart';
import 'package:trocado/src/infrastructure/clients/http/requests/fcm_token_delete_request.dart';

import 'package:trocado/src/infrastructure/clients/http/responses/reponses.dart';
import 'package:trocado/src/infrastructure/clients/http/responses/data_model.dart';
import 'package:trocado/src/infrastructure/clients/http/responses/failure/failure_response.dart';
import 'package:trocado/src/infrastructure/clients/http/responses/notification/notification_response.dart';

abstract interface class IRemoteNotificationDataSource {
  Stream<void> get onTokenRefreshed;

  Future<Either<FailureResponse, void>> deleteAll();
  Future<Either<FailureResponse, void>> revokeToken();
  Future<Either<FailureResponse, void>> registerToken();
  Future<Either<FailureResponse, void>> deleteById({required int id});
  Future<Either<FailureResponse, DataModel<List<NotificationResponse>>>>
  findAll({String? cursor});
}

final class RemoteNotificationDataSource
    implements IRemoteNotificationDataSource {
  final IHttpClient _httpClient;
  final IMessagingClient _messagingClient;

  RemoteNotificationDataSource({
    required this._httpClient,
    required this._messagingClient,
  });

  @override
  Stream<void> get onTokenRefreshed =>
      _messagingClient.onTokenRefresh.map((_) {});

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

  @override
  Future<Either<FailureResponse, DataModel<List<NotificationResponse>>>>
  findAll({String? cursor}) async {
    final path = cursor == null
        ? EndpointKey.notifications.path
        : '${EndpointKey.notifications.path}?cursor=$cursor';

    final response = await _httpClient.get(parameter: Requests(path));

    return response.toDataModel(
      (data) => (data as List)
          .map(
            (item) => NotificationResponse.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
    );
  }

  @override
  Future<Either<FailureResponse, void>> deleteAll() async {
    final response = await _httpClient.delete(
      parameter: Requests(EndpointKey.notifications.path),
    );

    return response.either(FailureResponse.fromJson, (_) {});
  }

  @override
  Future<Either<FailureResponse, void>> deleteById({required int id}) async {
    final response = await _httpClient.delete(
      parameter: Requests('${EndpointKey.notifications.path}/$id'),
    );

    return response.either(FailureResponse.fromJson, (_) {});
  }

  @override
  Future<Either<FailureResponse, void>> revokeToken() async {
    final token = await _messagingClient.getToken();
    if (token == null) return const Right(null);

    final response = await _httpClient.delete(
      parameter: Requests(
        EndpointKey.fcmToken.path,
        body: FcmTokenDeleteRequest(token: token).toJson(),
      ),
    );

    return response.either(FailureResponse.fromJson, (_) {});
  }
}
