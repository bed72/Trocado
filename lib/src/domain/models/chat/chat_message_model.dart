import 'package:equatable/equatable.dart';

import 'package:trocado/src/domain/enums/chat/chat_sender_enum.dart';

final class ChatMessageModel extends Equatable {
  final String content;
  final ChatSenderEnum sender;

  const ChatMessageModel({required this.sender, required this.content});

  @override
  List<Object?> get props => [sender, content];
}
