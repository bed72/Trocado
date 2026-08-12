import 'package:trocado/src/domain/either/either.dart';
import 'package:trocado/src/domain/failures/failure.dart';
import 'package:trocado/src/domain/models/chat/chat_result_model.dart';
import 'package:trocado/src/domain/repositories/interface_chat_repository.dart';

import 'package:trocado/src/data/extensions/failure_response_extension.dart';
import 'package:trocado/src/data/extensions/chat/chat_result_response_extension.dart';

import 'package:trocado/src/infrastructure/datasources/local/local_chat_data_source.dart';
import 'package:trocado/src/infrastructure/datasources/remote/remote_chat_data_source.dart';

final class ChatRepository implements IChatRepository {
  final ILocalChatDataSource _localDataSource;
  final IRemoteChatDataSource _remoteDataSource;

  ChatRepository({
    required this._localDataSource,
    required this._remoteDataSource,
  });

  @override
  Future<Either<Failure, int>> sendMessage({
    required String message,
    String? sessionId,
  }) async {
    final response = await _remoteDataSource.sendMessage(
      message: message,
      sessionId: sessionId,
    );

    if (response.isLeft) return Left(response.left.toFailure());

    await _localDataSource.saveSessionId(
      sessionId: response.right.data.sessionId,
    );

    return Right(response.right.data.taskId);
  }

  @override
  Future<Either<Failure, ChatResultModel>> getResult({
    required int taskId,
  }) async {
    final response = await _remoteDataSource.getResult(taskId: taskId);

    return response.either(
      (failure) => failure.toFailure(),
      (success) => success.data.toModel(),
    );
  }
}
