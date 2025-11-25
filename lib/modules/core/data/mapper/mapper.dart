import 'package:trocado/modules/core/domain/either.dart';

abstract class Mapper<DTO, MODEL> {
  final String defaultError;

  Mapper({this.defaultError = 'Invalid data'});

  MODEL toModel(DTO data);
  Map<String, dynamic> toJson(DTO data);
  Either<String, DTO> fromJson(Map<String, dynamic>? data);

  Either<String, List<DTO>> fromJsons(List<Map<String, dynamic>>? data) {
    if (data == null) return Left(defaultError);
    if (data.isEmpty) return Right(<DTO>[]);

    final List<DTO> dtos = [];

    for (final value in data) {
      final either = fromJson(value);

      if (either.isLeft) return Left(either.left);

      dtos.add(either.right);
    }

    return Right(dtos);
  }
}
