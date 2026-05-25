final class ChatResultResponse {
  final String status;
  final String? answer;
  final String? sessionId;

  const ChatResultResponse({
    required this.status,
    this.answer,
    this.sessionId,
  });

  factory ChatResultResponse.fromJson(Map<String, dynamic> json) =>
      ChatResultResponse(
        status: json['status'] as String,
        answer: json['answer'] as String?,
        sessionId: json['session_id'] as String?,
      );
}
