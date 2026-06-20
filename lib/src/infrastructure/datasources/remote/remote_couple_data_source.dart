import 'package:trocado/src/domain/either/either.dart';

import 'package:trocado/src/infrastructure/clients/http/http_client.dart';
import 'package:trocado/src/infrastructure/clients/http/endpoint_key.dart';
import 'package:trocado/src/infrastructure/clients/http/requests/requests.dart';
import 'package:trocado/src/infrastructure/clients/http/responses/couple/couple_response.dart';
import 'package:trocado/src/infrastructure/clients/http/responses/couple/invite_response.dart';
import 'package:trocado/src/infrastructure/clients/http/responses/failure/failure_response.dart';
import 'package:trocado/src/infrastructure/clients/http/responses/couple/invite_accept_response.dart';

abstract interface class IRemoteCoupleDataSource {
  Future<Either<FailureResponse, void>> dissolve();
  Future<Either<FailureResponse, CoupleResponse>> findActive();
  Future<Either<FailureResponse, InviteResponse>> createInvite();
  Future<Either<FailureResponse, InviteAcceptResponse>> acceptInvite({
    required String code,
  });
}

final class RemoteCoupleDataSource implements IRemoteCoupleDataSource {
  final IHttpClient _client;

  RemoteCoupleDataSource({required this._client});

  @override
  Future<Either<FailureResponse, void>> dissolve() async {
    final response = await _client.delete(
      parameter: Requests(EndpointKey.couple.path),
    );

    return response.either(FailureResponse.fromJson, (_) {});
  }

  @override
  Future<Either<FailureResponse, CoupleResponse>> findActive() async {
    final response = await _client.get(
      parameter: Requests(EndpointKey.couple.path),
    );

    return response.either(FailureResponse.fromJson, CoupleResponse.fromJson);
  }

  @override
  Future<Either<FailureResponse, InviteResponse>> createInvite() async {
    final response = await _client.post(
      parameter: Requests(EndpointKey.coupleInvites.path),
    );

    return response.either(FailureResponse.fromJson, InviteResponse.fromJson);
  }

  @override
  Future<Either<FailureResponse, InviteAcceptResponse>> acceptInvite({
    required String code,
  }) async {
    final response = await _client.post(
      parameter: Requests('${EndpointKey.invites.path}/$code/accept'),
    );

    return response.either(
      FailureResponse.fromJson,
      InviteAcceptResponse.fromJson,
    );
  }
}
