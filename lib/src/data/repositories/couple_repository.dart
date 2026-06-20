import 'package:trocado/src/data/extensions/invite_response_extension.dart';
import 'package:trocado/src/data/extensions/couple_response_extension.dart';
import 'package:trocado/src/data/extensions/failure_response_extension.dart';
import 'package:trocado/src/data/extensions/invite_accept_response_extension.dart';

import 'package:trocado/src/domain/either/either.dart';
import 'package:trocado/src/domain/failures/failure.dart';
import 'package:trocado/src/domain/models/couple/invite_model.dart';
import 'package:trocado/src/domain/models/couple/couple_model.dart';
import 'package:trocado/src/domain/models/couple/invite_accept_model.dart';
import 'package:trocado/src/domain/repositories/interface_couple_repository.dart';

import 'package:trocado/src/infrastructure/clients/share/share_client.dart';
import 'package:trocado/src/infrastructure/datasources/remote/remote_couple_data_source.dart';

final class CoupleRepository implements ICoupleRepository {
  final IShareClient _client;
  final IRemoteCoupleDataSource _dataSource;

  CoupleRepository({required this._client, required this._dataSource});

  @override
  Future<Either<Failure, CoupleModel>> findActive() async {
    final data = await _dataSource.findActive();

    return data.either(
      (failure) => failure.toFailure(),
      (response) => response.toModel(),
    );
  }

  @override
  Future<Either<Failure, InviteModel>> createInvite() async {
    final data = await _dataSource.createInvite();

    return data.either(
      (failure) => failure.toFailure(),
      (response) => response.toModel(),
    );
  }

  @override
  Future<Either<Failure, void>> dissolve() async {
    final data = await _dataSource.dissolve();

    return data.either((failure) => failure.toFailure(), (_) {});
  }

  @override
  Future<Either<Failure, void>> shareInvite({required String qrData}) async {
    await _client.shareText(
      'Vamos juntar nossas finanças no Trocado! Aceite meu convite: $qrData',
    );

    return const Right(null);
  }

  @override
  Future<Either<Failure, InviteAcceptModel>> acceptInvite({
    required String code,
  }) async {
    final data = await _dataSource.acceptInvite(code: code);

    return data.either(
      (failure) => failure.toFailure(),
      (response) => response.toModel(),
    );
  }
}
