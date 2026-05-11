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

### Parte 2 — Crashlytics

A Parte 1 entregou Firebase Core inicializado. Crashes nativos (NDK / iOS native) **ainda não são reportados** — Crashlytics SDK precisa ser ligado pra isso. Erros Dart não-fatais (uncaught Future, FlutterError, exceções loggadas via `talker`) também passam batido. Esta parte fecha as três pontas:

1. **Crashes nativos** — automaticamente capturados pelo `firebase_crashlytics` plugin assim que o SDK é inicializado. Zero código Flutter envolvido.
2. **Erros Dart uncaught** — `FlutterError.onError` (erros do framework / build phase) e `PlatformDispatcher.instance.onError` (erros assíncronos não-tratados, isolates) redirecionados pro `CrashClient` em `main.dart`.
3. **Erros Dart explicitamente loggados** — `LoggerClient.error()` e `LoggerClient.critical()` (já recebem `Object? error` + `StackTrace? stackTrace` como parâmetros opcionais que hoje são ignorados) passam a chamar `_crashClient.recordError(..., fatal: false)` quando os dois parâmetros são não-nulos.

#### Nova dependência

`pubspec.yaml`, seção `dependencies`:

```yaml
firebase_crashlytics: ^5.x.x  # versão exata pinada via `flutter pub add firebase_crashlytics`
```

#### Wrapper `ICrashClient` / `CrashClient`

- `lib/src/infrastructure/clients/crash/crash_client.dart` — interface + impl no mesmo arquivo, padrão de `FirebaseClient`:

  ```dart
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

  Delegate puro — toda a lógica (rate limiting, batching, retry offline) é responsabilidade do SDK do Crashlytics.

#### `LoggerClient` ganha dependência em `ICrashClient`

- Construtor de `LoggerClient` passa a aceitar `required ICrashClient crashClient`. Campo `_crashClient` antes do construtor (ordenação CLAUDE.md).
- Os métodos `error()` e `critical()` (e **somente** esses dois) ficam:
  ```dart
  @override
  void error(String message, {Object? error, StackTrace? stackTrace}) {
    _logger.error(message);
    if (error != null && stackTrace != null) {
      _crashClient.recordError(error: error, stackTrace: stackTrace, fatal: false);
    }
  }
  ```
- Métodos `debug()`, `verbose()`, `information()`, `warning()` **não** reportam — semanticamente são "estados interessantes", não falhas.
- `_crashClient.recordError` é fire-and-forget (não-bloqueante) — o método `error()` continua síncrono pra preservar a interface `ILoggerClient`.

#### Bridge em `main.dart`

Depois de `firebaseClient.initialize()`, antes de `runApp`:

```dart
final crashClient = container.read(crashClientProvider);

FlutterError.onError = crashClient.recordFlutterError;
PlatformDispatcher.instance.onError = (error, stack) {
  crashClient.recordError(error: error, stackTrace: stack, fatal: true);
  return true;
};
```

`fatal: true` no `PlatformDispatcher` porque erros assíncronos não-tratados são por definição falhas catastróficas (futures que ninguém pegou). `FlutterError.onError` usa o método `recordFlutterError` que já é marcado como `fatal: false` pelo SDK (build phase errors raramente travam o app).

#### Providers em `clients_provider.dart`

A ordem dos providers no arquivo passa a ser:

```dart
@Riverpod(keepAlive: true)
IFirebaseClient firebaseClient(Ref _) => FirebaseClient();

@Riverpod(keepAlive: true)
ICrashClient crashClient(Ref _) => CrashClient();

@Riverpod(keepAlive: true)
ILoggerClient loggerClient(Ref ref) =>
    LoggerClient(crashClient: ref.watch(crashClientProvider));

