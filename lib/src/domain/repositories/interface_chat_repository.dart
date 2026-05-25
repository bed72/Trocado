import 'package:trocado/src/domain/either/either.dart';
import 'package:trocado/src/domain/failures/failure.dart';

import 'package:trocado/src/domain/models/chat/chat_result_model.dart';

abstract interface class IChatRepository {
  Future<Either<Failure, ChatResultModel>> getResult({required int taskId});
  Future<Either<Failure, int>> sendMessage({
    required String message,
    String? sessionId,
  });
}
