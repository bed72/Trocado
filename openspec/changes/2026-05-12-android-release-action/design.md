# Design — android-release-action

## Contexto técnico

Build atual do Trocado:
- Flutter `^3.10.0` em Dart puro + Android via Flutter Gradle plugin.
- `android/app/build.gradle.kts` lê versão de `android/version.properties` (não do pubspec) — duplicação histórica.
- `signingConfigs.release` aponta pra path absoluto `/home/bed/Documentos/Code/keys/trocado.jks` — quebra qualquer build que não seja na máquina pessoal do owner.
- Release build type tem `isMinifyEnabled = true` + `isShrinkResources = true` — ProGuard gera `mapping.txt` (necessário pro upload no Play).
- Firebase Crashlytics wired via `CrashClient` + plugin `com.google.firebase.crashlytics` no Gradle. Crashes nativos (NDK) e Dart bridged via `FlutterError.onError` / `PlatformDispatcher.instance.onError`. **Sem upload de símbolos** em nenhum lugar — release crashes são opacos.
- App Check com Play Integrity provider em release, debug provider em debug — debug funciona local; release exige SHA-256 do keystore registrado no Firebase Console (configuração one-time pós primeiro release).

Stack do workflow:
- GitHub Actions com runner Ubuntu (mais barato e rápido que macOS, suficiente pra Android).
- `subosito/flutter-action@v2` pra setup Flutter.
- `actions/setup-java@v5` pra Temurin 17.
- `gradle/actions/setup-gradle@v3` pra cache de Gradle caches + wrapper.
- `actions/cache@v4` pra NDK (cold install ~3-5min via SDK Manager).
- `r0adkll/upload-google-play@v1.1.5` pro upload no Play Console (popular, mantido, suporta mappingFile).
- `firebase-tools` (npm global) pra upload de símbolos Crashlytics — Google não tem GitHub Action oficial pra isso.

## Regra de dependência (respeitada)

```
domain ← data ← infrastructure
domain ← presentation
main   → tudo
```

Esta change é **100% tooling/build (Gradle + CI)**. Zero linha em `domain/`, `data/`, `infrastructure/`, `presentation/`, `main/`. Blast radius limitado a:
- `android/app/build.gradle.kts`
- `android/version.properties`
- `.github/workflows/android-release.yml` (novo)
- `CLAUDE.md` (doc)

Nenhum risco arquitetural; risco operacional concentrado em secrets e signing.

## Decisões de design

### 1. **Pubspec como single source of truth** de versão

**Decisão**: remover `versionName`/`versionCode` do `defaultConfig` no `build.gradle.kts`. Deixar o Flutter Gradle plugin ler de `pubspec.yaml` automaticamente.

**Rationale**: hoje pubspec **e** version.properties têm que ser bumpados juntos. Convenção do Flutter é `version: X.Y.Z+N` no pubspec → versionName=X.Y.Z, versionCode=N propagados pra Gradle pelo plugin. Manter `version.properties` duplicando isso é anti-convenção e fonte de drift (bumpar pubspec e esquecer do properties = APK com versão "antiga" na meta-info nativa enquanto Dart reporta a nova).

`version.properties` **fica** — agora só pra coisas que não estão no pubspec (NDK version, SDK versions). Esse é o uso legítimo: pin de toolchain reproduzível.

**Trade-off**: bump fica em 1 PR (mexe só em pubspec), mas dev precisa lembrar que `version.properties` **não controla mais** o versionCode/versionName. Documentar em `CLAUDE.md`.

### 2. **Manual dispatch only, sem trigger em push/PR**

**Decisão**: workflow só roda via `workflow_dispatch` (botão "Run workflow" no UI ou `gh workflow run`).

**Rationale**: release é evento humano, não consequência de push. Trigger em push ou tag automaticamente publica AABs em rajada — qualquer PR ruim merge'ado pega o Play em modo "draft" mas ainda assim é poluição de drafts e gasta build minutes.

`workflow_dispatch` exige clique humano explícito. Combinado com `track: internal` + `status: draft`, há **dois gates humanos** antes de qualquer usuário receber update:
1. Dispatch da action.
2. Click em "Review release" → "Start rollout" no Play Console.

