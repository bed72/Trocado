import 'package:trocado/src/domain/failures/failure.dart';

import 'package:trocado/src/infrastructure/clients/http/responses/failure/failure_code_response.dart';
import 'package:trocado/src/infrastructure/clients/http/responses/failure/failure_response.dart';

extension FailureResponseExtension on FailureResponse {
  Failure toFailure() {
    final failure = errors.first;

    return switch (FailureCodeResponse.fromString(failure.code ?? '')) {
      .notFound => const NotFoundFailure(),
      .serverError => const ServerFailure(),
      .networkError => const NetworkFailure(),
      _ => ValidationFailure(failure.message ?? 'Falha desconhecida.'),
    };
  }
}