@Riverpod(keepAlive: true)
IHttpClient httpClient(Ref ref) => HttpClient(dio: ref.watch(dioProvider));
```

`loggerClient` deixa de ser `Ref _` (ignorado) e passa a usar `Ref ref` pra ler `crashClientProvider`. Build_runner regenera o `.g.dart`.

#### Decisões de privacidade

- **Sem `setUserIdentifier`** — crashes ficam anônimos (Crashlytics não recebe `user.id`, `email`, `name` nem nada que identifique a pessoa). Identificação por usuário precisa de opt-in explícito em Settings (LGPD); fica para change dedicada.
- **Sem `setCustomKey`** com campos do app (saldo, número de orçamentos, etc.) — qualquer dado financeiro é PII implícita.
- **Crashlytics ligado em debug também** — coleta acontece nos dois modos. Isso permite verificar via smoke que o pipeline funciona durante desenvolvimento. Crashes em debug aparecem no Console misturados com release; aceitável porque (a) volume de debug é baixo, (b) Console permite filtrar por versão da build se necessário.

#### Smoke de verificação

Diferente da Parte 1 (que só verifica boot OK), Parte 2 exige verificar que o crash chega no Console:

1. Adicionar **temporariamente** um botão em alguma screen (ex: Home) que chama `FirebaseCrashlytics.instance.crash()` no `onTap`. **Não commitar esse botão.**
2. Rodar `flutter run --release` em device real (debug builds não disparam o crash handler do mesmo jeito).
3. Tocar no botão — app fecha.
4. Reabrir o app — Crashlytics envia o report acumulado.
5. Aguardar 5-15 min e checar `console.firebase.google.com → Crashlytics → Issues` no projeto Trocado.
6. Crash deve aparecer com stack trace deobfuscado e info de device.
7. Remover o botão de teste antes do commit.

#### Configuração nativa adicional

**Android** — necessário aplicar o plugin Gradle do Crashlytics para upload automático de mapping files de R8/ProGuard em release:

- `android/settings.gradle.kts`, bloco `plugins`, adicionar abaixo do `google-services`:
  ```kotlin
  id("com.google.firebase.crashlytics") version "3.x.x" apply false
  ```
- `android/app/build.gradle.kts`, bloco `plugins`, adicionar abaixo do `google-services`:
  ```kotlin
  id("com.google.firebase.crashlytics")
  ```

**iOS** — nenhuma mudança em `AppDelegate.swift` ou `project.pbxproj`. O plugin `firebase_crashlytics` injeta o run-script de upload de dSYM automaticamente via FlutterFire. Sem ação manual.

### Parte 3 — Cloud Messaging mínimo

A Parte 2 entregou Crashlytics. O app captura crashes mas **ainda não tem canal push** — não consegue lembrar o usuário de nada, receber alerta de gasto do parceiro, ou notificar fim de ciclo de orçamento. Esta parte estabelece o **pipe mínimo** do FCM:

1. SDK do `firebase_messaging` inicializado (automático ao adicionar a dep + plugin GoogleService já configurado na Parte 1).
2. Token FCM do device obtido via `IMessagingClient.getToken()` no boot.
3. Token logado via `ILoggerClient.information(...)` — útil para (a) confirmar visualmente que o pipe funciona durante dev, (b) testar push manualmente via Firebase Console (campo "Adicionar mensagem de teste" aceita um token).

**Fora de escopo desta parte**: pedido de permissão de notificação, registro do token no backend, handling de payload (foreground/background/terminated), tap → deep link, local notifications, channels Android, override em `AppDelegate.swift`. Cada uma vira uma change própria quando houver caso de uso real.

#### Nova dependência

`pubspec.yaml`, seção `dependencies`:

```yaml
firebase_messaging: ^16.x.x  # versão exata pinada via `flutter pub add firebase_messaging`
```

#### Wrapper `IMessagingClient` / `MessagingClient`

- `lib/src/infrastructure/clients/messaging/messaging_client.dart`:

  ```dart
  import 'package:firebase_core/firebase_core.dart';
  import 'package:firebase_messaging/firebase_messaging.dart';

  abstract interface class IMessagingClient {
    Future<String?> getToken();
  }

  final class MessagingClient implements IMessagingClient {
    @override
    Future<String?> getToken() async {
      try {
        return await FirebaseMessaging.instance.getToken();
      } on FirebaseException catch (exception) {
        if (exception.code == 'apns-token-not-set') return null;
        rethrow;
      }
    }
  }
  ```

  Single-method interface. A impl trata especificamente o caso `apns-token-not-set` (iOS sem Push capability — comportamento conhecido e esperado nesta parte) retornando `null`, para que o caller logue `"(null)"` em vez de tratar como falha. Qualquer outro `FirebaseException` é rethrow — sobe pro try-catch do caller e vai pro Crashlytics como erro real.

#### Provider Riverpod

Em `clients_provider.dart`, entre `crashClient` e `loggerClient`:

```dart
@Riverpod(keepAlive: true)
IMessagingClient messagingClient(Ref _) => MessagingClient();
```

Build_runner regenera o `.g.dart`.

#### Boot-time logging em `main.dart`

O token é obtido no boot via `ProviderContainer.read`, **não** dentro de notifiers de auth. Razão: notifiers vivem em `presentation/`, que pelo CLAUDE.md depende só de `domain/` — instanciar provider de `messagingClient` (infrastructure) dentro de notifier quebraria a regra. `main.dart` (composition root) é o único lugar autorizado a tocar infrastructure direto. O esboço inicial mencionava "ramificação Right de SignInNotifier" — descartado por essa razão.

Após as bridges de Crashlytics (Parte 2), antes de `runApp`:

```dart
unawaited(_logFcmToken(container));