**Trade-off**: dev precisa lembrar de disparar a action. Aceitável — releases são raras (semanas/meses), não acontecem por engano.

Alternativa rejeitada: trigger em tag `v*`. Acopla tag a release; se quiser tagear pra organizar histórico sem shipar, fica preso. Manual é mais flexível.

### 3. **Track `internal` + status `draft` por padrão**

**Decisão**: o workflow sempre sobe pra track `internal` com `status: draft`. Promoção pra `beta` ou `production` é manual no Play Console.

**Rationale**: o `internal` track no Play tem rollout instantâneo (sem review do Google) e suporta apenas testers explicitamente cadastrados — perfeito pra smoke pós-build. `status: draft` adiciona um gate de revisão humana: o AAB sobe mas testers **não recebem** até alguém clicar "Review release".

Trabalho de promoção (internal → closed beta → open beta → production) fica fora da automação. Esses tracks têm caveats próprios (rollout %, esperar Google Play review pra production, etc.) que merecem decisão consciente humana, não pipe automático.

**Trade-off**: cada release exige clique manual após CI. Aceitável — é dezenas de segundos pra evitar publicar Treasury em produção por dispatch errado.

### 4. **Mesmo service account pra Firebase Crashlytics e Play Console** (default recomendado)

**Decisão**: 1 secret `PLAY_SERVICE_ACCOUNT_JSON` usado tanto pra upload de símbolos no Crashlytics (via `GOOGLE_APPLICATION_CREDENTIALS`) quanto pra `r0adkll/upload-google-play`.

**Rationale**: ambos consomem credenciais Google. O Firebase CLI lê do env var `GOOGLE_APPLICATION_CREDENTIALS` pointing pro JSON; o `r0adkll/upload-google-play` aceita o JSON direto como input. Reaproveitar 1 service account com **2 perms**:
- Firebase Console: Firebase Admin SDK (concede Crashlytics symbol upload).
- Play Console: "Liberar apps para as faixas de teste".

Resultado: 1 secret no GitHub em vez de 2. Menos rotação, menos chance de drift.

**Trade-off**: se um dia o operador quiser separar (princípio do menor privilégio levado ao limite), basta criar dois SAs, dois secrets e ajustar os steps. Hoje a simplicidade vale mais.

Alternativa rejeitada: 2 SAs separados (1 pra Firebase, 1 pra Play). Mais segregação, mais cerimônia. Não compensa pra app solo.

### 5. **Símbolos Dart via `--obfuscate` + `--split-debug-info` + Firebase CLI**

**Decisão**: o build comando inclui `--obfuscate --split-debug-info=build/symbols`. Step subsequente faz `firebase crashlytics:symbols:upload --app=<id> build/symbols`.

**Rationale**: sem `--obfuscate`, o Dart vai obfuscado no APK final mas os símbolos não saem do build process — Crashlytics não consegue resolver `libapp.so` stack traces. Com `--split-debug-info`, os símbolos vão pra um diretório separado (não embedded no APK, mantém size pequeno) e o Firebase CLI sobe esses símbolos pro backend do Crashlytics.

Resultado: crash em `libapp.so + 0x1A2B` no painel do Crashlytics vira `expense_notifier.dart:42 — _ExpenseNotifier._submit()`.

**Trade-off**: build fica ~30s mais lento (obfuscation + symbol extraction). Aceitável — release builds são raras.

Alternativa rejeitada: nativo Crashlytics Gradle plugin's `uploadCrashlyticsSymbolFile` (NDK symbols só). Cobre crashes nativos mas não Dart obfuscado — solução incompleta.

### 6. **`continue-on-error: true` no Crashlytics upload + warning explícito**

**Decisão**: o step de upload de símbolos tem `continue-on-error: true`. Se falhar, há um step subsequente que emite `::warning::` no log e marca o summary.

**Rationale**: símbolos são "nice to have" pra observabilidade, não bloqueador de ship. Se Firebase API ficar 5xx num momento específico, não justifica re-rodar 14 minutos de build + re-upload no Play. Mas operador precisa saber que aquele build específico vai ter crashes opacos no Crashlytics — daí o warning visível no summary, não silencioso.

