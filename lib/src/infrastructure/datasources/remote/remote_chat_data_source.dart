import 'package:trocado/src/domain/either/either.dart';

import 'package:trocado/src/infrastructure/clients/http/http_client.dart';
import 'package:trocado/src/infrastructure/clients/http/endpoint_key.dart';
import 'package:trocado/src/infrastructure/clients/http/requests/requests.dart';
import 'package:trocado/src/infrastructure/clients/http/responses/reponses.dart';
import 'package:trocado/src/infrastructure/clients/http/responses/data_model.dart';
import 'package:trocado/src/infrastructure/clients/http/responses/failure/failure_response.dart';
import 'package:trocado/src/infrastructure/clients/http/requests/chat/send_message_request.dart';
import 'package:trocado/src/infrastructure/clients/http/responses/chat/chat_result_response.dart';
import 'package:trocado/src/infrastructure/clients/http/responses/chat/send_message_response.dart';

abstract interface class IRemoteChatDataSource {
  Future<Either<FailureResponse, DataModel<ChatResultResponse>>> getResult({
    required int taskId,
  });
  Future<Either<FailureResponse, DataModel<SendMessageResponse>>> sendMessage({
    required String message,
    String? sessionId,
  });
}

final class RemoteChatDataSource implements IRemoteChatDataSource {
  final IHttpClient _client;

  RemoteChatDataSource({required this._client});

  @override
  Future<Either<FailureResponse, DataModel<SendMessageResponse>>> sendMessage({
    required String message,
    String? sessionId,
  }) async {
    final response = await _client.post(
      parameter: Requests(
        EndpointKey.chat.path,
        body: SendMessageRequest(message: message).toJson(),
      ),
    );
    return response.toDataModel(
      (data) =>
          SendMessageResponse.fromJson(Map<String, dynamic>.from(data as Map)),
    );
  }

  @override
  Future<Either<FailureResponse, DataModel<ChatResultResponse>>> getResult({
    required int taskId,
  }) async {
    final response = await _client.get(
      parameter: Requests('${EndpointKey.chat.path}/result/$taskId'),
    );
    return response.toDataModel(
      (data) =>
          ChatResultResponse.fromJson(Map<String, dynamic>.from(data as Map)),
    );
  }
}
