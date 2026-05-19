import 'dart:async';

import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:trocado/src/main/providers/storage_provider.dart';
import 'package:trocado/src/main/providers/clients_provider.dart';

import 'package:trocado/src/domain/either/either.dart';

import 'package:trocado/src/infrastructure/clients/http/http_client.dart';
import 'package:trocado/src/infrastructure/clients/storage/storage_key.dart';
import 'package:trocado/src/infrastructure/clients/http/requests/requests.dart';
import 'package:trocado/src/infrastructure/clients/storage/storage_client.dart';
import 'package:trocado/src/infrastructure/clients/messaging/messaging_client.dart';

import 'package:trocado/src/presentation/ui/authentication/sign_in/notifiers/sign_in_state.dart';
import 'package:trocado/src/presentation/ui/authentication/sign_in/notifiers/sign_in_intent.dart';
import 'package:trocado/src/presentation/ui/authentication/sign_in/notifiers/sign_in_notifier.dart';

import '../../../../mocks/mocks.dart';

const _signInPath = '/api/v1/token';
const _fcmTokenPath = '/api/v1/me/fcm-token';

const _signInSuccessBody = {
  'access': 'access-token',
  'refresh': 'refresh-token',
};

const _invalidCredentialsBody = {
  'errors': [
    {
      'field': 'non_field_errors',
      'code': 'no_active_account',
      'message': 'No active account found with the given credentials.',
    },
  ],
};

const _networkErrorBody = {
  'errors': [
    {
      'code': 'network_error',
      'field': 'non_field_errors',
      'message': 'Network error',
    },
  ],
};

const _serverErrorBody = {
  'errors': [
    {
      'code': 'server_error',
      'field': 'non_field_errors',
      'message': 'Internal server error',
    },
  ],
};

