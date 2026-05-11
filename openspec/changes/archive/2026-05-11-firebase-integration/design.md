# Design — firebase-integration

## Contexto técnico

O Trocado é um app Flutter (`^3.10.0`) com Clean Architecture estrita: `domain ← data ← infrastructure`, `domain ← presentation`, `main → tudo`. Frameworks externos vivem em `infrastructure/clients/<nome>/`. O padrão estabelecido (`logger_client.dart`, `dio_factory.dart`, `flutter_secure_storage` via `storage_provider.dart`) é: interface `I<Nome>Client` + classe `final class <Nome>Client implements I<Nome>Client` no mesmo arquivo, sem arquivo `interface_` separado. Providers Riverpod (`@Riverpod(keepAlive: true)`) compõem em `main/providers/clients_provider.dart` e fazem o wiring de SDKs concretos.

O Firebase SDK é framework-specific (depende de Flutter platform channels e dos artefatos nativos `google-services.json`/`GoogleService-Info.plist`). Por isso vive integralmente em `infrastructure/`, atrás de wrappers. Nenhum import de `package:firebase_*` deve cruzar para `domain/`, `data/` ou `presentation/`.

`main.dart` hoje é mínimo (`WidgetsFlutterBinding.ensureInitialized() + runApp`). Isso facilita inserir um `await container.read(firebaseClientProvider).initialize()` entre os dois.

## Regra de dependência (respeitada)

```
domain ← data ← infrastructure
domain ← presentation
main   → tudo
```

A Parte 1 é **100% infrastructure + main**. Não toca `domain/`, `data/` nem `presentation/`. Blast radius mínimo — wrapper isolado, um provider novo, e refactor pequeno em `main.dart`.

## Decisões de design

### 1. Wrapper `FirebaseClient` em vez de chamar `Firebase.initializeApp` direto

**Decisão**: criar `IFirebaseClient` + `FirebaseClient` em `infrastructure/clients/firebase/` e expor `initialize()` como único método. `main.dart` chama o método via provider, nunca `Firebase.initializeApp` direto.

**Rationale**: o CLAUDE.md exige que código framework-specific viva em `infrastructure/`. O wrapper isola o SDK do resto do app, abre porta para mock em teste (se necessário no futuro) e mantém `main.dart` agnóstico de qual SDK está inicializando (Parte 2 vai inicializar Crashlytics, Parte 4 vai inicializar App Check — tudo via providers correspondentes, sem `main.dart` virar dump de chamadas SDK). Espelha `DioFactory` (Dio também é framework-specific e é construído atrás de wrapper).

**Trade-off**: interface com um único método pode parecer ceremônia desnecessária. Aceitável — o padrão é consistente com `LoggerClient` (também tem interface com métodos simples delegando direto) e as Partes 2/3/4 vão adicionar wrappers semelhantes (`CrashClient`, `MessagingClient`, `AppCheckClient`), criando uma família coerente. Custo de boilerplate é baixíssimo.

### 2. `ProviderContainer` + `UncontrolledProviderScope` em vez de `ProviderScope`

**Decisão**: trocar `runApp(ProviderScope(observers: [...], child: ...))` por:

```dart
final container = ProviderContainer(observers: [stateObserver]);
await container.read(firebaseClientProvider).initialize();
runApp(UncontrolledProviderScope(container: container, child: AppWidget()));
```

**Rationale**: `Firebase.initializeApp` precisa rodar **antes** de `runApp` (a Parte 2 vai instalar `FlutterError.onError` antes da primeira árvore de widgets para capturar crashes de boot; a Parte 4 vai inicializar App Check antes da primeira request HTTP, que pode vir de algum `AsyncNotifier` com `keepAlive: true`). Para reusar o `firebaseClientProvider` (em vez de instanciar `FirebaseClient` direto), o provider precisa ser lido fora do `ProviderScope` — ou seja, em um `ProviderContainer` criado manualmente. `UncontrolledProviderScope` é a forma canônica do Riverpod de injetar um container pré-criado na árvore de widgets, preservando todos os providers, observers e overrides.