runApp(...);
```

E a função-helper, no mesmo arquivo:

```dart
Future<void> _logFcmToken(ProviderContainer container) async {
  final logger = container.read(loggerClientProvider);

  try {
    final token = await container.read(messagingClientProvider).getToken();
    logger.information('FCM token: ${token ?? '(null)'}');
  } catch (error, stackTrace) {
    logger.error('Failed to retrieve FCM token', error: error, stackTrace: stackTrace);
  }
}
```

`unawaited(...)` (`import 'dart:async'`) é o idioma canônico do Dart para "fire-and-forget" sem warning de linter. A obtenção do token não bloqueia o boot — splash não atrasa por causa do FCM. Erros de fetch caem no `logger.error()` que pelo bridge da Parte 2 já reporta no Crashlytics como não-fatal.

#### iOS — Push Notifications capability **não** adicionada nesta parte

Em iOS, `FirebaseMessaging.instance.getToken()` exige a capability **Push Notifications** ligada no Xcode (entitlement `aps-environment`). Sem isso, o SDK lança `FirebaseException(code: 'apns-token-not-set')` (não retorna null, contrariando o esboço inicial). O `MessagingClient` filtra esse código específico e devolve `null` para o caller — log final fica `"FCM token: (null)"`, sem stack trace no Crashlytics.

**Decisão**: não adicionar a capability na Parte 3. iOS vai logar `(null)` até a change futura que introduzir notificação real ligar a capability junto com o restante (request de permissão, handling de payload, `AppDelegate.swift` overrides, APNs auth key no Console).

Trade-off: o pipe iOS fica "meio-pronto" — token Android funciona, token iOS é `(null)`. Aceitável porque (a) o objetivo dessa parte é validar o SDK rodando e o pipe Android, não tokens iOS de produção; (b) ligar capability isolada sem o resto do handling de push significa shipar pro TestFlight um app com "Push" marcado nas Capabilities mas que não faz nada visível — confuso pra quem revisar.

#### Android — sem setup nativo adicional

`firebase_messaging` no Android usa Firebase Installations sob o capô para gerar o token. Nenhuma capability, nenhum manifest, nenhum channel necessário pra apenas obter o token. Permissão `POST_NOTIFICATIONS` (Android 13+) **não** é exigida para `getToken()` — só para exibir notificação.

#### Smoke de verificação

1. `flutter run -d <android-device>` — observar logcat / talker output. Deve aparecer: `FCM token: f8a3b...XYZ` (longo string ~150 chars).
2. `flutter run -d <ios-device>` — observar console. Deve aparecer: `FCM token: (null)` (sem capability; comportamento esperado).
3. **Teste manual de push (opcional)**: pegar o token Android logado, ir em [Console → Trocado → Messaging → Nova campanha → Notificação de teste](https://console.firebase.google.com), colar o token, enviar. Sem handler ainda, mas confirma que o pipe Console → device funciona.

### Parte 4 — App Check

A Parte 3 entregou FCM. As 3 pernas do Firebase (Crashlytics observabilidade, Messaging push, **App Check gate de identidade**) ainda têm a terceira em aberto. Esta parte fecha:

1. SDK `firebase_app_check` adicionado e ativado no boot **antes** de outros serviços Firebase (Crashlytics não exige, mas FCM `getToken()` chama Firebase Installations, que **é** App Check-protected).
2. Provider de attestation: **Play Integrity** (Android release), **App Attest** (iOS release), **Debug Provider** (kDebugMode em ambos).
3. Token App Check injetado em header `X-Firebase-AppCheck` em **toda** request HTTP via interceptor Dio.
4. Backend Django ignora o header por ora — Trocado fica pronto para quando o backend ligar a validação (change separada do lado backend).

#### Nova dependência

`pubspec.yaml`, seção `dependencies`:

```yaml
firebase_app_check: ^0.4.x.x  # versão exata pinada via `flutter pub add firebase_app_check`
```

#### Wrapper `IAppCheckClient` / `AppCheckClient`

A estratégia de providers (`debug` vs `playIntegrity` / `appAttest`) é **encapsulada dentro do wrapper** — `main.dart` apenas chama `activate()` sem decidir provider. Isso esconde os tipos `AndroidProvider` / `AppleProvider` do `firebase_app_check` no único arquivo que importa o SDK.

- `lib/src/infrastructure/clients/app_check/app_check_client.dart`:

  ```dart
  import 'package:flutter/foundation.dart';
  import 'package:firebase_app_check/firebase_app_check.dart';

  abstract interface class IAppCheckClient {
    Future<void> activate();
    Future<String?> getToken();
  }

  final class AppCheckClient implements IAppCheckClient {
    @override
    Future<void> activate() => FirebaseAppCheck.instance.activate(
      providerAndroid: kDebugMode
          ? AndroidDebugProvider()
          : AndroidPlayIntegrityProvider(),
      providerApple: kDebugMode
          ? AppleDebugProvider()
          : AppleAppAttestProvider(),
    );

    @override
    Future<String?> getToken() => FirebaseAppCheck.instance.getToken();
  }
  ```

  Em `firebase_app_check ^0.4.4`, os parâmetros `androidProvider` / `appleProvider` (que recebiam enums `AndroidProvider.debug`, etc.) foram deprecados em favor de `providerAndroid` / `providerApple`, que recebem instâncias de classes concretas (`AndroidDebugProvider()`, `AndroidPlayIntegrityProvider()`, `AppleDebugProvider()`, `AppleAppAttestProvider()`). O wrapper usa o API moderno.

#### Provider Riverpod

Em `clients_provider.dart`, entre `firebaseClient` e `messagingClient`:

```dart
@Riverpod(keepAlive: true)
IAppCheckClient appCheckClient(Ref _) => AppCheckClient();
```

E o `dio` provider passa a injetar o cliente no factory (próxima seção).

#### Novo interceptor Dio `AppCheckInterceptor`

- `lib/src/infrastructure/clients/http/interceptors/app_check_interceptor.dart`:

  ```dart
  import 'package:dio/dio.dart';

  import 'package:trocado/src/infrastructure/clients/app_check/app_check_client.dart';

  final class AppCheckInterceptor extends Interceptor {
    final IAppCheckClient _appCheckClient;

    AppCheckInterceptor({required IAppCheckClient appCheckClient})
        : _appCheckClient = appCheckClient;

    @override
    void onRequest(
      RequestOptions options,
      RequestInterceptorHandler handler,
    ) async {
      try {
        final token = await _appCheckClient.getToken();
        if (token != null) {
          options.headers['X-Firebase-AppCheck'] = token;
        }
      } catch (_) {}

      handler.next(options);
    }
  }
  ```

  O `catch (_)` vazio é intencional: falha de App Check (token expirou, rede off, debug provider não-autorizado ainda) **não** bloqueia a request — segue sem o header, e o backend decide aceitar ou rejeitar. Hoje aceita (validação não está ligada); amanhã pode rejeitar com 401 e o `AuthenticationInterceptor` cuida do refresh / logout.

#### `DioFactory.create()` — interceptor adicionado **antes** do AuthenticationInterceptor

`AppCheckInterceptor` precisa rodar antes do `AuthenticationInterceptor` por dois motivos:
1. Endpoints públicos (sign-in, sign-up) também são App Check-protegidos — o token deve ser injetado mesmo quando o usuário não está autenticado.
2. Convenção: middleware de identidade do device vem antes de middleware de identidade do usuário.

`DioFactory.create()` ganha novo parâmetro nomeado-obrigatório `IAppCheckClient appCheckClient` e adiciona o interceptor na frente da lista (`AppCheckInterceptor` antes de `AuthenticationInterceptor`).

#### `clients_provider.dart` — `dio` provider passa o `appCheckClient`

O provider `dio` recebe a nova dependência via `ref.watch`:

```dart
@Riverpod(keepAlive: true)
Dio dio(Ref ref) => DioFactory.create(
  baseUrl: AppConfig.url,
  dataSource: ref.watch(localTokenDataSourceProvider),
  appCheckClient: ref.watch(appCheckClientProvider),
  onUnauthenticated: () { ... },
);
```

#### `main.dart` — ativação antes de qualquer outro serviço Firebase

App Check **precisa** estar ativo antes de qualquer chamada que dispare Firebase Installations (que inclui FCM `getToken()`). Ordem final do `main()`:

```dart
WidgetsFlutterBinding.ensureInitialized();

