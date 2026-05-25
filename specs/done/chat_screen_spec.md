# Spec: Chat Screen

## Resumo

Tela de chat com assistente financeiro IA. Comunicação assíncrona via HTTP polling (sem WebSocket). O usuário envia uma mensagem, a API retorna um `task_id`, e o app faz polling com backoff progressivo até receber a resposta.

---

## API

### POST /api/v1/chat

Envia mensagem do usuário.

**Request:**
```json
{ "message": "Quanto gastei em comida esse mês?" }
```

**Response 202:**
```json
{ "task_id": 564, "session_id": "f4e1aa26-0234-4b85-8b92-c6bc0efbad53", "status": "processing" }
```

**Error:**
```json
{ "errors": [{ "field": "string", "message": "string", "code": "string" }] }
```

### GET /api/v1/chat/result/{task_id}

Consulta resultado da mensagem.

**Response 200 (ready):**
```json
{ "status": "ready", "answer": "Você gastou R$ 450,00 em comida.", "session_id": "f4e1aa26-..." }
```

**Response 200 (processing):**
```json
{ "status": "processing" }
```

**Error:**
```json
{ "errors": [{ "field": "string", "message": "string", "code": "string" }] }
```

---

## Regras de Negócio

| # | Regra |
|---|---|
| 1 | Sem histórico — chat começa limpo a cada abertura da tela |
| 2 | Uma mensagem por vez — input desabilitado enquanto aguarda resposta |
| 3 | `session_id` persistido localmente (secure storage) entre sessões do app |
| 4 | Polling com backoff: 500ms → 1s → 2s → 3s (cap), timeout total 60s |
| 5 | Timeout expirado → mensagem de erro no chat como resposta do assistant |
| 6 | Mensagem do usuário aparece imediatamente no chat (otimistic) |
| 7 | Typing indicator visível enquanto status == `processing` |

---

## Domain

### Enum `ChatSenderEnum`

**Path:** `lib/src/domain/enums/chat/chat_sender_enum.dart`

```dart
enum ChatSenderEnum { user, assistant }
```

### Model `ChatMessageModel`

**Path:** `lib/src/domain/models/chat/chat_message_model.dart`

```dart
final class ChatMessageModel extends Equatable {
  final String content;
  final ChatSenderEnum sender;

  const ChatMessageModel({
    required this.content,
    required this.sender,
  });

  @override
  List<Object?> get props => [content, sender];
}
```

Sem `copyWith` — mensagens são imutáveis e nunca editadas após criação.

### Repository Interface `IChatRepository`

**Path:** `lib/src/domain/repositories/interface_chat_repository.dart`

```dart
abstract interface class IChatRepository {
  Future<Either<Failure, int>> sendMessage({
    required String message,
    String? sessionId,
  });
  Future<Either<Failure, ChatResultModel>> getResult({required int taskId});
}
```

### Model `ChatResultModel`

**Path:** `lib/src/domain/models/chat/chat_result_model.dart`

```dart
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
```

---

## Infrastructure

### EndpointKey (adicionar)

```dart
chat('/api/v1/chat'),
// chatResult não entra no enum — path é dinâmico: /api/v1/chat/result/{taskId}
```

Para o GET com path dinâmico, o datasource monta o path manualmente: `'${EndpointKey.chat.path}/result/$taskId'`.

### StorageKey (adicionar)

```dart
chatSessionId('chat_session_id'),
```

### Request `SendMessageRequest`

**Path:** `lib/src/infrastructure/clients/http/requests/chat/send_message_request.dart`

```dart
final class SendMessageRequest {
  final String message;

  const SendMessageRequest({required this.message});

  Map<String, dynamic> toJson() => {'message': message};
}
```

### Response `SendMessageResponse`

**Path:** `lib/src/infrastructure/clients/http/responses/chat/send_message_response.dart`

```dart
final class SendMessageResponse {
  final int taskId;
  final String sessionId;
  final String status;

  const SendMessageResponse({
    required this.taskId,
    required this.sessionId,
    required this.status,
  });

  factory SendMessageResponse.fromJson(Map<String, dynamic> json) =>
      SendMessageResponse(
        taskId: json['task_id'] as int,
        sessionId: json['session_id'] as String,
        status: json['status'] as String,
      );
}
```

### Response `ChatResultResponse`

**Path:** `lib/src/infrastructure/clients/http/responses/chat/chat_result_response.dart`

```dart
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
```

### Datasource `IRemoteChatDataSource`

**Path:** `lib/src/infrastructure/datasources/remote/remote_chat_data_source.dart`

