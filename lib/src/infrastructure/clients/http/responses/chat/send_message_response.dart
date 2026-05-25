final class SendMessageResponse {
  final int taskId;
  final String status;
  final String sessionId;

  const SendMessageResponse({
    required this.taskId,
    required this.status,
    required this.sessionId,
  });

  factory SendMessageResponse.fromJson(Map<String, dynamic> json) =>
      SendMessageResponse(
        taskId: json['task_id'] as int,
        status: json['status'] as String,
        sessionId: json['session_id'] as String,
      );
}
