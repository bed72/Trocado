import 'package:flutter/material.dart';

import 'package:trocado/src/domain/models/chat/chat_message_model.dart';

import 'package:trocado/src/presentation/ui/chat/widgets/chat_message_bubble_widget.dart';
import 'package:trocado/src/presentation/ui/chat/widgets/chat_typing_indicator_widget.dart';

class ChatMessagesWidget extends StatelessWidget {
  final bool isPolling;
  final List<ChatMessageModel> messages;

  const ChatMessagesWidget({
    super.key,
    required this.messages,
    required this.isPolling,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      reverse: true,
      itemCount: messages.length + (isPolling ? 1 : 0),
      padding: const .symmetric(horizontal: 16.0, vertical: 8.0),
      itemBuilder: (context, index) {
        if (isPolling && index == 0) {
          return const ChatTypingIndicatorWidget();
        }

        final messageIndex = isPolling
            ? messages.length - index
            : messages.length - 1 - index;

        return ChatMessageBubbleWidget(message: messages[messageIndex]);
      },
    );
  }
}