```dart
abstract interface class IRemoteChatDataSource {
  Future<Either<FailureResponse, SendMessageResponse>> sendMessage({
    required String message,
    String? sessionId,
  });
  Future<Either<FailureResponse, ChatResultResponse>> getResult({
    required int taskId,
  });
}

final class RemoteChatDataSource implements IRemoteChatDataSource {
  final IHttpClient _client;

  RemoteChatDataSource({required IHttpClient client}) : _client = client;

  @override
  Future<Either<FailureResponse, SendMessageResponse>> sendMessage({
    required String message,
    String? sessionId,
  }) async {
    final response = await _client.post(
      parameter: Requests(
        EndpointKey.chat.path,
        body: SendMessageRequest(message: message).toJson(),
      ),
    );
    return response.either(FailureResponse.fromJson, SendMessageResponse.fromJson);
  }

  @override
  Future<Either<FailureResponse, ChatResultResponse>> getResult({
    required int taskId,
  }) async {
    final response = await _client.get(
      parameter: Requests('${EndpointKey.chat.path}/result/$taskId'),
    );
    return response.either(FailureResponse.fromJson, ChatResultResponse.fromJson);
  }
}
```

### Datasource `ILocalChatDataSource`

**Path:** `lib/src/infrastructure/datasources/local/local_chat_data_source.dart`

```dart
abstract interface class ILocalChatDataSource {
  Future<String?> getSessionId();
  Future<void> saveSessionId({required String sessionId});
}

final class LocalChatDataSource implements ILocalChatDataSource {
  final IStorageClient _client;

  LocalChatDataSource({required IStorageClient client}) : _client = client;

  @override
  Future<String?> getSessionId() =>
      _client.read(key: StorageKey.chatSessionId.value);

  @override
  Future<void> saveSessionId({required String sessionId}) =>
      _client.write(key: StorageKey.chatSessionId.value, value: sessionId);
}
```

---

## Data

### Extension `SendMessageResponseExtension`

**Path:** `lib/src/data/extensions/chat/send_message_response_extension.dart`

```dart
extension SendMessageResponseExtension on SendMessageResponse {
  int toTaskId() => taskId;
}
```

### Extension `ChatResultResponseExtension`

**Path:** `lib/src/data/extensions/chat/chat_result_response_extension.dart`

```dart
extension ChatResultResponseExtension on ChatResultResponse {
  ChatResultModel toModel() => ChatResultModel(
    status: status,
    answer: answer,
    sessionId: sessionId,
  );
}
```

### Repository `ChatRepository`

**Path:** `lib/src/data/repositories/chat_repository.dart`

```dart
final class ChatRepository implements IChatRepository {
  final IRemoteChatDataSource _remoteDataSource;
  final ILocalChatDataSource _localDataSource;

  ChatRepository({
    required IRemoteChatDataSource remoteDataSource,
    required ILocalChatDataSource localDataSource,
  })  : _remoteDataSource = remoteDataSource,
       _localDataSource = localDataSource;

  @override
  Future<Either<Failure, int>> sendMessage({
    required String message,
    String? sessionId,
  }) async {
    final data = await _remoteDataSource.sendMessage(
      message: message,
      sessionId: sessionId,
    );

    if (data.isLeft) return Left(data.left.toFailure());

    await _localDataSource.saveSessionId(sessionId: data.right.sessionId);

    return Right(data.right.taskId);
  }

  @override
  Future<Either<Failure, ChatResultModel>> getResult({
    required int taskId,
  }) async {
    final data = await _remoteDataSource.getResult(taskId: taskId);
    return data.either(
      (failure) => failure.toFailure(),
      (response) => response.toModel(),
    );
  }
}
```

---

## Presentation

### State `ChatState`

**Path:** `lib/src/presentation/ui/chat/notifiers/chat_state.dart`

```dart
enum ChatStatus { initial, sending, polling, ready, failure }

final class ChatState extends Equatable {
  final String? sessionId;
  final ChatStatus status;
  final String? failureMessage;
  final List<ChatMessageModel> messages;

  const ChatState({
    this.sessionId,
    this.failureMessage,
    this.messages = const [],
    this.status = ChatStatus.initial,
  });

  bool get isProcessing => status == ChatStatus.sending || status == ChatStatus.polling;

  ChatState copyWith({
    String? sessionId,
    ChatStatus? status,
    String? failureMessage,
    List<ChatMessageModel>? messages,
    bool clearFailureMessage = false,
  }) => ChatState(
    sessionId: sessionId ?? this.sessionId,
    status: status ?? this.status,
    messages: messages ?? this.messages,
    failureMessage: clearFailureMessage ? null : failureMessage ?? this.failureMessage,
  );

  @override
  List<Object?> get props => [sessionId, status, failureMessage, messages];
}
```