**Trade-off**: complexidade extra em `main.dart` (3 linhas em vez de 1). Em troca, ganhamos:
- (a) Capacidade de inicializar dependências async antes de `runApp` reusando providers (padrão que Crashlytics, App Check, e qualquer integração futura vão usar).
- (b) Mesmo container atravessa o widget tree — sem risco de "duas árvores Riverpod" (problema clássico com `ProviderScope` aninhado).
- (c) Observers (`stateObserver`) continuam funcionando exatamente igual.

Alternativa rejeitada — `runApp` direto + listener em provider auto-init: criar um provider `appBootstrapProvider` que faz a inicialização async e renderizar um splash até resolver. Funciona, mas (i) atrasa Crashlytics: errors de boot do app não seriam capturados porque o handler ainda não está instalado quando o widget tree monta, e (ii) atrasa App Check: a primeira request pode disparar antes do `activate()` resolver.

### 3. `google-services.json` e `GoogleService-Info.plist` commitados

**Decisão**: os dois arquivos vão para o repo (`android/app/google-services.json` e `ios/Runner/GoogleService-Info.plist`).

**Rationale**: documentação oficial do Firebase é explícita — esses arquivos contêm IDs públicos (project ID, app ID, sender ID, API key do client SDK). Eles **não são credenciais de servidor**; identificam *qual* projeto Firebase o app usa, mas qualquer um pode obtê-los descompilando o APK/IPA. A segurança real do Firebase vem de:
- **Security Rules** (Firestore, Storage, Database) — não usamos nenhum desses serviços nesta change.
- **App Check** (Parte 4 desta change) — garante que requests vêm do app oficial.
- **OAuth / autenticação** — backend Django já tem JWT próprio.

Commitar simplifica onboarding (clone do repo + `flutter pub get` + `flutter run` funciona) e elimina drift entre devs (todos usando o mesmo projeto Firebase). Padrão recomendado pela própria FlutterFire docs.

**Trade-off**: se algum dia precisarmos de projetos Firebase distintos por ambiente (dev/staging/prod), vamos precisar de build flavors + plists/JSONs por flavor + `.gitignore` mais sofisticado. Aceitável adiar isso — Parte 1 entrega um único projeto Firebase, e quando o split por ambiente for necessário, vira uma change dedicada (não-trivial — exige flavors no `pubspec`, `android/app/src/<flavor>/`, schemes no Xcode).

### 4. `firebase_options.dart` commitado (não gerado em CI)

**Decisão**: o arquivo `lib/firebase_options.dart` produzido pelo `flutterfire configure` é commitado.

**Rationale**: ele é o equivalente Dart do `google-services.json`/`GoogleService-Info.plist` (mesmos IDs públicos, em formato consumível pelo SDK). Não é gerado por build_runner — é gerado pelo CLI, que precisa de credenciais Google do dono do projeto Firebase. Gerar em CI exigiria service account JSON do Firebase no pipeline, que é mais sensível do que o arquivo final. Mais simples e mais seguro committar o arquivo gerado.

**Trade-off**: se um dev rodar `flutterfire configure` localmente sem precisar (ex: pra debug), o arquivo pode mudar e gerar diff no repo. Mitigação: documentar no `CLAUDE.md` (em parte futura) que `flutterfire configure` só é rodado quando há mudança real no projeto Firebase — e essa mudança vira commit explícito.

### 5. Plugin Gradle declarado no root + aplicado em `app/`

**Decisão**: `android/build.gradle.kts` declara `id("com.google.gms.google-services") version "4.4.x" apply false` no bloco `plugins` raiz; `android/app/build.gradle.kts` aplica via `id("com.google.gms.google-services")` no bloco `plugins` do módulo app.

**Rationale**: padrão recomendado pela documentação Android moderna (declarar versão no root, aplicar no módulo). Mantém versão única para o plugin em todo o projeto e isola o `apply` ao módulo que consome `google-services.json`. Espelha exatamente como o `flutter-gradle-plugin` já é declarado/aplicado (root: `id("dev.flutter.flutter-gradle-plugin") version "..." apply false`, app: `id("dev.flutter.flutter-gradle-plugin")`).

**Trade-off**: versão exata do plugin é pinada na implementação (lookup no Maven). Aceitável — Firebase atualiza esse plugin com cadência baixa (raramente quebra contrato).

### 6. Nenhum override em `AppDelegate.swift` nesta parte

**Decisão**: a Parte 1 **não toca** `ios/Runner/AppDelegate.swift`. O `flutterfire configure` já fez todo o setup iOS necessário — registro do plist no Xcode project é o suficiente.

