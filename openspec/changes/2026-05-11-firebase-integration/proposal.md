# Proposal — firebase-integration

## Why

O Trocado hoje não tem **observabilidade de produção**, **canal de notificação push** nem **gate de identidade** entre o app e a API. Três lacunas distintas com impactos diferentes:

- **Sem observabilidade**: crashes (Dart e nativos) somem no device. Hoje só descobrimos problema via report manual de usuário ou review na loja. `talker` já existe e loga localmente, mas o log morre quando o processo crasha ou o usuário fecha. Como o Trocado lida com dinheiro de **duas pessoas** (casal compartilhando orçamento), erros silenciosos têm potencial de "perdi minha conta", "saldo errado", "categoria gravou no parceiro" — risco alto de churn e de quebra de confiança no produto. `lib/src/infrastructure/clients/logger/logger_client.dart` é a fonte natural para fazer bridge.
- **Sem canal push**: a feature de orçamento (`lib/src/presentation/ui/budgets/`) é inerentemente temporal — alerta de fim de mês, ping quando o parceiro registra um gasto grande, lembrete de fechamento de ciclo. Sem FCM o app fica 100% reativo: só sabe das coisas quando o usuário abre. Concorrentes (Mobills, Organizze) lembram o usuário; o Trocado não.
- **Sem App Check**: a API Django (`AppConfig.url`) aceita request de qualquer cliente que tenha JWT válido. Não há sinal "esta request veio do app oficial". Para um app financeiro isso abre flanco para abuso: scripts criando contas em massa, força bruta em sign-in, scraping de endpoints, clones rebrandeados consumindo a mesma API.

A feature completa de **Integração com Firebase** será entregue de forma **incremental** — esta change vai ser editada conforme as próximas partes forem implementadas. A primeira parte (esta proposal) entrega apenas o **setup base do Firebase no projeto**: criação do projeto no Console (passo manual), inclusão de `firebase_core`, geração de `firebase_options.dart` via FlutterFire CLI, wrapper `FirebaseClient`, plugin Gradle no Android, registro do plist no iOS e inicialização explícita em `main.dart` antes de `runApp`. Nenhum SDK funcional (Crashlytics, FCM, App Check) é ligado ainda — só a base.

Partes futuras (a serem adicionadas a esta mesma change):

- **Parte 2** — Crashlytics: SDK + wrapper `CrashClient` + bridge `FlutterError.onError` / `PlatformDispatcher.instance.onError` / observer Talker → Crashlytics. Crashes nativos automáticos; exceções Dart não-fatais via bridge. Sem PII (sem `setUserIdentifier`) nesta parte.
- **Parte 3** — Cloud Messaging mínimo: SDK + wrapper `MessagingClient` + chamada `getToken()` pós-autenticação, com o token apenas loggado via `ILoggerClient.info`. **Sem permissão pedida**, **sem registro no backend**, **sem handling de payload**. Apenas estabelece o pipe — o token vai pro backend numa change futura quando o endpoint existir.
- **Parte 4** — App Check: SDK + wrapper `AppCheckClient` + providers Play Integrity (Android) e App Attest (iOS) em release, Debug Provider em debug. Token injetado em header `X-Firebase-AppCheck` via novo interceptor Dio. Backend ignora o header por enquanto — quando o Django ligar a validação, o app não muda.

## What

### Pré-requisito manual (executado pelo usuário antes da implementação começar)

O Firebase Console é operação interativa que exige login na conta Google do dono do projeto. Eu não consigo automatizar — **você precisa**, antes de aprovar a implementação:

