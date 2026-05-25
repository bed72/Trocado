final class SendMessageRequest {
  final String message;

  const SendMessageRequest({required this.message});

  Map<String, dynamic> toJson() => {'message': message};
}