**Rationale**: o SDK do Firebase Core inicializa via `FirebaseApp.configure()` automaticamente no `application(_:didFinishLaunchingWithOptions:)` se a `Firebase.initializeApp` Dart for chamada antes de `runApp` (que é o que fazemos). Não há necessidade de adicionar código nativo manualmente. A Parte 4 (App Check) vai precisar mexer no `AppDelegate.swift` para chamar `FirebaseAppCheck.appCheck().setAppCheckProviderFactory(...)` **antes** de `FirebaseApp.configure()`, mas isso é decisão da Parte 4 (não desta).

**Trade-off**: nenhum visível. Mantemos `AppDelegate.swift` o mais limpo possível pelo maior tempo possível.

### 7. Wrappers das Partes 2/3/4 seguem o mesmo padrão de `FirebaseClient`

**Decisão (preview)**: `CrashClient` (Parte 2), `MessagingClient` (Parte 3) e `AppCheckClient` (Parte 4) seguem exatamente o mesmo padrão: `infrastructure/clients/<nome>/<nome>_client.dart`, interface `I<Nome>Client` + classe `final class <Nome>Client`, providers `@Riverpod(keepAlive: true)` em `clients_provider.dart`.

**Rationale**: coerência arquitetural. Quando o app tiver Firebase Core + Crashlytics + Messaging + App Check, todos os SDKs estarão atrás de wrappers irmãos em `clients/`. Qualquer dev que abrir o folder consegue prever o padrão dos próximos SDKs Firebase que entrarem (Analytics, Performance, Remote Config — se um dia entrarem).

**Trade-off**: nada relevante. O custo de seguir o padrão é negligível e o ganho de previsibilidade é grande.

### 8. Sem testes unitários para `FirebaseClient`

**Decisão**: nenhum arquivo em `test/src/infrastructure/clients/firebase/` será criado nesta parte.

**Rationale**: `FirebaseClient.initialize()` é puro delegate para `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)` — não há ramificação, não há erro tratado, não há transformação de dados. Testar seria mockear `Firebase.initializeApp` para verificar que foi chamada com o argumento correto — o que é tautológico (o teste replica exatamente o corpo do método). A regressão real é detectada via smoke manual nos dois OSes (boot Android e iOS) — se algo quebrar no setup nativo, o app não inicia, e isso é detectável a olho. Conferir a precedência: `LoggerClient` também não tem teste unitário (delega para `TalkerLogger`).

**Trade-off**: cobertura "no papel" não cresce. Aceitável — cobertura real (regressão detectável) está garantida pelo smoke.

### 9. App Check sem validação backend ainda (Parte 4 — preview)

**Decisão (Parte 4)**: o `AppCheckInterceptor` vai enviar header `X-Firebase-AppCheck: <token>` em toda request HTTP, mesmo que o backend Django ainda não valide.

**Rationale**: o lado app fica pronto (interceptor, token gerado, header injetado). Quando o backend ligar a validação (change separada do lado Django), nenhum código no app muda. Isso desacopla os dois lados — podemos shipar a Parte 4 antes do backend estar pronto, ganhando experiência operacional com Play Integrity/App Attest (debug tokens, registros no console, problemas em devices reais) sem bloquear no backend.

**Trade-off**: enquanto o backend ignora, o App Check no app é "decorativo" — gera token, envia header, ninguém valida. Aceitável porque (i) a expectativa é que o backend ligue a validação dentro de poucas semanas após a Parte 4, e (ii) o app está produzindo o token de verdade, então qualquer bug de Play Integrity ou App Attest aparece cedo (não na hora que o backend liga a validação e quebra todos os usuários de uma vez).

### 10. Parte 2 — Bridge `talker` → Crashlytics via `LoggerClient`, não via `TalkerObserver`

**Decisão (Parte 2)**: `LoggerClient` recebe `ICrashClient` via construtor e os métodos `error()` e `critical()` chamam `_crashClient.recordError(..., fatal: false)` direto. **Não** criamos uma classe `CrashTalkerObserver` que anexa ao `Talker`.