1. Ir em [console.firebase.google.com](https://console.firebase.google.com), criar projeto **"Trocado"** (plano Spark — free tier cobre tudo nesta change inteira).
2. Habilitar Google Analytics opcional (recomendado — é grátis e desbloqueia propriedades extras do Crashlytics; não usamos a feature de Analytics ainda).
3. Adicionar **app Android**: package name `br.com.bed.trocado` (confere com `android/app/build.gradle.kts:31`), app nickname `Trocado Android`, SHA-1 não obrigatório para a Parte 1 (será necessário para a Parte 4 em release).
4. Adicionar **app iOS**: bundle ID `br.com.bed.trocado` (confere com `ios/Runner.xcodeproj/project.pbxproj`), app nickname `Trocado iOS`, App Store ID em branco.
5. Local, no root do projeto: instalar o CLI uma vez com `dart pub global activate flutterfire_cli` (skip se já tiver) e rodar `flutterfire configure --project=trocado-<projectId>`. O CLI:
   - baixa `google-services.json` para `android/app/`,
   - baixa `GoogleService-Info.plist` e registra no Xcode project,
   - gera `lib/firebase_options.dart` com a constante `DefaultFirebaseOptions.currentPlatform`.

A spec assume que os passos acima estão prontos quando a implementação começa. Se algum sair errado (ex: bundle ID divergente, plist não registrado no Xcode), a implementação para e me avisa antes de continuar.

### Parte 1 — Setup base do Firebase (esta entrega)

#### Nova dependência

`pubspec.yaml`, seção `dependencies`, junto com as demais (entre `flutter_secure_storage` e `talker`, ou no fim do bloco — ordem alfabética não é seguida no pubspec atual):

```yaml
firebase_core: ^4.x.x  # versão exata pinada via `flutter pub add firebase_core` no momento da implementação
```

Nenhuma dep nova em `dev_dependencies`.

#### Arquivo gerado pelo FlutterFire CLI

- `lib/firebase_options.dart` — gerado pelo `flutterfire configure`, commitado. Contém a constante `DefaultFirebaseOptions.currentPlatform` com as chaves de API por plataforma. **Não editar à mão**.

#### Wrapper `IFirebaseClient` / `FirebaseClient`

- `lib/src/infrastructure/clients/firebase/firebase_client.dart` — interface + implementação no mesmo arquivo, espelhando o padrão de `logger_client.dart` (interface `I<Nome>Client` + classe `final class <Nome>Client`):

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

  Sem construtor (não há dependência). Sem campos. Single-method interface — o mínimo para isolar o SDK.

#### Provider Riverpod

Em `lib/src/main/providers/clients_provider.dart`, junto com `loggerClient` / `httpClient` / `dio`:

```dart
@Riverpod(keepAlive: true)
IFirebaseClient firebaseClient(Ref _) => FirebaseClient();
```

Roda `dart run build_runner build --delete-conflicting-outputs` para regenerar `clients_provider.g.dart`.

#### Inicialização explícita em `main.dart`

`Firebase.initializeApp` é async e **precisa** rodar antes de `runApp` (Crashlytics da Parte 2 e App Check da Parte 4 dependem do core inicializado para registrar handlers já na boot). Refatorar `lib/main.dart`:

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final container = ProviderContainer(observers: [stateObserver]);
  await container.read(firebaseClientProvider).initialize();

  runApp(UncontrolledProviderScope(container: container, child: AppWidget()));
}
```

Trocamos `ProviderScope` por `ProviderContainer` + `UncontrolledProviderScope` para conseguir ler o provider antes de `runApp`. O `observers: [stateObserver]` continua aplicado (mesmo comportamento de logging Riverpod via `talker_riverpod_logger`). Decisão completa no `design.md`.

#### Configuração nativa

**Android** — duas mudanças:

- `android/build.gradle.kts` (root do módulo Android): adicionar ao bloco `plugins`:
  ```kotlin
  id("com.google.gms.google-services") version "4.4.x" apply false
  ```
- `android/app/build.gradle.kts`: adicionar ao bloco `plugins` (depois de `dev.flutter.flutter-gradle-plugin`):
  ```kotlin
  id("com.google.gms.google-services")
  ```

**iOS** — `flutterfire configure` já registra `GoogleService-Info.plist` automaticamente no Xcode project (referência no `project.pbxproj`). **Nenhuma mudança manual** em `AppDelegate.swift` nesta parte. A Parte 4 vai adicionar `FirebaseAppCheck.appCheck().setAppCheckProviderFactory(...)` no `application(_:didFinishLaunchingWithOptions:)` antes de `FirebaseApp.configure()`, mas isso é Parte 4.

#### Artefatos commitados (decisão)

`google-services.json` (Android) e `GoogleService-Info.plist` (iOS) **são commitados** ao repo. Justificativa: as "API keys" dentro deles não são secrets — documentação oficial do Firebase confirma que esses identificadores são públicos por design; a segurança vem das Security Rules dos services consumidos + App Check (Parte 4). Trade-off completo no `design.md`.

### Parte 2 — Crashlytics (esboço, escopo final virá quando a Parte 1 estiver mergeada)

- Dep `firebase_crashlytics`.
- `lib/src/infrastructure/clients/crash/crash_client.dart` — `ICrashClient` com `recordError({required Object error, required StackTrace stackTrace, bool fatal})` e `recordFlutterError(FlutterErrorDetails details)`. Impl delega para `FirebaseCrashlytics.instance`.
- Bridge em `main.dart` (depois do `firebase_core.initialize()`):
  ```dart
  FlutterError.onError = crashClient.recordFlutterError;
  PlatformDispatcher.instance.onError = (error, stack) {
    crashClient.recordError(error: error, stackTrace: stack, fatal: true);
    return true;
  };
  ```
- Bridge `talker` → Crashlytics: classe `CrashTalkerObserver implements TalkerObserver` que escuta `onError` / `onException` e chama `_crashClient.recordError(..., fatal: false)`. Anexado ao `talker` em `LoggerClient`.
- Provider `crashClientProvider` em `clients_provider.dart`.
- **Sem `setUserIdentifier`** nesta parte — crashes ficam anônimos. Identificação por usuário é decisão de privacidade que precisa ser feita à parte (opt-in em Settings, LGPD compliance) — fica para change separada.

### Parte 3 — Cloud Messaging mínimo (esboço)

- Dep `firebase_messaging`.
- `lib/src/infrastructure/clients/messaging/messaging_client.dart` — `IMessagingClient` com `Future<String?> getToken()`. Impl delega para `FirebaseMessaging.instance.getToken()`.
- Chamada do `getToken()` na ramificação Right de `SignInNotifier._submit` e `SignUpNotifier._submit`, com o token loggado via `ILoggerClient.information('FCM token: $token')`. **Nenhuma chamada de API** — o backend Django ainda não tem endpoint para receber FCM token.
- **Sem permissão pedida**. Em iOS, sem permissão não há push visível, mas o token é gerado mesmo assim (necessário para futuras notificações silenciosas e para o backend pré-registrar o device quando ele for ligado). Pedido formal de permissão fica para change futura, quando houver notificação real para exibir.
- Provider `messagingClientProvider` em `clients_provider.dart`.

### Parte 4 — App Check (esboço)

- Dep `firebase_app_check`.
- `lib/src/infrastructure/clients/app_check/app_check_client.dart` — `IAppCheckClient` com `Future<void> activate()` e `Future<String?> getToken()`. Impl delega para `FirebaseAppCheck.instance`.
- Providers configurados em `activate()` por modo de build (`kDebugMode`):
  - **Debug** (`kDebugMode == true`): `androidProvider: AndroidProvider.debug`, `appleProvider: AppleProvider.debug`. O Debug Provider imprime um UUID no console que o usuário precisa registrar manualmente no Firebase Console (em **App Check → Apps → Manage debug tokens**) para que o token seja aceito.
  - **Release**: `androidProvider: AndroidProvider.playIntegrity`, `appleProvider: AppleProvider.appAttest`. Play Integrity é o sucessor do SafetyNet (deprecated em 2024); App Attest exige iOS 14+ (já garantido pelo Flutter SDK `^3.10.0`).
- Inicialização em `main.dart` **depois** de `Firebase.initializeApp` e **antes** de `runApp`.
- Novo interceptor Dio `lib/src/infrastructure/clients/http/interceptors/app_check_interceptor.dart` — `AppCheckInterceptor extends Interceptor` que injeta header `X-Firebase-AppCheck: <token>` em `onRequest`. Token obtido via `IAppCheckClient.getToken()`. Se o token vier `null` (provider sem rede, debug provider não autorizado), a request segue sem o header — o backend decide aceitar ou rejeitar.
- `lib/src/infrastructure/clients/http/factories/dio_factory.dart` adiciona o `AppCheckInterceptor` **antes** do `AuthenticationInterceptor` (ordem: App Check protege também endpoints públicos como sign-in/sign-up, então vem primeiro).
- Sem validação no backend ainda — o header chega no Django mas é ignorado. Quando o backend ligar a validação, o app **não muda**. Trade-off aceito no `design.md`.

## Scope

### Em escopo (Parte 1 — atual)

- Setup do Firebase Console feito **manualmente pelo usuário** antes da implementação (documentado no proposal, não codificado).
- Dependência `firebase_core` adicionada ao `pubspec.yaml`.
- `lib/firebase_options.dart` gerado via `flutterfire configure` e commitado.
- `lib/src/infrastructure/clients/firebase/firebase_client.dart` com `IFirebaseClient` + `FirebaseClient` (single-method interface `initialize()`).
- `firebaseClientProvider` em `lib/src/main/providers/clients_provider.dart` + regeneração de `.g.dart` via build_runner.
- `lib/main.dart` refatorado: `ProviderContainer` + `UncontrolledProviderScope` em vez de `ProviderScope`; `await container.read(firebaseClientProvider).initialize()` antes de `runApp`.
- Plugin Gradle `com.google.gms.google-services` aplicado em Android (declaração no root `android/build.gradle.kts` + `apply` em `android/app/build.gradle.kts`).
- `google-services.json` em `android/app/` e `GoogleService-Info.plist` em `ios/Runner/` **commitados** ao repo.
- `flutter analyze` zero warnings; `flutter test` passa toda a suíte (nenhum teste novo nesta parte — `FirebaseClient` é delegate puro sem lógica testável).
- **Smoke manual — Android**: `flutter run` em emulador. Boot completa sem erro. Logcat mostra `FirebaseApp initialization successful`.
- **Smoke manual — iOS**: `flutter run` em simulador. Boot completa sem erro. Xcode console mostra `Configuring the default app`.

### Fora de escopo (Parte 1 — virá em partes futuras)

- **Crashlytics** (Parte 2) — SDK, wrapper `CrashClient`, bridges `FlutterError.onError` / `PlatformDispatcher.onError` / `TalkerObserver`.
- **FCM** (Parte 3) — SDK, wrapper `MessagingClient`, chamada de `getToken()` pós-auth, log via talker. **Sem permissão**, **sem backend**, **sem handling**.
- **App Check** (Parte 4) — SDK, wrapper `AppCheckClient`, providers Play Integrity / App Attest / Debug, interceptor Dio com header `X-Firebase-AppCheck`.
- **Backend Django** — nenhuma mudança em backend em **nenhuma** das 4 partes desta change. Endpoint para receber FCM token e validação de App Check ficam fora — viram changes do lado do backend quando agendadas.
- **Firebase Analytics** — fora do escopo da change inteira. Decidir separadamente (LGPD precisa ser revisada).
- **Firebase Performance Monitoring** — fora do escopo.
- **Firebase Remote Config** — fora do escopo.
- **Build flavors / múltiplos projetos Firebase** (dev/staging/prod) — fica com **um projeto Firebase só** por enquanto. Quando precisar de separação por ambiente, criar change dedicada.
- **Permissão de notificação iOS / Android 13+** — fica para a change que introduzir notificação real (não é a Parte 3).
- **Configuração de SHA-1 release no Firebase Console** — só será necessária na Parte 4 quando Play Integrity for ligado em release.
- **Notification icon, notification channel Android, override em `AppDelegate.swift`** — todos fora; serão tratados na change que ligar handling de notificação real.
- **Testes unitários do `FirebaseClient`** — wrapper trivial sem lógica testável (chama `Firebase.initializeApp`, retorna `void`); cobertura via smoke manual nos dois OSes.
- **Documentação no `CLAUDE.md`** sobre Firebase — fica para quando a Parte 4 estiver concluída e a integração inteira estabilizar; só então faz sentido um parágrafo no contrato.
