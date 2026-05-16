import 'package:trocado/src/data/extensions/invite_response_extension.dart';
import 'package:trocado/src/data/extensions/couple_response_extension.dart';
import 'package:trocado/src/data/extensions/failure_response_extension.dart';

import 'package:trocado/src/domain/either/either.dart';
import 'package:trocado/src/domain/failures/failure.dart';
import 'package:trocado/src/domain/models/couple/invite_model.dart';
import 'package:trocado/src/domain/models/couple/couple_model.dart';
import 'package:trocado/src/domain/repositories/interface_couple_repository.dart';

import 'package:trocado/src/infrastructure/datasources/remote/remote_couple_data_source.dart';

final class CoupleRepository implements ICoupleRepository {
  final IRemoteCoupleDataSource _dataSource;

  CoupleRepository({required IRemoteCoupleDataSource dataSource})
    : _dataSource = dataSource;

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
}
