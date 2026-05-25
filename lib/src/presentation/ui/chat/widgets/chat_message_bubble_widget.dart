import 'package:flutter/material.dart';

import 'package:trocado/src/domain/models/chat/chat_message_model.dart';

import 'package:trocado/src/presentation/extensions/context_extension.dart';

class ChatMessageBubbleWidget extends StatelessWidget {
  final ChatMessageModel message;

  const ChatMessageBubbleWidget({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.sender == .user;

    return Align(
      alignment: isUser ? .centerRight : .centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: context.width * 0.75),
        margin: const .symmetric(vertical: 4.0),
        padding: const .symmetric(horizontal: 14.0, vertical: 10.0),
        decoration: BoxDecoration(
          color: isUser
              ? context.colors.primary
              : context.colors.surfaceContainerHighest,
          borderRadius: .only(
            topLeft: const .circular(16.0),
            topRight: const .circular(16.0),
            bottomLeft: .circular(isUser ? 16.0 : 4.0),
            bottomRight: .circular(isUser ? 4.0 : 16.0),
          ),
        ),
        child: Text(
          message.content,
          style: context.typography.bodyMedium?.copyWith(
            color: isUser ? context.colors.onPrimary : context.colors.onSurface,
          ),
        ),
      ),
    );
  }
}
