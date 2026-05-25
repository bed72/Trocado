import 'package:equatable/equatable.dart';

final class ChatResultModel extends Equatable {
  final String status;
  final String? answer;
  final String? sessionId;

  const ChatResultModel({
    required this.status,
    this.answer,
    this.sessionId,
  });

  bool get isReady => status == 'ready';

  @override
  List<Object?> get props => [status, answer, sessionId];
}