**Trade-off**: símbolos podem ficar ausentes pra uma release sem ninguém notar se ninguém ler o summary. Mitigado pela linha "Crashlytics symbols: **failed**" no summary final ser hardcoded em formato visível.

### 7. **Tag git só depois do upload no Play succeed**

**Decisão**: o step `Tag the release commit` roda **depois** de `Upload to Play Console`. Se Play upload falhar, job aborta, tag nunca é criada.

**Rationale**: tag = "este commit virou um build distribuído". Se build construiu mas Play recusou (versionCode duplicado, AAB inválido, SA sem perm, etc.), o commit **não shipou** — não deve receber tag. Próxima dispatch tenta o mesmo pubspec version novamente (porque CI não bumpa pubspec).

Idempotência: se a tag já existir no remote (re-dispatch acidental), step skip com warning em vez de falhar.

**Trade-off**: se Play upload passar mas tag step der erro de permissão, o release shipou sem tag. Edge case raríssimo; recuperação manual (`git tag -a vX.Y.Z+N -m "..."; git push --tags`).

### 8. **Path do keystore em dev local: `<repo>/.keys/trocado.jks`** (gitignored)

**Decisão**: o fallback do `signingConfigs.release.storeFile` resolve pra `../../.keys/trocado.jks` (relativo a `android/app/`, i.e., `<repo>/.keys/trocado.jks`). Dev local coloca o `.jks` lá.

**Rationale**: o path absoluto `/home/bed/Documentos/Code/keys/trocado.jks` quebra em qualquer outra máquina. Path relativo dentro do repo (gitignored) é portátil e descobrível (qualquer dev abre o `.gitignore`, vê `.keys/`, entende a convenção).

Env var `TROCADO_KEYSTORE_PATH` permite override absoluto se o operador preferir manter o `.jks` em outro lugar (ex: keyring externo). CI sempre usa env var pointing pra `.keys/trocado.jks` decodificado.

**Trade-off**: dev precisa copiar o keystore pro `.keys/` (ou setar env var). Documentado em `CLAUDE.md`. Aceitável.

### 9. **NDK pinned em `version.properties`, cacheado por content-hash**

**Decisão**: a `flutterNdkVersion` continua em `android/version.properties` como `trocado.ndkVersion=29.0.14206865`. Workflow tem step `Read NDK version` que faz `grep` no properties pra resolver, e usa esse valor como cache key.

**Rationale**: NDK 29 cold install via SDK Manager leva ~3-5min. Cache do diretório `${ANDROID_HOME}/ndk/<version>` reduz pra segundos. Cache key derivado do `version.properties` invalida automaticamente quando o NDK é bumpado.

**Trade-off**: cache do GitHub Actions tem 10GB de cota total por repo — NDK 29 deve pesar ~1GB. Bem dentro do budget.

### 10. **Single `BASE_URL` secret, sem suporte multi-env hoje**

**Decisão**: 1 secret `BASE_URL` apontando pra URL prod do backend Django. Passado via `--dart-define=BASE_URL=<url>` no build.

**Rationale**: Trocado é production-only (decisão da sessão anterior — flavors removidos). Suporte a staging/dev URL no CI workflow viraria N secrets condicionais (`BASE_URL_STAGING`, etc.) sem benefício imediato. Quando staging existir, é change separada.

**Trade-off**: zero. Configuração mais simples possível.

Alternativa rejeitada: hardcode da URL no código + recompile pra trocar. Quebra reprodutibilidade entre builds (mudaria o source pra mudar URL).

### 11. **Sem promoção automática internal → beta → production**

**Decisão**: workflow para no track `internal` + `status: draft`. Promoção é manual.

**Rationale**: cada track tem caveats próprios:
- `internal` → instantâneo, testers cadastrados.
- `alpha`/`closed beta` → pode exigir review do Google em alguns casos.
- `production` → review do Google sempre, rollout %, possível halt.