**Rationale**: o esboço original mencionava `TalkerObserver`, mas `LoggerClient` hoje usa `TalkerLogger` (a versão *light* do pacote `talker`) — não a classe `Talker` completa. `TalkerLogger` **não** tem suporte a observers (essa feature vive na classe `Talker`). As opções eram:

(a) Migrar `LoggerClient` de `TalkerLogger` pra `Talker`, anexar observer.
(b) Wire direto nos métodos `error()`/`critical()` do `LoggerClient`.

A (b) é estritamente menos código, mais explícita (o bridge é uma linha visível no método de log, não um observer fantasma), e não exige aprender a API completa de `Talker` (`history`, `onLog`, settings de retenção, etc.) só pra capturar 2 níveis de log. O preço da explicit-ness é que adicionar `warning()` ou `critical()` ao bridge no futuro exige edição da impl em vez de só adicionar um listener — aceitável dado o escopo pequeno.

**Trade-off**: se um dia precisarmos de breadcrumbs no Crashlytics (`Talker.history` tem um buffer das últimas N mensagens), vamos ter que migrar pra `Talker` completa de qualquer jeito. Aceitável adiar — breadcrumbs são feature de power-debugging, não MVP de observabilidade.

### 11. Parte 2 — Só `error` e `critical` reportam, não `warning`

**Decisão (Parte 2)**: apenas `LoggerClient.error()` e `LoggerClient.critical()` chamam `_crashClient.recordError`. `warning()`, `information()`, `debug()`, `verbose()` não tocam o Crashlytics.

**Rationale**: Crashlytics cobra (em volume de dados, em ruído pra triagem) por cada `recordError`. Warnings semanticamente são "atenção, mas o sistema seguiu" — não são falhas. Reportar warnings infla o painel de Issues com coisas que não exigem ação. Erro / crítico **exigem** ação — é o sinal certo pra Issues.

**Trade-off**: se algum dia descobrirmos que warnings de pré-falha eram úteis pra root cause de bug X, fica fácil ampliar (uma linha em `warning()`). Inverter (reportar tudo e depois filtrar) é trabalho de configuração no Console — mais caro.

### 12. Parte 2 — `recordError` é fire-and-forget; `LoggerClient.error()` continua síncrono

**Decisão (Parte 2)**: a chamada `_crashClient.recordError(...)` dentro de `LoggerClient.error()` **não** é `await`-ada. A interface `ILoggerClient.error()` continua síncrona retornando `void`.

**Rationale**: bloquear o caller só pra esperar Crashlytics persistir o report seria uma regressão de performance (chamadas a `_logger.error` em hot paths viraria operação async). Crashlytics SDK já garante persistência em disco antes de retornar do `recordError` — não há perda se o app crashar logo depois (próxima boot envia o report acumulado).

**Trade-off**: o linter pode reclamar de `Future` sem await (`unawaited_futures`). Mitigação: envolver em `unawaited(_crashClient.recordError(...))` da `dart:async` se necessário, ou suprimir explicitamente.

### 13. Parte 2 — `PlatformDispatcher.onError` reporta `fatal: true`; `FlutterError.onError` deixa o SDK decidir

**Decisão (Parte 2)**:
- `PlatformDispatcher.instance.onError` (erros assíncronos não-capturados) usa `crashClient.recordError(..., fatal: true)`.
- `FlutterError.onError` delega para `crashClient.recordFlutterError(details)`, que internamente o SDK marca como **não-fatal** (build-phase, framework errors).

**Rationale**: Crashlytics usa "fatal" pra diferenciar "app crashou" vs "app continuou rodando". `PlatformDispatcher.onError` só dispara em uncaught Futures e erros de isolate — situações onde o estado do app está corrompido (algum await falhou silenciosamente, dados inconsistentes). É efetivamente um crash mesmo que o framework Flutter siga renderizando. Por outro lado, `FlutterError.onError` dispara em erros de build/render (overflow de RenderBox, etc.) que o framework recupera — claramente não-fatal.

**Trade-off**: o critério de fatal influencia ranking de severidade no Console. Aceitar o default do SDK (fatal para PlatformDispatcher, non-fatal para FlutterError) replica o comportamento padrão do `firebase_crashlytics` example app — segue o que a comunidade espera.

### 14. Parte 2 — Crashlytics coleta em debug + release; smoke exige release

