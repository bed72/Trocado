sealed class Failure {
  const Failure(this.message);

  final String message;

  @override
  String toString() => message;
}

final class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Sem conexão com o servidor.']);
}

final class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'Recurso não encontrado.']);
}

final class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Erro interno do servidor.']);
}

final class DatabaseFailure extends Failure {
  const DatabaseFailure([super.message = 'Erro ao acessar o banco de dados.']);
}

final class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

final class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'Erro desconhecido.']);
}
