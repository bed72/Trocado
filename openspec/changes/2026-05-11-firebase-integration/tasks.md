# Tasks — firebase-integration

> Esta change é **incremental**. A Parte 1 (setup base) está descrita abaixo. Partes 2+ (Crashlytics, FCM, App Check) serão adicionadas como novas seções (`## Parte 2`, `## Parte 3`, etc.) quando cada uma for aprovada para implementação.

---

## Parte 1 — Setup base do Firebase

Ordem fixa: console + CLI (manual, pré-implementação) → pubspec → wrapper → provider → main.dart → Android Gradle → iOS Xcode → verificação.

### 0. Pré-implementação manual (executado pelo usuário; **bloqueia** a implementação)

- [ ] 0.1 Criar projeto **"Trocado"** no [Firebase Console](https://console.firebase.google.com) (plano Spark).
- [ ] 0.2 Habilitar Google Analytics opcional (recomendado).
- [ ] 0.3 Adicionar app Android: package `br.com.bed.trocado`, nickname `Trocado Android`. SHA-1 não obrigatório agora.
- [ ] 0.4 Adicionar app iOS: bundle ID `br.com.bed.trocado`, nickname `Trocado iOS`.
- [ ] 0.5 Local: `dart pub global activate flutterfire_cli` (skip se já instalado).
- [ ] 0.6 Local, no root do projeto: `flutterfire configure --project=trocado-<projectId>`. Confirmar que:
  - `android/app/google-services.json` foi criado.
  - `ios/Runner/GoogleService-Info.plist` foi criado **e** está referenciado no Xcode project (`project.pbxproj`).
  - `lib/firebase_options.dart` foi criado com `DefaultFirebaseOptions.currentPlatform`.

### 1. pubspec

- [ ] 1.1 No root do projeto: `flutter pub add firebase_core`. Confirmar que `pubspec.yaml` ganhou a entrada `firebase_core:` na seção `dependencies` e que `pubspec.lock` está coerente.
- [ ] 1.2 Verificar `flutter pub get` sem warnings.

### 2. Wrapper `FirebaseClient`

- [ ] 2.1 Criar pasta `lib/src/infrastructure/clients/firebase/`.
- [ ] 2.2 Criar `lib/src/infrastructure/clients/firebase/firebase_client.dart`:
  ```dart
  import 'package:firebase_core/firebase_core.dart';
  import 'package:trocado/firebase_options.dart';

  abstract interface class IFirebaseClient {
    Future<void> initialize();
  }

  final class FirebaseClient implements IFirebaseClient {
    @override
    Future<void> initialize() async {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    }
  }
  ```
  - Sem construtor, sem campos, sem dependências (espelha `LoggerClient` em `logger_client.dart`).

### 3. Provider Riverpod

- [ ] 3.1 Em `lib/src/main/providers/clients_provider.dart`, adicionar (após `loggerClient`, antes de `httpClient`):
  ```dart
  @Riverpod(keepAlive: true)
  IFirebaseClient firebaseClient(Ref _) => FirebaseClient();
  ```
- [ ] 3.2 Importar `firebase_client.dart` no topo do arquivo.
- [ ] 3.3 Rodar `dart run build_runner build --delete-conflicting-outputs`.
- [ ] 3.4 Verificar que `clients_provider.g.dart` ganhou `firebaseClientProvider`.

### 4. `main.dart` — inicialização explícita antes de `runApp`

- [ ] 4.1 Atualizar `lib/main.dart` para:
  ```dart
  import 'package:flutter/widgets.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';

  import 'package:trocado/app_widget.dart';
  import 'package:trocado/src/main/providers/clients_provider.dart';
  import 'package:trocado/src/presentation/observers/state_observer.dart';

  Future<void> main() async {
    WidgetsFlutterBinding.ensureInitialized();

    final container = ProviderContainer(observers: [stateObserver]);
    await container.read(firebaseClientProvider).initialize();

    runApp(UncontrolledProviderScope(container: container, child: AppWidget()));
  }
  ```
- [ ] 4.2 Verificar que `stateObserver` continua sendo passado ao container e que `AppWidget` recebe o `UncontrolledProviderScope`.
- [ ] 4.3 Conferir que nenhum outro lugar do app referencia `ProviderScope` direto (grep `ProviderScope` em `lib/`).

### 5. Android — plugin Gradle `google-services`

- [ ] 5.1 Em `android/build.gradle.kts` (root do módulo Android), adicionar ao bloco `plugins`:
  ```kotlin
  id("com.google.gms.google-services") version "4.4.x" apply false
  ```
  - Versão exata: olhar o [release atual no Maven](https://maven.google.com/web/index.html#com.google.gms:google-services) no momento da implementação e pinar.
- [ ] 5.2 Em `android/app/build.gradle.kts`, adicionar ao bloco `plugins` (depois de `dev.flutter.flutter-gradle-plugin`):
  ```kotlin
  id("com.google.gms.google-services")
  ```
- [ ] 5.3 Confirmar que `android/app/google-services.json` existe (criado pelo `flutterfire configure` na fase 0).
- [ ] 5.4 Verificar que `flutter build apk --debug` completa sem erro.

### 6. iOS — registro do plist (já feito pelo CLI; só verificar)

- [ ] 6.1 Abrir `ios/Runner.xcworkspace` no Xcode (uma vez) e confirmar que `GoogleService-Info.plist` aparece sob o target `Runner` com **Target Membership** marcado. Se não, arrastar o arquivo para o Xcode (não duplicar — usar "Create reference").
- [ ] 6.2 Verificar que `flutter build ios --debug --no-codesign` completa sem erro.
- [ ] 6.3 **Não** editar `AppDelegate.swift` nesta parte. Parte 4 (App Check) vai fazer isso.

### 7. Commit dos artefatos

- [ ] 7.1 `git add android/app/google-services.json ios/Runner/GoogleService-Info.plist lib/firebase_options.dart`. Os três são commitados (justificativa no `design.md`).
- [ ] 7.2 Confirmar que `.gitignore` **não** está ignorando os três arquivos. Se algum padrão existente (ex: `*.plist`) estiver bloqueando, adicionar exceção explícita.

### 8. Verificação

- [ ] 8.1 `flutter analyze` — zero warnings.
- [ ] 8.2 `flutter test` — toda a suíte passa (nenhum teste novo nesta parte).
- [ ] 8.3 **Smoke manual — Android**: `flutter run -d <android-emulator>`. App boota sem crash. Logcat mostra entrada do Firebase Core (`FirebaseApp`/`FirebaseInitProvider`). Login flow continua funcionando (regressão).
- [ ] 8.4 **Smoke manual — iOS**: `flutter run -d <ios-simulator>`. App boota sem crash. Xcode console mostra `Configuring the default app`. Login flow continua funcionando (regressão).
- [ ] 8.5 Confirmar via grep que `Firebase.initializeApp` aparece **apenas** em `firebase_client.dart` — nunca em `main.dart` direto.
- [ ] 8.6 Confirmar via grep que nenhum arquivo fora de `lib/src/infrastructure/clients/firebase/` importa `package:firebase_core/firebase_core.dart`.

---

## Parte 2 — Crashlytics

Ordem fixa: pubspec → wrapper → refactor do `LoggerClient` → providers → main.dart → plugin Gradle Crashlytics → verificação + smoke release.

### 1. pubspec

- [ ] 1.1 `flutter pub add firebase_crashlytics`. Confirmar que `pubspec.yaml` ganhou a entrada.
- [ ] 1.2 `flutter pub get` sem warnings.

### 2. Wrapper `CrashClient`

- [ ] 2.1 Criar pasta `lib/src/infrastructure/clients/crash/`.
- [ ] 2.2 Criar `lib/src/infrastructure/clients/crash/crash_client.dart`:
  ```dart
  import 'package:flutter/foundation.dart';
  import 'package:firebase_crashlytics/firebase_crashlytics.dart';

  abstract interface class ICrashClient {
    Future<void> recordError({
      required Object error,
      required StackTrace stackTrace,
      bool fatal = false,
    });

    Future<void> recordFlutterError(FlutterErrorDetails details);
  }

  final class CrashClient implements ICrashClient {
    @override
    Future<void> recordError({
      required Object error,
      required StackTrace stackTrace,
      bool fatal = false,
    }) =>
        FirebaseCrashlytics.instance.recordError(error, stackTrace, fatal: fatal);

    @override
    Future<void> recordFlutterError(FlutterErrorDetails details) =>
        FirebaseCrashlytics.instance.recordFlutterError(details);
  }
  ```

### 3. Refactor `LoggerClient`

- [ ] 3.1 Atualizar `lib/src/infrastructure/clients/logger/logger_client.dart`:
  - Adicionar import `crash_client.dart`.
  - Adicionar campo `final ICrashClient _crashClient;` antes do `_logger` (ordenação CLAUDE.md).
  - Construtor: `LoggerClient({required ICrashClient crashClient}) : _crashClient = crashClient;` (substitui o construtor default sem args).
  - Atualizar `error()` e `critical()` para chamar `_crashClient.recordError(error: error, stackTrace: stackTrace, fatal: false)` quando `error != null && stackTrace != null`.
  - Não tocar em `debug()`, `verbose()`, `information()`, `warning()`.
- [ ] 3.2 Verificar que `ILoggerClient` (interface) **não muda** — só a impl.

### 4. Providers

- [ ] 4.1 Em `lib/src/main/providers/clients_provider.dart`:
  - Adicionar import `crash_client.dart`.
  - Adicionar `crashClientProvider` entre `firebaseClientProvider` e `loggerClientProvider`:
    ```dart
    @Riverpod(keepAlive: true)
    ICrashClient crashClient(Ref _) => CrashClient();
    ```
  - Atualizar `loggerClient` provider: trocar `Ref _` por `Ref ref` e injetar:
    ```dart
    @Riverpod(keepAlive: true)
    ILoggerClient loggerClient(Ref ref) =>
        LoggerClient(crashClient: ref.watch(crashClientProvider));
    ```
- [ ] 4.2 `dart run build_runner build --delete-conflicting-outputs`.
- [ ] 4.3 Verificar `clients_provider.g.dart` tem `crashClientProvider`.

### 5. `main.dart` — bridges de erro

- [ ] 5.1 Atualizar `lib/main.dart` adicionando, depois de `await container.read(firebaseClientProvider).initialize()`:
  ```dart
  final crashClient = container.read(crashClientProvider);

  FlutterError.onError = crashClient.recordFlutterError;
  PlatformDispatcher.instance.onError = (error, stack) {
    crashClient.recordError(error: error, stackTrace: stack, fatal: true);
    return true;
  };
  ```
- [ ] 5.2 Importar `dart:ui` (para `PlatformDispatcher`) se não estiver no arquivo.

### 6. Android — plugin Gradle Crashlytics

- [ ] 6.1 Em `android/settings.gradle.kts`, dentro do bloco `plugins`, abaixo da linha `id("com.google.gms.google-services") ...`, adicionar:
  ```kotlin
  id("com.google.firebase.crashlytics") version "3.x.x" apply false
  ```
  - Versão exata: olhar [release atual](https://firebase.google.com/docs/crashlytics/get-started?platform=android) no momento da implementação.
- [ ] 6.2 Em `android/app/build.gradle.kts`, dentro do bloco `plugins`, abaixo de `id("com.google.gms.google-services")`, adicionar:
  ```kotlin
  id("com.google.firebase.crashlytics")
  ```
- [ ] 6.3 Confirmar `flutter build apk --debug` completa sem erro.

### 7. iOS — verificar (nada manual)

- [ ] 7.1 Abrir `ios/Runner.xcworkspace` no Xcode, confirmar que o plugin `firebase_crashlytics` apareceu em Pods. Sem mudanças em `AppDelegate.swift`.
- [ ] 7.2 `flutter build ios --debug --no-codesign` completa sem erro.

### 8. Testes

- [ ] 8.1 `test/src/infrastructure/clients/logger/logger_client_test.dart` (se existir): atualizar para injetar `MockCrashClient` no construtor. Se não existir, **não** criar — sem cobertura nova (wrapper trivial).
- [ ] 8.2 Procurar testes que instanciam `LoggerClient()` direto (sem provider): `grep -rn 'LoggerClient(' test/`. Cada call-site precisa receber `crashClient: MockCrashClient()`.
- [ ] 8.3 Procurar testes que dependem de `loggerClientProvider`: usam override do Riverpod com mock — não devem precisar de mudança.

### 9. Verificação

- [ ] 9.1 `flutter analyze` — zero warnings.
- [ ] 9.2 `flutter test` — toda a suíte passa.
- [ ] 9.3 Confirmar via grep que `package:firebase_crashlytics/` é importado **apenas** em `crash_client.dart`.
- [ ] 9.4 Confirmar via grep que `FirebaseCrashlytics.instance` aparece **apenas** em `crash_client.dart`.
- [ ] 9.5 **Smoke release — Android**: build release `flutter run --release -d <android-device>`. Adicionar botão temporário em alguma screen disparando `FirebaseCrashlytics.instance.crash()`. Tap → app fecha. Reabrir → crash sobe.
- [ ] 9.6 **Smoke release — iOS**: idem em device real iOS (simulator não dispara o crash handler nativo).
- [ ] 9.7 Esperar 5-15 min e confirmar no Console (`console.firebase.google.com → Trocado → Crashlytics`) que o crash de teste aparece com stack trace e device info.
- [ ] 9.8 **Remover o botão de teste** antes de commitar. Confirmar via grep que `FirebaseCrashlytics.instance.crash()` não aparece em nenhum lugar de `lib/`.