final container = ProviderContainer(observers: [stateObserver]);

await container.read(firebaseClientProvider).initialize();
await container.read(appCheckClientProvider).activate();   // ← novo

final crashClient = container.read(crashClientProvider);
FlutterError.onError = crashClient.recordFlutterError;
PlatformDispatcher.instance.onError = (e, s) { ... };

unawaited(_logFcmToken(container));

runApp(...);
```

#### Debug Provider — fluxo de registro de token

Em debug, o SDK imprime no log algo como:

```
Enter this debug secret into the allow list in the Firebase Console for your project: 12345678-abcd-...
```

O usuário precisa:
1. Copiar o UUID do log.
2. Ir em `console.firebase.google.com → Trocado → App Check → Apps → (Android ou iOS) → ⋮ → Manage debug tokens`.
3. Adicionar o token com um nome reconhecível (ex: "Gabriel iPhone debug").

Sem esse registro, o backend Firebase rejeita os tokens emitidos pelo Debug Provider. Como nesta parte **nenhum serviço backend valida**, o registro é apenas pra evitar warnings — não bloqueia smoke da Parte 4.

#### iOS App Attest entitlement — **não** adicionado nesta parte

Para release em iOS com `AppleProvider.appAttest`, o `Runner.entitlements` precisa do entitlement `com.apple.developer.devicecheck.appattest-environment` (valor `development` ou `production`), **e** o provisioning profile precisa incluir a capability "App Attest" no Apple Developer Portal.

**Decisão**: não adicionar o entitlement nesta parte. iOS em debug usa Debug Provider (sem exigência). Release com App Attest fica para a primeira release que efetivamente fizer App Check enforcement — aí o entitlement, o provisioning profile e a APNs auth key viram pacote junto.

#### SHA-256 release no Console (Android) — fora de escopo

Play Integrity em release exige o SHA-256 do keystore de release cadastrado no Console (`App Check → Apps → Android → Manage signing certificates`). Como Parte 4 entrega o pipe e a Debug Provider já cobre dev, o cadastro do SHA-256 release fica para quando o time efetivamente fizer o primeiro release com App Check ligado no backend.

#### Smoke de verificação

1. `flutter run -d <android-emulator>` — boot deve completar; log do Talker deve mostrar a linha `Enter this debug secret into the allow list...` com um UUID. Login flow continua funcionando (App Check não bloqueia request porque backend não valida).
2. `flutter run -d <ios-simulator>` — idem, UUID iOS impresso no console.
3. **Inspeção de header (opcional)**: ligar `TalkerDioLogger` com `printRequestHeaders: true` temporariamente, refazer uma request qualquer, confirmar que o header `X-Firebase-AppCheck: <token>` aparece. Reverter o `printRequestHeaders: true` após confirmar.
4. (opcional, mas recomendado) registrar os 2 UUIDs no Firebase Console para evitar warnings de "tokens rejeitados" em logs futuros.

## Scope

### Em escopo (Parte 4 — atual)

- Dependência `firebase_app_check` adicionada ao `pubspec.yaml`.
- `lib/src/infrastructure/clients/app_check/app_check_client.dart` com `IAppCheckClient` (2 métodos: `activate()` + `getToken()`) + `AppCheckClient`. A impl encapsula a estratégia de providers via `kDebugMode` — debug usa `AndroidProvider.debug` / `AppleProvider.debug`, release usa `AndroidProvider.playIntegrity` / `AppleProvider.appAttest`.
- `appCheckClientProvider` adicionado em `clients_provider.dart` entre `firebaseClient` e `messagingClient`.
- `lib/src/infrastructure/clients/http/interceptors/app_check_interceptor.dart` com `AppCheckInterceptor` que injeta header `X-Firebase-AppCheck` em `onRequest` via `IAppCheckClient.getToken()`. Token nulo ou exception → request segue sem header (try-catch swallow).
- `DioFactory.create()` ganha parâmetro nomeado-obrigatório `IAppCheckClient appCheckClient` e adiciona `AppCheckInterceptor` antes de `AuthenticationInterceptor` na lista de interceptors.
- `dio` provider em `clients_provider.dart` passa `appCheckClient: ref.watch(appCheckClientProvider)` para o factory.
- `lib/main.dart` ganha `await container.read(appCheckClientProvider).activate();` entre `firebaseClient.initialize()` e as bridges de Crashlytics — App Check precisa estar ativo antes do FCM `getToken()` da Parte 3.
- Build_runner regenera `clients_provider.g.dart`.
- Teste novo `test/src/infrastructure/clients/http/interceptors/app_check_interceptor_test.dart` cobrindo: token retornado → header presente; token null → sem header; `getToken` lança → sem header. Mock em `IAppCheckClient`.
- `MockAppCheckClient extends Mock implements IAppCheckClient` adicionado em `test/mocks/mocks.dart`.
- `flutter analyze` zero warnings; `flutter test` passa toda a suíte.
- **Smoke Android**: UUID de debug impresso no log na boot. **Smoke iOS**: idem. **Smoke header (opcional)**: ativando `printRequestHeaders` temporário no `TalkerDioLogger`, confirmar que `X-Firebase-AppCheck` aparece nos requests.

### Fora de escopo (Parte 4 — virá em partes futuras)

- **Validação no backend Django** — o header chega mas não é validado. Backend ligar validação é change separada (não esta).
- **iOS App Attest entitlement** (`com.apple.developer.devicecheck.appattest-environment`) — fica para a primeira release que efetivamente exigir App Attest em iOS.
- **iOS provisioning profile com capability "App Attest"** — junto com o entitlement acima.
- **SHA-256 release Android cadastrado no Console** (necessário pra Play Integrity em release) — quando primeiro release com App Check enforcement chegar.
- **APNs auth key no Firebase Console** — fora; é problema da change de push real (não desta).
- **Registro dos UUIDs de debug no Console** — passo manual recomendado mas não bloqueia smoke; cada dev registra o próprio device.
- **Token refresh proativo** — `FirebaseAppCheck.instance.setTokenAutoRefreshEnabled(true)` é o default; não precisamos ativar nada. Stream `onTokenChange` fica fora — não há use case ainda.
- **Header em endpoints que não vão pra `AppConfig.url`** — `AppCheckInterceptor` está anexado a um único `Dio` instance. Se o app criar outro client futuramente, ele não terá o header automaticamente. Aceitável; revisitar quando o cenário aparecer.
- **Testes do `AppCheckClient` wrapper** — delegate puro (mesmo padrão de `CrashClient` / `MessagingClient`), sem teste.
- **`enforce` em outros serviços Firebase** (Firestore, Storage, Cloud Functions) — não usamos esses serviços.

### Em escopo (Parte 3 — atual)

- Dependência `firebase_messaging` adicionada ao `pubspec.yaml`.
- `lib/src/infrastructure/clients/messaging/messaging_client.dart` com `IMessagingClient` (single-method `getToken()`) + `MessagingClient` (delegate puro pra `FirebaseMessaging.instance.getToken()`).
- `messagingClientProvider` adicionado em `clients_provider.dart` entre `crashClientProvider` e `loggerClientProvider`. Build_runner regenera `.g.dart`.
- `lib/main.dart` ganha:
  - `import 'dart:async'` (para `unawaited`).
  - Função privada `_logFcmToken(ProviderContainer container)` que faz `getToken()` num try-catch, logando sucesso via `logger.information('FCM token: $token')` e falha via `logger.error(..., error: e, stackTrace: s)`.
  - `unawaited(_logFcmToken(container));` antes do `runApp`.
- `flutter analyze` zero warnings; `flutter test` passa toda a suíte.
- **Smoke Android**: token impresso no log. **Smoke iOS**: `(null)` esperado (sem Push capability nesta parte).

### Fora de escopo (Parte 3 — virá em partes futuras)

- **iOS Push Notifications capability** (`aps-environment` entitlement) — fica para change que introduzir notificação real.
- **Pedido de permissão de notificação** (iOS `requestPermission`, Android 13+ `POST_NOTIFICATIONS`) — fica pra mesma change futura.
- **Endpoint backend** `POST /api/v1/me/fcm-token` — backend Django não tem ainda; quando existir, mudar `_logFcmToken` para `_registerFcmToken` chamando `IUserRepository.registerFcmToken(...)`. **Não é esta change**.
- **Handling de payload**: `FirebaseMessaging.onMessage` (foreground), `FirebaseMessaging.onBackgroundMessage` (background isolate), `FirebaseMessaging.onMessageOpenedApp` (tap quando app suspenso/morto) — fora.
- **Local notifications** (exibir notif quando app em foreground via `flutter_local_notifications`) — fora.
- **Notification icon / notification channel Android / sound config** — fora.
- **Override `AppDelegate.swift`** (`UNUserNotificationCenter.current().delegate`, swizzling config, etc.) — fora.
- **Deep link routing a partir de tap em notification** — fora.
- **APNs auth key no Console Firebase** (necessário pra Apple aceitar push em produção) — fora; quando capability for ligada, configurar.
- **`FirebaseMessaging.instance.onTokenRefresh`** stream — fora; será relevante quando token for enviado pro backend.
- **Topics** (subscribe/unsubscribe a `FirebaseMessaging.instance.subscribeToTopic`) — fora.
- **Testes unitários do `MessagingClient`** — wrapper trivial (decisão #16 aplicada), sem cobertura nova.

### Em escopo (Parte 2 — atual)

- Dependência `firebase_crashlytics` adicionada ao `pubspec.yaml`.
- `lib/src/infrastructure/clients/crash/crash_client.dart` com `ICrashClient` + `CrashClient` (interface de 2 métodos: `recordError({error, stackTrace, fatal})` + `recordFlutterError(details)`).
- `LoggerClient` refatorado: ganha `final ICrashClient _crashClient;` antes do construtor; construtor passa a aceitar `required ICrashClient crashClient`; métodos `error()` e `critical()` chamam `_crashClient.recordError(..., fatal: false)` quando `error` e `stackTrace` são ambos não-nulos.
- `crashClientProvider` adicionado em `clients_provider.dart` entre `firebaseClientProvider` e `loggerClientProvider`. `loggerClientProvider` deixa de ser `Ref _` e passa a injetar `crashClient` via `ref.watch`.
- Build_runner regenera `clients_provider.g.dart`.
- `lib/main.dart` ganha, depois de `await container.read(firebaseClientProvider).initialize()`:
  ```dart
  final crashClient = container.read(crashClientProvider);
  FlutterError.onError = crashClient.recordFlutterError;
  PlatformDispatcher.instance.onError = (error, stack) {
    crashClient.recordError(error: error, stackTrace: stack, fatal: true);
    return true;
  };
  ```
- `android/settings.gradle.kts` ganha `id("com.google.firebase.crashlytics") version "3.x.x" apply false`.
- `android/app/build.gradle.kts` ganha `id("com.google.firebase.crashlytics")`.
- Testes do `LoggerClient` (se existirem) atualizados para injetar `MockCrashClient` no construtor.
- `flutter analyze` zero warnings; `flutter test` passa toda a suíte.
- **Smoke manual — Android e iOS em release**: botão temporário disparando `FirebaseCrashlytics.instance.crash()`; reabrir app; crash aparece em `console.firebase.google.com → Crashlytics → Issues` em 5-15 min.

### Fora de escopo (Parte 2 — virá em partes futuras)

- **`setUserIdentifier`** — crashes ficam anônimos. Identificação por usuário precisa de opt-in em Settings + revisão LGPD; change dedicada.
- **`setCustomKey`** com saldo/orçamento/qualquer dado financeiro — PII implícita.
- **Análise / triagem de crashes** — Console do Firebase é o destino; alertas Slack/email ficam para change futura.
- **Filtros por versão de build, regiões, devices** — configuração no próprio Console quando começar a ter volume real.
- **Mapping files de release Android** — o plugin Crashlytics faz upload automático; configuração custom (variantes de flavor, regions de build) fica para change que introduzir flavors.
- **`recordError` em catch blocks específicos do app** — Parte 2 só liga o pipe (bridge automático via `LoggerClient.error()`). Refatorar try-catch espalhados pelo código pra logar via `_logger.error(..., error: e, stackTrace: s)` é decisão case-by-case, não esta change.
- **Testes unitários do `CrashClient`** — wrapper trivial sem lógica testável (delega 100% para `FirebaseCrashlytics.instance`); cobertura via smoke release nos dois OSes.
- **FCM** (Parte 3) e **App Check** (Parte 4) — partes seguintes.

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
