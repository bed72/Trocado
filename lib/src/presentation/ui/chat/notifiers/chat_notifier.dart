import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:trocado/src/main/providers/storage_provider.dart';
import 'package:trocado/src/main/providers/repositories_provider.dart';

import 'package:trocado/src/presentation/ui/chat/notifiers/chat_state.dart';
import 'package:trocado/src/presentation/ui/chat/notifiers/chat_intent.dart';

import 'package:trocado/src/domain/models/chat/chat_message_model.dart';
import 'package:trocado/src/domain/repositories/interface_chat_repository.dart';

import 'package:trocado/src/infrastructure/datasources/local/local_chat_data_source.dart';

part 'chat_notifier.g.dart';

@Riverpod()
final class ChatNotifier extends _$ChatNotifier {
  late IChatRepository _repository;
  late ILocalChatDataSource _localDataSource;

  Timer? _pollingTimer;
  int _pollingAttempts = 0;
  String _currentMessage = '';

  @override
  ChatState build() {
    _repository = ref.watch(chatRepositoryProvider);
    _localDataSource = ref.watch(localChatDataSourceProvider);

    ref.onDispose(() => _pollingTimer?.cancel());

    _loadSessionId();

    return const ChatState();
  }

  void dispatch(ChatIntent intent) => switch (intent) {
    MessageChanged(:final value) => _currentMessage = value,
    SendPressed() => _send(),
  };

  Future<void> _loadSessionId() async {
    final sessionId = await _localDataSource.getSessionId();
    if (sessionId != null) {
      state = state.copyWith(sessionId: sessionId);
    }
  }

  Future<void> _send() async {
    if (_currentMessage.trim().isEmpty) return;

    final userMessage = ChatMessageModel(
      sender: .user,
      content: _currentMessage.trim(),
    );

    state = state.copyWith(
      status: .sending,
      clearFailureMessage: true,
      messages: [...state.messages, userMessage],
    );

    _currentMessage = '';

    final data = await _repository.sendMessage(
      sessionId: state.sessionId,
      message: userMessage.content,
    );

    data.fold(
      (failure) => state = state.copyWith(
        status: .failure,
        failureMessage: failure.message,
      ),
      (taskId) => _startPolling(taskId),
    );
  }

  void _startPolling(int taskId) {
    _pollingAttempts = 0;
    state = state.copyWith(status: .polling);
    _poll(taskId);
  }

  Future<void> _poll(int taskId) async {
    final data = await _repository.getResult(taskId: taskId);

    data.fold(
      (failure) {
        _pollingTimer?.cancel();
        state = state.copyWith(
          status: .failure,
          failureMessage: failure.message,
        );
      },
      (chatResult) {
        if (chatResult.isReady) {
          _pollingTimer?.cancel();

          final assistantMessage = ChatMessageModel(
            sender: .assistant,
            content: chatResult.answer!,
          );

          state = state.copyWith(
            status: .ready,
            sessionId: chatResult.sessionId ?? state.sessionId,
            messages: [...state.messages, assistantMessage],
          );
        } else {
          _scheduleNextPoll(taskId);
        }
      },
    );
  }

  void _scheduleNextPoll(int taskId) {
    _pollingAttempts++;

    final elapsed = _calculateElapsedMs();
    if (elapsed >= 60000) {
      _pollingTimer?.cancel();
      final timeoutMessage = ChatMessageModel(
        sender: .assistant,
        content: 'Não foi possível obter a resposta. Tente novamente.',
      );
      state = state.copyWith(
        status: .ready,
        messages: [...state.messages, timeoutMessage],
      );

      return;
    }

    final delay = _getBackoffDelay();
    _pollingTimer = Timer(Duration(milliseconds: delay), () => _poll(taskId));
  }

  int _getBackoffDelay() => switch (_pollingAttempts) {
    1 => 500,
    2 => 1000,
    3 => 2000,
    _ => 3000,
  };

  int _calculateElapsedMs() {
    int total = 0;
    for (int i = 0; i < _pollingAttempts; i++) {
      total += switch (i + 1) {
        1 => 500,
        2 => 1000,
        3 => 2000,
        _ => 3000,
      };
    }
    return total;
  }
}
