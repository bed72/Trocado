import 'package:trocado/src/domain/models/chat/chat_result_model.dart';

import 'package:trocado/src/infrastructure/clients/http/responses/chat/chat_result_response.dart';

extension ChatResultResponseExtension on ChatResultResponse {
  ChatResultModel toModel() => ChatResultModel(
    status: status,
    answer: answer,
    sessionId: sessionId,
  );
}