Automatizar isso significa replicar lógica do Play Console num YAML — pouco valor agregado. Promoção é decisão consciente humana (smoke test passou? rollout faseado? esperar 24h pra ver crashes?).

**Trade-off**: cada release tem manual step pós-CI. Aceitável.

### 12. **Cleanup de credentials no working dir após cada run**

**Decisão**: step `Cleanup credentials` com `if: always()` deleta `.keys/trocado.jks` e `.keys/play-sa.json` no fim da run (success ou failure).

**Rationale**: o runner é descartado depois da run no GitHub Actions hosted runners — em teoria nada persiste. Mas defesa em profundidade: se em algum momento mudarmos pra self-hosted ou se algum artifact accidentally capturar o diretório, melhor já ter deletado.

**Trade-off**: zero.

### 13. **Workflow lê Firebase app ID dinamicamente do `google-services.json`**

**Decisão**: step `Resolve Firebase app ID` faz `jq` no `android/app/google-services.json` filtrando por `client_info.android_client_info.package_name == "br.com.bed.trocado"`.

**Rationale**: hardcodar o app ID no workflow é frágil — se um dia regenerarmos `google-services.json` apontando pra outro projeto Firebase (rebrand, etc.), o workflow continuaria tentando upload pro app errado. Ler do `google-services.json` (single source of truth do SDK) tracking automático.

**Trade-off**: zero — `jq` é pre-installed no runner Ubuntu.

### 14. **Cache de Firebase CLI install via npm global path**

**Decisão**: step `Cache Firebase CLI install` cacheia `~/.npm`, `/usr/local/lib/node_modules/firebase-tools`, `/usr/local/bin/firebase` com key `firebase-tools-<os>-<version>`. Step `Install Firebase CLI` é skip se cache hit.

**Rationale**: `npm install -g firebase-tools` leva ~30s. Cache reduz a "restore-only" (~1s).

**Trade-off**: zero.

### 15. **Sem multi-os, sem matrix**

**Decisão**: roda só em `ubuntu-latest`. Sem matrix por OS, Flutter version, etc.

**Rationale**: Android builds em Linux são 1.5-2x mais rápidos que macOS (e macOS minutes são 10x mais caros). Matrix por Flutter version (stable + beta) adicionaria complexidade sem ROI — release sempre usa stable.

**Trade-off**: se um dia houver bug específico do Linux toolchain, dor pra debugar. Mitigação: dev local também roda Linux/macOS pra desenvolvimento; smoke compatibilidade já implícito.

### 16. **Sem teste rodado dentro da action**

**Decisão**: a action **não** roda `flutter test` antes do build.

**Rationale**: testes deveriam rodar num workflow separado (PR-trigged) antes do merge pra main. A release action assume que main já passou pelos testes. Duplicar `flutter test` aqui adiciona 1-2min sem catch real — testes que passam num PR não vão começar a falhar no commit de release.

Se um dia houver CI flaky ou os PRs sem branch protection, melhor adicionar branch protection pra "tests passed" em main do que duplicar testes na release.

**Trade-off**: se alguém push direto em main sem testar localmente, release pode falhar em runtime. Mitigado por branch protection (responsabilidade futura).

### 17. **Sem changelog automático nem release notes**

**Decisão**: workflow não gera changelog, release notes, nem nada similar. O texto "What's new" no Play Console é preenchido manualmente.

**Rationale**: gerar changelog automático bom exige convenção de commit (Conventional Commits, etc.) que o Trocado não segue (commits usam gitmoji). Tentar parsear gitmoji vira lógica frágil. Texto bom de release é curado humano — automação aqui geraria ruído.

**Trade-off**: 30 segundos extras de operador no Play Console. Aceitável.

### 18. **Cleanup do `version.properties`** — remover legacy `trocado.versionName` e `trocado.versionCode`

**Decisão**: remover essas duas linhas do `version.properties` durante a refactor.

**Rationale**: ficam órfãs após o build.gradle.kts não lê mais elas. Manter geraria pegadinha futura ("posso bumpar aqui?"). Remover força a clareza: "versão vive em pubspec".

**Trade-off**: zero.
