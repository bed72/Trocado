import 'package:trocado/src/domain/either/either.dart';

import 'package:trocado/src/infrastructure/clients/http/responses/data_model.dart';
import 'package:trocado/src/infrastructure/clients/http/responses/failure/failure_response.dart';

typedef Responses = Either<Map<String, dynamic>, Map<String, dynamic>>;

extension ResponsesExtension on Responses {
  Either<FailureResponse, DataModel<T>> toDataModel<T>(
    T Function(Object? data) parser,
  ) => either(
    FailureResponse.fromJson,
    (json) => DataModel<T>.fromJson(json, parser),
  );
}
