import 'package:trocado/src/domain/either/either.dart';

import 'package:trocado/src/infrastructure/clients/http/http_client.dart';
import 'package:trocado/src/infrastructure/clients/http/endpoint_key.dart';
import 'package:trocado/src/infrastructure/clients/http/requests/requests.dart';
import 'package:trocado/src/infrastructure/clients/http/responses/couple/couple_response.dart';
import 'package:trocado/src/infrastructure/clients/http/responses/couple/invite_response.dart';
import 'package:trocado/src/infrastructure/clients/http/responses/failure/failure_response.dart';
import 'package:trocado/src/infrastructure/clients/http/responses/couple/invite_lookup_response.dart';

abstract interface class IRemoteCoupleDataSource {
  Future<Either<FailureResponse, void>> dissolve();
  Future<Either<FailureResponse, CoupleResponse>> findActive();
  Future<Either<FailureResponse, InviteResponse>> createInvite();
  Future<Either<FailureResponse, InviteLookupResponse>> lookupInvite({
    required String code,
  });
  Future<Either<FailureResponse, InviteLookupResponse>> acceptInvite({
    required String code,
  });
}

final class RemoteCoupleDataSource implements IRemoteCoupleDataSource {
  final IHttpClient _client;

  RemoteCoupleDataSource({required IHttpClient client}) : _client = client;

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
  Future<Either<FailureResponse, InviteLookupResponse>> lookupInvite({
    required String code,
  }) async {
    final response = await _client.get(
      parameter: Requests('${EndpointKey.coupleInvites.path}/$code'),
    );

    return response.either(
      FailureResponse.fromJson,
      InviteLookupResponse.fromJson,
    );
  }

  @override
  Future<Either<FailureResponse, InviteLookupResponse>> acceptInvite({
    required String code,
  }) async {
    final response = await _client.post(
      parameter: Requests('${EndpointKey.coupleInvites.path}/$code/accept'),
    );

    return response.either(
      FailureResponse.fromJson,
      InviteLookupResponse.fromJson,
    );
  }
}
