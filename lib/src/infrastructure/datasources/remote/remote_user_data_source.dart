import 'package:trocado/src/domain/either/either.dart';

import 'package:trocado/src/infrastructure/clients/http/http_client.dart';
import 'package:trocado/src/infrastructure/clients/http/endpoint_key.dart';
import 'package:trocado/src/infrastructure/clients/http/requests/requests.dart';

import 'package:trocado/src/infrastructure/clients/http/responses/reponses.dart';
import 'package:trocado/src/infrastructure/clients/http/responses/data_model.dart';
import 'package:trocado/src/infrastructure/clients/http/responses/user_response.dart';
import 'package:trocado/src/infrastructure/clients/http/responses/failure/failure_response.dart';

abstract interface class IRemoteUserDataSource {
  Future<Either<FailureResponse, DataModel<UserResponse>>> me();

  Future<Either<FailureResponse, void>> delete({
    required String refresh,
    required String password,
  });

  Future<Either<FailureResponse, DataModel<UserResponse>>> update({
    String? name,
    String? newPassword,
    String? currentPassword,
  });
}

final class RemoteUserDataSource implements IRemoteUserDataSource {
  final IHttpClient _client;

  RemoteUserDataSource({required this._client});

  @override
  Future<Either<FailureResponse, DataModel<UserResponse>>> me() async {
    final response = await _client.get(
      parameter: Requests(EndpointKey.me.path),
    );

    return response.toDataModel(
      (data) => UserResponse.fromJson(Map<String, dynamic>.from(data as Map)),
    );
  }

  @override
  Future<Either<FailureResponse, void>> delete({
    required String refresh,
    required String password,
  }) async {
    final response = await _client.delete(
      parameter: Requests(
        EndpointKey.me.path,
        body: {'refresh': refresh, 'password': password},
      ),
    );

    return response.either(FailureResponse.fromJson, (_) {});
  }

  @override
  Future<Either<FailureResponse, DataModel<UserResponse>>> update({
    String? name,
    String? newPassword,
    String? currentPassword,
  }) async {
    final response = await _client.patch(
      parameter: Requests(
        EndpointKey.me.path,
        body: {
          'name': ?name,
          'new_password': ?newPassword,
          'current_password': ?currentPassword,
        },
      ),
    );

    return response.toDataModel(
      (data) => UserResponse.fromJson(Map<String, dynamic>.from(data as Map)),
    );
  }
}
