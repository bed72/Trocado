sealed class ChatIntent {
  const ChatIntent();
}

final class MessageChanged extends ChatIntent {
  final String value;
  const MessageChanged(this.value);
}

final class SendPressed extends ChatIntent {
  const SendPressed();
}
