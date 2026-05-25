import 'package:equatable/equatable.dart';

import 'package:trocado/src/domain/models/chat/chat_message_model.dart';

enum ChatStatus { initial, sending, polling, ready, failure }

final class ChatState extends Equatable {
  final String? sessionId;
  final ChatStatus status;
  final String? failureMessage;
  final List<ChatMessageModel> messages;

  const ChatState({
    this.sessionId,
    this.failureMessage,
    this.status = .initial,
    this.messages = const [],
  });

  bool get isProcessing => status == .sending || status == .polling;

  ChatState copyWith({
    String? sessionId,
    ChatStatus? status,
    String? failureMessage,
    List<ChatMessageModel>? messages,
    bool clearFailureMessage = false,
  }) => ChatState(
    status: status ?? this.status,
    messages: messages ?? this.messages,
    sessionId: sessionId ?? this.sessionId,
    failureMessage: clearFailureMessage
        ? null
        : failureMessage ?? this.failureMessage,
  );

  @override
  List<Object?> get props => [sessionId, status, failureMessage, messages];
}