### Intent `ChatIntent`

**Path:** `lib/src/presentation/ui/chat/notifiers/chat_intent.dart`

```dart
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
```

### Notifier `ChatNotifier`

**Path:** `lib/src/presentation/ui/chat/notifiers/chat_notifier.dart`

```dart
@Riverpod()
final class ChatNotifier extends _$ChatNotifier {
  late IChatRepository _repository;
  late ILocalChatDataSource _localDataSource;

  String _currentMessage = '';
  Timer? _pollingTimer;
  int _pollingAttempts = 0;

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
      content: _currentMessage.trim(),
      sender: ChatSenderEnum.user,
    );

    state = state.copyWith(
      status: ChatStatus.sending,
      messages: [...state.messages, userMessage],
      clearFailureMessage: true,
    );

    _currentMessage = '';

    final data = await _repository.sendMessage(
      message: userMessage.content,
      sessionId: state.sessionId,
    );

    data.fold(
      (failure) => state = state.copyWith(
        status: ChatStatus.failure,
        failureMessage: failure.message,
      ),
      (taskId) => _startPolling(taskId),
    );
  }

  void _startPolling(int taskId) {
    _pollingAttempts = 0;
    state = state.copyWith(status: ChatStatus.polling);
    _poll(taskId);
  }

  Future<void> _poll(int taskId) async {
    final data = await _repository.getResult(taskId: taskId);

    data.fold(
      (failure) {
        _pollingTimer?.cancel();
        state = state.copyWith(
          status: ChatStatus.failure,
          failureMessage: failure.message,
        );
      },
      (chatResult) {
        if (chatResult.isReady) {
          _pollingTimer?.cancel();

          final assistantMessage = ChatMessageModel(
            content: chatResult.answer!,
            sender: ChatSenderEnum.assistant,
          );

          state = state.copyWith(
            status: ChatStatus.ready,
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
        content: 'Não foi possível obter a resposta. Tente novamente.',
        sender: ChatSenderEnum.assistant,
      );
      state = state.copyWith(
        status: ChatStatus.ready,
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
```

### Location `ChatLocation`

**Path:** `lib/src/presentation/ui/chat/locations/chat_location.dart`

```dart
final class ChatLocation extends Location {
  @override
  String get path => AppRoutes.chat.path;

  @override
  LocationBuilder? get builder => (context) => const ChatScreen();
}
```

### Screen `ChatScreen`

**Path:** `lib/src/presentation/ui/chat/screens/chat_screen.dart`

Estrutura:
- `Scaffold` com `SafeArea`
- `Column`:
  - `ScreenHeaderWidget(title: 'Chat', description: 'Converse com o Trocado')`
  - `Expanded` → lista de mensagens (ou empty state)
  - `ChatInputWidget` fixo no bottom

```dart
class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Consumer(
        builder: (context, ref, _) {
          final state = ref.watch(chatNotifierProvider);

          return Column(
            children: [
              const ScreenHeaderWidget(
                title: 'Chat',
                description: 'Converse com o Trocado',
              ),
              Expanded(
                child: state.messages.isEmpty
                    ? const ChatEmptyWidget()
                    : ChatMessagesWidget(
                        messages: state.messages,
                        isPolling: state.status == ChatStatus.polling,
                      ),
              ),
              ChatInputWidget(
                enabled: !state.isProcessing,
                onChanged: (value) => ref
                    .read(chatNotifierProvider.notifier)
                    .dispatch(MessageChanged(value)),
                onSend: () => ref
                    .read(chatNotifierProvider.notifier)
                    .dispatch(const SendPressed()),
              ),
            ],
          );
        },
      ),
    ),
  );
}
```

### Widgets

**Path base:** `lib/src/presentation/ui/chat/widgets/`

#### `ChatInputWidget`

**Path:** `lib/src/presentation/ui/chat/widgets/chat_input_widget.dart`

- `TextField` com `maxLines: 3`, `minLines: 1` (cresce até 3 linhas, scroll interno depois)
- Botão de enviar (ícone `Icons.send`) à direita, dentro de um suffix
- `enabled` controla se o campo aceita input
- `onChanged` callback para cada caractere
- `onSend` callback ao pressionar botão ou submit no teclado
- Limpa o texto internamente ao enviar (usa `TextEditingController`)
- Borda arredondada, estilo alinhado com o design system

#### `ChatMessageBubbleWidget`

**Path:** `lib/src/presentation/ui/chat/widgets/chat_message_bubble_widget.dart`

