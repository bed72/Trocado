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

### 10. Não introduzir Firebase Analytics nesta change

**Decisão**: Analytics (mesmo que habilitado no Console na fase 0.2) **não é integrado** ao app em nenhuma das 4 partes.

**Rationale**: Analytics é coleta de dados de comportamento do usuário — decisão de privacidade explicitamente fora do escopo de "Firebase plumbing". LGPD exige consentimento informado para coleta de telemetria comportamental; sem isso configurado (banner de consentimento, opt-out em Settings), habilitar Analytics seria não-conforme. Crashlytics, FCM e App Check são plumbing técnico (observabilidade de defeitos, canal de notificação contratualmente esperado, gate de segurança) — não pedem o mesmo consentimento explícito.

**Trade-off**: a opção `Habilitar Google Analytics` na fase 0.2 fica `true` mas a feature fica desligada no app — Console pode mostrar "0 events" ou warning de "no events received". Aceitável e esperado. Quando Analytics for ligada, será change dedicada com consent UX.
