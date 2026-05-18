sealed class Failure {
  const Failure(this.message);

  final String message;

  @override
  String toString() => message;
}

final class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

final class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'Falha desconhecida.']);
}

final class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'Recurso não encontrado.']);
}

final class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Falha interna do servidor.']);
}

final class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Sem conexão com o servidor.']);
}