- Recebe `ChatMessageModel`
- User: alinhado à direita, cor `primary`
- Assistant: alinhado à esquerda, cor `surfaceContainerHighest`
- Texto com `bodyMedium`
- Border radius arredondado (16px), com canto inferior diferenciado por sender

#### `ChatTypingIndicatorWidget`

**Path:** `lib/src/presentation/ui/chat/widgets/chat_typing_indicator_widget.dart`

- Três pontos animados (dots pulse/bounce)
- Mesmo alinhamento e estilo do bubble do assistant
- Visível quando `status == ChatStatus.polling`

#### `ChatEmptyWidget`

**Path:** `lib/src/presentation/ui/chat/widgets/chat_empty_widget.dart`

- Centralizado verticalmente
- Ícone + texto de boas-vindas
- Sugestão de como usar (ex: "Pergunte sobre seus gastos")

#### `ChatMessagesWidget`

**Path:** `lib/src/presentation/ui/chat/widgets/chat_messages_widget.dart`

- `ListView.builder` com `reverse: true` (scroll natural de chat)
- Renderiza `ChatMessageBubbleWidget` para cada mensagem
- Se `isPolling == true`, mostra `ChatTypingIndicatorWidget` no final

---

## Main

### Providers

**Path:** `lib/src/main/providers/chat_provider.dart`

```dart
@Riverpod()
ILocalChatDataSource localChatDataSource(Ref ref) =>
    LocalChatDataSource(client: ref.watch(storageClientProvider));

@Riverpod()
IRemoteChatDataSource remoteChatDataSource(Ref ref) =>
    RemoteChatDataSource(client: ref.watch(httpClientProvider));

@Riverpod()
IChatRepository chatRepository(Ref ref) => ChatRepository(
  remoteDataSource: ref.watch(remoteChatDataSourceProvider),
  localDataSource: ref.watch(localChatDataSourceProvider),
);
```

### Route (adicionar em `AppRoutes`)

```dart
chat('/chat'),
```

### Location wiring (atualizar `HomeLocation`)

```dart
navigateToChat: () => context.navigate(ChatLocation()),
```

---

## Árvore de arquivos

```
lib/src/
├── domain/
│   ├── enums/chat/
│   │   └── chat_sender_enum.dart
│   ├── models/chat/
│   │   ├── chat_message_model.dart
│   │   └── chat_result_model.dart
│   └── repositories/
│       └── interface_chat_repository.dart
├── infrastructure/
│   ├── clients/http/
│   │   ├── endpoint_key.dart              (+ chat)
│   │   ├── requests/chat/
│   │   │   └── send_message_request.dart
│   │   └── responses/chat/
│   │       ├── send_message_response.dart
│   │       └── chat_result_response.dart
│   ├── clients/storage/
│   │   └── storage_key.dart               (+ chatSessionId)
│   └── datasources/
│       ├── remote/
│       │   └── remote_chat_data_source.dart
│       └── local/
│           └── local_chat_data_source.dart
├── data/
│   ├── extensions/chat/
│   │   ├── send_message_response_extension.dart
│   │   └── chat_result_response_extension.dart
│   └── repositories/
│       └── chat_repository.dart
├── presentation/ui/chat/
│   ├── locations/
│   │   └── chat_location.dart
│   ├── screens/
│   │   └── chat_screen.dart
│   ├── notifiers/
│   │   ├── chat_notifier.dart
│   │   ├── chat_state.dart
│   │   └── chat_intent.dart
│   └── widgets/
│       ├── chat_input_widget.dart
│       ├── chat_message_bubble_widget.dart
│       ├── chat_typing_indicator_widget.dart
│       ├── chat_messages_widget.dart
│       └── chat_empty_widget.dart
└── main/
    ├── providers/
    │   └── chat_provider.dart
    └── locations/                          (atualizar home_location + AppRoutes)
```

---

## Testes

| Arquivo | O que testa |
|---|---|
| `test/src/infrastructure/responses/chat/send_message_response_test.dart` | `fromJson` da SendMessageResponse |
| `test/src/infrastructure/responses/chat/chat_result_response_test.dart` | `fromJson` da ChatResultResponse |
| `test/src/data/repositories/chat_repository_test.dart` | Repository + Datasource (mock em IHttpClient) |
| `test/src/presentation/providers/chat_notifier_test.dart` | ChatNotifier com mock do IChatRepository + ILocalChatDataSource |

---

## Fora de escopo

- Histórico de mensagens persistido
- Múltiplas mensagens simultâneas
- Markdown rendering na resposta do assistant
- Upload de arquivos ou imagens
- Notificações push para respostas