**Decisão (Parte 2)**: `setCrashlyticsCollectionEnabled` é deixado no default (true em todos os modos). Mas o **smoke de verificação** exige `flutter run --release` em device físico.

**Rationale**: deixar coleta ligada em debug significa que durante desenvolvimento, crashes locais sobem pro Console — desejável pra validar o pipeline rapidamente sem precisar fazer release build. Por outro lado, o crash handler nativo do Crashlytics só dispara confiavelmente em release: em debug o Flutter / Xcode interceptam o crash pra debugger antes do Crashlytics ver. Por isso o smoke específico de "crash → Console" precisa release.

**Trade-off**: relatórios de debug poluem o painel com crashes de desenvolvimento. Filtros por versão de build no Console resolvem; se virar problema sério, a change futura pode desligar via `setCrashlyticsCollectionEnabled(kReleaseMode)`.

### 15. Parte 2 — Sem `setUserIdentifier` nem custom keys com dados do app

**Decisão (Parte 2)**: zero identificação de usuário (`setUserIdentifier`, `setCustomKey` com `user.id`, `email`, etc.). Crashes anônimos.

**Rationale**: LGPD trata identificadores pseudoanônimos como dado pessoal quando ligados a outras informações. Identificar usuário no Crashlytics, mesmo só com `user.id`, exige base legal explícita (consentimento ou interesse legítimo documentado). Sem consent flow no app, não temos base. Custom keys com dados financeiros (saldo, número de orçamentos) são piores — são dados sensíveis que não deveriam sair do device sem necessidade.

**Trade-off**: triagem de crashes fica mais difícil (não dá pra associar "esse crash bate o usuário X que reportou via suporte"). Aceitável pra início — quando volume crescer e essa fricção for real, criar change dedicada com opt-in.

### 16. Parte 2 — Sem testes unitários para `CrashClient`

**Decisão (Parte 2)**: nenhum arquivo em `test/src/infrastructure/clients/crash/`. Wrapper é delegate puro.