void main() {
  late IHttpClient httpClient;
  late IStorageClient storageClient;
  late IMessagingClient messagingClient;

  setUp(() {
    httpClient = MockHttpClient();
    storageClient = MockStorageClient();
    messagingClient = MockMessagingClient();

    registerFallbackValue(const Requests('/'));

    when(
      () => storageClient.write(
        key: any(named: 'key'),
        value: any(named: 'value'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => storageClient.read(key: any(named: 'key')),
    ).thenAnswer((_) async => null);
    when(() => storageClient.clear()).thenAnswer((_) async {});

    when(() => messagingClient.platform).thenReturn('android');
    when(() => messagingClient.getToken()).thenAnswer((_) async => 'fcm-token');
  });

  ProviderContainer makeContainer() {
    final container = ProviderContainer(
      overrides: [
        httpClientProvider.overrideWithValue(httpClient),
        storageClientProvider.overrideWithValue(storageClient),
        messagingClientProvider.overrideWithValue(messagingClient),
      ],
    );
    addTearDown(container.dispose);
    container.listen(signInProvider, (_, _) {});
    return container;
  }

  void fillValidForm(ProviderContainer container) {
    final notifier = container.read(signInProvider.notifier);
    notifier.dispatch(const EmailChanged('jane@trocado.app'));
    notifier.dispatch(const PasswordChanged('secret123'));
  }

  void stubHttpSuccess() {
    when(() => httpClient.post(parameter: any(named: 'parameter'))).thenAnswer((
      invocation,
    ) async {
      final request = invocation.namedArguments[#parameter] as Requests;
      return switch (request.path) {
        _signInPath => const Right(_signInSuccessBody),
        _fcmTokenPath => const Right(<String, dynamic>{}),
        _ => const Right(<String, dynamic>{}),
      };
    });
  }

  List<Requests> capturedPosts() => verify(
    () => httpClient.post(parameter: captureAny(named: 'parameter')),
  ).captured.cast<Requests>();

  group('validation prevents network call', () {
    test('does not POST when both fields are empty', () {
      final container = makeContainer();

      container.read(signInProvider.notifier).dispatch(const SubmitPressed());

      final state = container.read(signInProvider);

      expect(state.status, SignInStatus.initial);
      expect(state.emailFailure, 'E-mail obrigatório');
      expect(state.passwordFailure, 'Senha obrigatória');

      verifyNever(() => httpClient.post(parameter: any(named: 'parameter')));
      verifyNever(
        () => storageClient.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      );
    });

    test('does not POST when password is shorter than 8 characters', () {
      final container = makeContainer();
      final notifier = container.read(signInProvider.notifier);

      notifier.dispatch(const EmailChanged('jane@trocado.app'));
      notifier.dispatch(const PasswordChanged('1234567'));
      notifier.dispatch(const SubmitPressed());

      expect(
        container.read(signInProvider).passwordFailure,
        'Senha deve ter ao menos 8 caracteres',
      );
      verifyNever(() => httpClient.post(parameter: any(named: 'parameter')));
    });
  });

  group('successful sign in', () {
    setUp(stubHttpSuccess);

    test('transitions initial -> loading -> success', () async {
      final container = makeContainer();
      fillValidForm(container);

      container.read(signInProvider.notifier).dispatch(const SubmitPressed());
      expect(container.read(signInProvider).status, SignInStatus.loading);

      await Future<void>.delayed(Duration.zero);

      final state = container.read(signInProvider);
      expect(state.status, SignInStatus.success);
      expect(state.message, '');
    });

    test('POSTs sign-in payload to /api/v1/token', () async {
      final container = makeContainer();
      fillValidForm(container);

      container.read(signInProvider.notifier).dispatch(const SubmitPressed());
      await Future<void>.delayed(Duration.zero);

      final signInCall = capturedPosts().firstWhere(
        (request) => request.path == _signInPath,
      );
      expect(signInCall.body, {
        'email': 'jane@trocado.app',
        'password': 'secret123',
      });
    });

    test('persists access and refresh tokens after success', () async {
      final container = makeContainer();
      fillValidForm(container);

      container.read(signInProvider.notifier).dispatch(const SubmitPressed());
      await Future<void>.delayed(Duration.zero);

      verify(
        () => storageClient.write(
          key: StorageKey.accessToken.value,
          value: 'access-token',
        ),
      ).called(1);
      verify(
        () => storageClient.write(
          key: StorageKey.refreshToken.value,
          value: 'refresh-token',
        ),
      ).called(1);
    });

    test('registers FCM token after successful sign in', () async {
      final container = makeContainer();
      fillValidForm(container);

      container.read(signInProvider.notifier).dispatch(const SubmitPressed());
      await Future<void>.delayed(Duration.zero);

      verify(() => messagingClient.getToken()).called(1);
      final fcmCall = capturedPosts().firstWhere(
        (request) => request.path == _fcmTokenPath,
      );
      expect(fcmCall.body?['token'], 'fcm-token');
      expect(fcmCall.body?['platform'], 'android');
    });

    test('still reaches success when messaging returns null token', () async {
      when(() => messagingClient.getToken()).thenAnswer((_) async => null);
      final container = makeContainer();
      fillValidForm(container);

      container.read(signInProvider.notifier).dispatch(const SubmitPressed());
      await Future<void>.delayed(Duration.zero);

      expect(container.read(signInProvider).status, SignInStatus.success);
      verify(() => messagingClient.getToken()).called(1);
      final posts = capturedPosts();
      expect(posts.length, 1);
      expect(posts.single.path, _signInPath);
    });
  });

  group('failed sign in', () {
    test('invalid credentials map to ValidationFailure message', () async {
      when(
        () => httpClient.post(parameter: any(named: 'parameter')),
      ).thenAnswer((_) async => const Left(_invalidCredentialsBody));

      final container = makeContainer();
      fillValidForm(container);

      container.read(signInProvider.notifier).dispatch(const SubmitPressed());
      await Future<void>.delayed(Duration.zero);

      final state = container.read(signInProvider);
      expect(state.status, SignInStatus.failure);
      expect(
        state.message,
        'No active account found with the given credentials.',
      );
    });

    test('network_error code maps to NetworkFailure message', () async {
      when(
        () => httpClient.post(parameter: any(named: 'parameter')),
      ).thenAnswer((_) async => const Left(_networkErrorBody));

      final container = makeContainer();
      fillValidForm(container);

      container.read(signInProvider.notifier).dispatch(const SubmitPressed());
      await Future<void>.delayed(Duration.zero);

      final state = container.read(signInProvider);
      expect(state.status, SignInStatus.failure);
      expect(state.message, 'Sem conexão com o servidor.');
    });

    test('server_error code maps to ServerFailure message', () async {
      when(
        () => httpClient.post(parameter: any(named: 'parameter')),
      ).thenAnswer((_) async => const Left(_serverErrorBody));

      final container = makeContainer();
      fillValidForm(container);

      container.read(signInProvider.notifier).dispatch(const SubmitPressed());
      await Future<void>.delayed(Duration.zero);

      final state = container.read(signInProvider);
      expect(state.status, SignInStatus.failure);
      expect(state.message, 'Falha interna do servidor.');
    });

    test('does not persist tokens on failure', () async {
      when(
        () => httpClient.post(parameter: any(named: 'parameter')),
      ).thenAnswer((_) async => const Left(_invalidCredentialsBody));

      final container = makeContainer();
      fillValidForm(container);

      container.read(signInProvider.notifier).dispatch(const SubmitPressed());
      await Future<void>.delayed(Duration.zero);

      verifyNever(
        () => storageClient.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      );
    });

    test('does not register FCM token on failure', () async {
      when(
        () => httpClient.post(parameter: any(named: 'parameter')),
      ).thenAnswer((_) async => const Left(_invalidCredentialsBody));

      final container = makeContainer();
      fillValidForm(container);

      container.read(signInProvider.notifier).dispatch(const SubmitPressed());
      await Future<void>.delayed(Duration.zero);

      verifyNever(() => messagingClient.getToken());
    });
  });

  group('FCM side-effect timing', () {
    test('slow FCM register does not block success transition', () async {
      final completer =
          Completer<Either<Map<String, dynamic>, Map<String, dynamic>>>();

      when(
        () => httpClient.post(parameter: any(named: 'parameter')),
      ).thenAnswer((invocation) async {
        final request = invocation.namedArguments[#parameter] as Requests;
        return switch (request.path) {
          _signInPath => const Right(_signInSuccessBody),
          _ => completer.future,
        };
      });

      final container = makeContainer();
      fillValidForm(container);

      container.read(signInProvider.notifier).dispatch(const SubmitPressed());
      await Future<void>.delayed(Duration.zero);

      expect(container.read(signInProvider).status, SignInStatus.success);
      expect(completer.isCompleted, isFalse);

      completer.complete(const Right(<String, dynamic>{}));
    });
  });
}