**Rationale**: mesmo argumento de `FirebaseClient` (decisão #8). `CrashClient.recordError(...)` chama `FirebaseCrashlytics.instance.recordError(...)` 1-pra-1 com os mesmos parâmetros. Testar seria mockear o singleton (lento, frágil) pra verificar parametros — tautológico. Regressão real é detectada via smoke release.

**Trade-off**: para `LoggerClient` o argumento muda — agora ele tem **lógica condicional** (`if (error != null && stackTrace != null)`) que vale testar. Se já existe `logger_client_test.dart`, atualizar com casos:
- `error()` com error+stackTrace → `MockCrashClient.recordError` chamado.
- `error()` sem error → `MockCrashClient.recordError` **não** chamado.
- Idem `critical()`.
- `warning()` com error+stackTrace → `MockCrashClient.recordError` **não** chamado.

Se `logger_client_test.dart` não existe hoje, **não** criar nesta parte — manter consistência com a decisão original de não testar wrappers.

### 17. Parte 3 — Token FCM logado em `main.dart`, **não** em notifier de auth

**Decisão (Parte 3)**: `_logFcmToken(container)` é chamado em `main.dart` após as bridges de Crashlytics, com `unawaited(...)`. **Não** vai dentro de `SignInNotifier._submit` nem `SignUpNotifier._submit`.

**Rationale**: o esboço original mencionava "ramificação Right de SignInNotifier". Implementar assim violaria a regra de dependência do CLAUDE.md — notifiers vivem em `presentation/`, que depende exclusivamente de `domain/`. Ler `messagingClientProvider` (que retorna `IMessagingClient` de `infrastructure/`) dentro de notifier criaria import direto de `presentation → infrastructure`, contornando a camada de domain. `main.dart` é o único composition root autorizado a tocar infrastructure direto.

Timing: token FCM é por-device, não por-usuário. Buscar no boot é equivalente a buscar pós-auth — o token é o mesmo. Quando o backend ligar o endpoint para receber tokens, aí faz sentido relocar pra pós-auth (porque a request precisa do JWT do usuário no header). Por ora, boot é mais simples e respeita a arquitetura.

**Trade-off**: o token é loggado **toda vez** que o app boota. Cada chamada é cheap (FCM cacheia local; só o primeiro boot real exige round-trip). Esse log pode ser uma anomalia visual no talker mas não tem custo real.

### 18. Parte 3 — iOS Push capability **não** adicionada; `MessagingClient` absorve o erro conhecido

**Decisão (Parte 3)**: o entitlement `aps-environment` (capability "Push Notifications") **não** é adicionado ao `Runner.entitlements`. iOS sem capability lança `FirebaseException(code: 'apns-token-not-set')` em `getToken()` — o wrapper `MessagingClient` captura esse código específico e devolve `null` para o caller, que loga `"FCM token: (null)"` discretamente.

**Aprendizado**: o esboço inicial assumiu que iOS retornaria `null` puro; a realidade é throw. Descoberto no smoke da Parte 3 (stack trace gigante via bridge Crashlytics). Spec corrigida para refletir o comportamento real e o filtro no wrapper.

**Rationale**: ligar a capability isolada cria estado intermediário esquisito — TestFlight mostra "Push Notifications" como Capability ativa, mas o app não pede permissão, não exibe notificação, não roteia tap. Reviewer da Apple, dev futuro ou suporte vão se perguntar "por que está ligada se não funciona?". Pior, em ambientes onde o Trocado for assinado com provisioning profile que **não** inclui Push Notifications (alguns dev profiles), o build de release pode quebrar de surpresa.

Capability deve ser ligada **junto** com (a) `requestPermission()`, (b) `AppDelegate.swift` overrides pra UNUserNotificationCenter, (c) handlers de payload, (d) APNs key no Console. Tudo numa change unificada — escopo de "ligar push em iOS de verdade".

**Trade-off**: iOS na Parte 3 é "meio-pronto" — só Android tem token logado. Aceitável: o objetivo dessa parte é validar o SDK rodando, não tokens de produção iOS. Quando o backend ligar e a change de push iOS chegar, o pipe iOS fica completo no mesmo momento que ele passa a importar.

### 19. Parte 3 — `unawaited(...)` em vez de `await` para não bloquear o boot

**Decisão (Parte 3)**: `_logFcmToken` é disparado via `unawaited(...)` (do `dart:async`), não `await`-ado em `main()`.

**Rationale**: o token é informativo (log); o app não depende dele pra renderizar. Aguardar resolve algo entre 100ms (cache hit) e alguns segundos (cold start sem rede); fazer o splash esperar isso é regressão de UX por nada. Se a chamada falha (rede off, FCM rate-limited), o try-catch interno loga via `logger.error` (que pelo bridge Parte 2 vai pro Crashlytics como não-fatal). Erros não-tratados que escapem do try-catch caem no `PlatformDispatcher.onError` bridge da Parte 2 — duplo safety net.

**Trade-off**: o linter `unawaited_futures` poderia reclamar; usar `unawaited(...)` da `dart:async` é exatamente o idioma canônico que silencia o warning sem suprimir nada legítimo.

### 20. Parte 3 — Sem `onTokenRefresh`, sem topics, sem handlers

**Decisão (Parte 3)**: `IMessagingClient` expõe **só** `getToken()`. Não há `subscribeToTopic`, `unsubscribeFromTopic`, `onTokenRefresh` stream, `onMessage` handler, nada disso.

**Rationale**: cada uma dessas APIs corresponde a uma feature de produto (segmentação por topic, manter o backend atualizado quando o token rota, exibir notificação em foreground). Adicionar interface sem caso de uso real gera código não-exercitado = surface de bug. Quando cada feature for necessária, a interface ganha o método junto com a impl + os call-sites + o teste — change atômica.

**Trade-off**: ampliar `IMessagingClient` no futuro vai exigir editar duas linhas (interface + impl) por método. Aceitável; é menos custo que arrastar interface inflada desde o início.

### 21. Parte 3 — Sem testes unitários para `MessagingClient`

**Decisão (Parte 3)**: nada em `test/src/infrastructure/clients/messaging/`. Wrapper trivial — mesmo argumento das decisões #8 (FirebaseClient) e #16 (CrashClient).

**Rationale**: `MessagingClient.getToken()` é delegate puro pra `FirebaseMessaging.instance.getToken()`. Testar exige mockear o singleton estático — frágil e tautológico. Regressão real detectada via smoke (token aparece no log Android).

### 22. Parte 4 — Estratégia de providers (`debug` vs `playIntegrity`/`appAttest`) encapsulada no wrapper

**Decisão (Parte 4)**: `AppCheckClient.activate()` decide internamente qual provider usar baseado em `kDebugMode`. `main.dart` chama `activate()` sem parametrizar.

**Rationale**: tipos `AndroidProvider` e `AppleProvider` vêm de `package:firebase_app_check/...` — se a interface `IAppCheckClient.activate()` aceitasse esses tipos como parâmetros, o caller (composition root) teria que importar `firebase_app_check`, vazando o SDK pra fora de `infrastructure/clients/app_check/`. O ponto do wrapper é isolar o SDK; deixar a decisão de provider dentro dele preserva esse isolamento.

**Trade-off**: se um dia precisarmos overridar o provider em testes (ex: forçar debug em release para canary), o wrapper precisa expor a configuração. Aceitável adiar — não há caso de uso atual, e ampliar a interface depois é uma linha de código.

### 23. Parte 4 — `AppCheck.activate()` antes de qualquer outro serviço Firebase

**Decisão (Parte 4)**: a ordem em `main()` fica:
1. `Firebase.initializeApp` (Parte 1)
2. `AppCheck.activate` (Parte 4) ← **novo**
3. Crashlytics bridges (Parte 2)
4. FCM `getToken()` (Parte 3) ← consumidor de App Check
5. `runApp`

**Rationale**: FCM `getToken()` chama Firebase Installations sob o capô, que é App Check-protected. Se App Check não estiver ativo, Installations pode rejeitar o request quando o backend ligar enforcement — e fica chato debug porque o erro aparece em momento aparentemente desconexo. Ativar App Check antes de qualquer outro serviço Firebase é a recomendação oficial do FlutterFire e elimina toda essa classe de bug.

**Trade-off**: `activate()` adiciona ~50-200ms ao boot (depending on Play Integrity / App Attest cold start). É `await`-ado (não `unawaited`) porque os serviços subsequentes dependem dele. Custo aceitável — boot já tem `Firebase.initializeApp` (~100ms) e o tempo até `runApp` continua sub-segundo.

### 24. Parte 4 — `AppCheckInterceptor` antes do `AuthenticationInterceptor`

**Decisão (Parte 4)**: na lista de interceptors do `DioFactory.create()`, `AppCheckInterceptor` vem **antes** do `AuthenticationInterceptor`.

**Rationale**: dois motivos.

(1) Endpoints públicos (sign-in, sign-up — definidos em `EndpointKey.isPublicPath`) bypassam o `AuthenticationInterceptor` (a header `Authorization: Bearer` só é injetada em endpoints autenticados). Mas eles devem ter `X-Firebase-AppCheck` mesmo assim — App Check é gate de identidade do **device**, não do usuário. Atacante criando contas em massa via script sem App Check é exatamente o cenário que essa parte protege. Logo App Check tem que rodar antes do early-return do AuthenticationInterceptor.

(2) Convenção: middleware de identidade do device vem antes de identidade do usuário (mesma ordem que cloud platforms tipicamente seguem — TLS → WAF → rate-limit por IP → auth de aplicação → auth de usuário).

**Trade-off**: `getToken()` é chamado em **toda** request, mesmo as públicas. O SDK do `firebase_app_check` cacheia o token internamente (~1h de TTL), então o custo real após o primeiro fetch é uma leitura em memória. Aceitável.

### 25. Parte 4 — Token nulo / exception → request segue sem header (não bloqueia)

**Decisão (Parte 4)**: se `IAppCheckClient.getToken()` retorna `null` ou lança, o `AppCheckInterceptor` engole silenciosamente e a request segue sem o header.

**Rationale**: App Check é um gate de **defesa em profundidade**, não um gate primário. Se ele falhar no client (rede momentaneamente off, provider rate-limited, debug token não-registrado, App Attest API temporariamente fora), a request ainda tem Bearer auth do `AuthenticationInterceptor` — o backend recebe a request e decide. O backend é a autoridade final: hoje aceita, amanhã pode rejeitar com 401, e o app trata como qualquer outro 401.

Bloquear localmente seria pior: usuário com rede instável ficaria com app travado em "checking..." sem feedback útil, quando a request normal teria 90% de chance de sucesso (apenas o flag App Check faltando).

**Trade-off**: ataques sofisticados podem tentar forçar falha local de App Check para bypassar o header. Aceitável — quando o backend ligar enforcement, ele rejeita request sem header igualzinho a token inválido. Defesa fica no backend, onde deve estar.

### 26. Parte 4 — Debug Provider em `kDebugMode`; release providers em release builds

**Decisão (Parte 4)**: `kDebugMode == true` → `AndroidProvider.debug` + `AppleProvider.debug`. Caso contrário → `AndroidProvider.playIntegrity` + `AppleProvider.appAttest`.

**Rationale**: providers de produção (Play Integrity, App Attest) **não funcionam** em emuladores Android sem Play Services, simuladores iOS, ou builds sem signing release. Tentar usar Play Integrity em `flutter run` no Android Studio emulator quebra com erro genérico de "Integrity API not available". Debug Provider existe exatamente pra cobrir esses cenários — gera tokens de teste que o Firebase backend aceita **se o UUID estiver registrado no Console**.

Usar `kDebugMode` como switch acopla a decisão ao tipo de build, que é a discriminação correta. `flutter build apk --release` ou `flutter build ios --release` automaticamente desativam `kDebugMode` e ligam os providers de produção. CI pode rodar release builds sem precisar manipular env vars.

**Trade-off**: TestFlight builds (com signing real mas via debug build no Xcode) ficam com Debug Provider — mas TestFlight builds são quase sempre release builds. Edge case raro.

### 27. Parte 4 — iOS App Attest entitlement **não** adicionado nesta parte

**Decisão (Parte 4)**: `Runner.entitlements` **não** ganha `com.apple.developer.devicecheck.appattest-environment` nesta parte. Provisioning profile no Apple Developer Portal **não** é alterado.

**Rationale**: mesma lógica da decisão #18 (Push capability deferred): ligar entitlement isolado sem um caso de uso real (App Attest enforcement do backend) cria estado intermediário esquisito. Pior: entitlement exige update do provisioning profile, que é trabalho manual no Developer Portal + re-download em todos os devs + re-distribuição do profile. Custo alto pra zero ganho enquanto backend não valida.

iOS em debug (Debug Provider) **não** exige o entitlement — o Debug Provider usa a API privada do FlutterFire para emitir tokens locais. Para release com App Attest real, entitlement + provisioning entram juntos na primeira change que efetivamente ligar enforcement.

**Trade-off**: primeira release que exigir App Attest vai ter um setup iOS extra (entitlement + profile). Aceitável — esse trabalho fica concentrado no momento em que ele importa.

### 28. Parte 4 — Teste do `AppCheckInterceptor`; sem teste do wrapper

**Decisão (Parte 4)**: criar `test/src/infrastructure/clients/http/interceptors/app_check_interceptor_test.dart` cobrindo 3 cenários (token, null, throw). **Não** criar teste do `AppCheckClient` wrapper.

**Rationale**: o interceptor **tem lógica condicional** (`if (token != null)` + try-catch swallow) — vale teste. O `AppCheckClient` é delegate puro (mesma lógica das decisões #8/#16/#21). Mock em `IAppCheckClient`, instanciar interceptor, montar `RequestOptions` + `RequestInterceptorHandler` fakes, exercitar `onRequest`, verificar headers.

**Trade-off**: `MockAppCheckClient` é mais um mock em `test/mocks/mocks.dart` — boilerplate pequeno, aceitável.

### 29. Não introduzir Firebase Analytics nesta change

**Decisão**: Analytics (mesmo que habilitado no Console na fase 0.2) **não é integrado** ao app em nenhuma das 4 partes.

**Rationale**: Analytics é coleta de dados de comportamento do usuário — decisão de privacidade explicitamente fora do escopo de "Firebase plumbing". LGPD exige consentimento informado para coleta de telemetria comportamental; sem isso configurado (banner de consentimento, opt-out em Settings), habilitar Analytics seria não-conforme. Crashlytics, FCM e App Check são plumbing técnico (observabilidade de defeitos, canal de notificação contratualmente esperado, gate de segurança) — não pedem o mesmo consentimento explícito.

**Trade-off**: a opção `Habilitar Google Analytics` na fase 0.2 fica `true` mas a feature fica desligada no app — Console pode mostrar "0 events" ou warning de "no events received". Aceitável e esperado. Quando Analytics for ligada, será change dedicada com consent UX.
