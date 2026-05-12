# Proposal — android-release-action

## Why

Hoje pra publicar uma versão release do Trocado, o fluxo é manual e frágil:

1. **Versão duplicada** entre `pubspec.yaml` (`version: 1.0.0+1`) e `android/version.properties` (`trocado.versionName=1.0.0`, `trocado.versionCode=1`). Bumps assíncronos viram discrepância silenciosa entre Dart e Android nativo.
2. **Build local** — `flutter build appbundle` rodado na máquina pessoal com keystore em path absoluto (`/home/bed/Documentos/Code/keys/trocado.jks`). Não-reprodutível entre máquinas; quebra qualquer outra origem que tente buildar (CI, outro dev, etc.).
3. **Upload manual no Play Console** — humano arrasta o AAB pra UI a cada release.
4. **Sem upload de símbolos pro Crashlytics** — crashes em release (Dart obfuscado + libapp.so) chegam ao painel como hex addresses sem mapeamento pra `file:line`. Primeira reclamação real de usuário em produção fica sem stack trace decifrável.
5. **Sem tag git nem rastreio** — não dá pra responder "qual commit foi essa versão" sem arqueologia.

Esta change introduz uma **GitHub Action `Android release`** disparada manualmente (`workflow_dispatch`) que:

1. Lê versão de `pubspec.yaml` (single source of truth).
2. Valida secrets pré-flight (falha rápido se faltar algum).
3. Build assinado **reproduzível** em runner Ubuntu (Java 17, Flutter stable, NDK 29 pinado via `version.properties`).
4. Upload de símbolos Dart pro Crashlytics via Firebase CLI.
5. Upload do AAB pro Play Console em track `internal` com status `draft` (rollout exige clique humano no Console — gate intencional).
6. Tag `vX.Y.Z+N` no commit que shipou, **só se** o upload no Play succeed.

**iOS App Store release fica fora desta change** — Fastlane / xcrun altool / dSYM upload são fluxo bem diferente e mereceriam spec própria.

## What

### Pré-requisito manual (Parte 1 — executado pelo operador antes da implementação)

Esses passos exigem acesso a contas Google externas e geração de credenciais — não dá pra automatizar via texto.

1. **Keystore release** — se ainda não tem, gerar e converter pra base64:

   ```bash
   keytool -genkeypair -alias trocado -keystore trocado.jks \
     -keyalg RSA -keysize 4096 -validity 25000
   base64 -i trocado.jks | tr -d '\n' > trocado.jks.base64
   ```

   Anotar `alias`, `keypass`, `storepass`. Guardar o `.jks` em local seguro fora do repo (não commitar; já gitignored via `.keys/`).

2. **Firebase service account** (pro upload de símbolos do Crashlytics):
   - `console.firebase.google.com → Trocado → Project Settings → Service accounts → Generate new private key`.
   - O JSON baixado tem **Firebase Admin SDK** por padrão; basta pra Crashlytics symbol upload.

3. **Play Console service account** (pro upload do AAB):
   - `play.google.com/console → Setup → API access → Create new service account` (redireciona pra Google Cloud Console).
   - Permission: **"Liberar apps para as faixas de teste"** na app Trocado.
   - Baixar JSON do service account.

   Pode reaproveitar o mesmo service account pros dois (Firebase + Play). Basta dar Firebase Admin SDK + Play Console "Liberar apps". Simplifica pra 1 secret no GitHub. **Default recomendado**.

4. **App no Play Console** — criar a app `br.com.bed.trocado` se ainda não existe. Pode ser necessário um upload manual inicial do APK pra desbloquear o track `internal` (a API só aceita uploads após a primeira release de "qualquer jeito").

5. **GitHub Secrets** — `Settings → Secrets and variables → Actions → New repository secret`. Adicionar:

   | Secret name | Valor | Origem |
   |---|---|---|
   | `TROCADO_KEYSTORE_BASE64` | conteúdo do `trocado.jks.base64` (uma linha sem `\n`) | passo 1 |
   | `TROCADO_KEY_ALIAS` | alias do keystore | passo 1 |
   | `TROCADO_KEY_PASSWORD` | senha da key | passo 1 |
   | `TROCADO_STORE_PASSWORD` | senha do keystore | passo 1 |
   | `PLAY_SERVICE_ACCOUNT_JSON` | JSON inteiro (multiline OK) | passo 2/3 (mesmo arquivo se for SA único) |
   | `BASE_URL` | URL do backend prod (ex: `https://api.trocado.com.br`) | manual |

6. **App Check release attestation** (pós primeiro release):
   - Extrair SHA-256 do keystore: `keytool -list -v -keystore trocado.jks | grep SHA256`.
   - `console.firebase.google.com → Trocado → App Check → trocado (android) → Registrar → Play Integrity → cola SHA-256`.

   Sem isso, builds release não conseguem obter token App Check válido em produção e o backend (quando ligar enforcement) vai rejeitar todos os requests.

### Parte 2 — Implementação atômica

#### Refactor `android/app/build.gradle.kts`

Hoje o build lê versão de `android/version.properties` (`trocado.versionName=1.0.0`, `trocado.versionCode=1`), o que duplica `pubspec.yaml` (`version: 1.0.0+1`). Migrar pra **single source of truth = pubspec**.

Mudanças:
- **Remover** do `defaultConfig`:
  ```kotlin
  versionName = flutterVersionName
  versionCode = flutterVersionCode
  ```
- **Remover** as leituras correspondentes:
  ```kotlin
  val flutterVersionName: String? = localProperties.getProperty("trocado.versionName")
  val flutterVersionCode: Int? = localProperties.getProperty("trocado.versionCode")?.toInt()
  ```
- **Manter** `flutterMinSdk`, `flutterNdkVersion`, `flutterAndroidSkd` lidos de `version.properties` (essas não estão no pubspec e fazem sentido como pin de toolchain).

Resultado: `flutter build appbundle` passa a usar automaticamente o `version: X.Y.Z+N` do pubspec via Flutter Gradle plugin — convenção do framework.

**Refactor signingConfigs** — substituir path absoluto por env var + fallback relativo:

```kotlin
signingConfigs {
    create("release") {
        storeFile = file(System.getenv("TROCADO_KEYSTORE_PATH") ?: "../../.keys/trocado.jks")
        keyAlias = System.getenv("TROCADO_KEY_ALIAS")
        keyPassword = System.getenv("TROCADO_KEY_PASSWORD")
        storePassword = System.getenv("TROCADO_STORE_PASSWORD")
    }
}
```

- CI: workflow decodifica o base64 pra `<repo>/.keys/trocado.jks` e exporta `TROCADO_KEYSTORE_PATH=$PWD/.keys/trocado.jks` (ou usa o fallback). Env vars de senha/alias vêm dos secrets.
- Dev local: coloca o `trocado.jks` em `<repo>/.keys/` (já gitignored), exporta as 3 env vars (`TROCADO_KEY_ALIAS`, `TROCADO_KEY_PASSWORD`, `TROCADO_STORE_PASSWORD`) no shell, roda `flutter build appbundle --release`. Funciona sem env var de path (fallback resolve relativo a `android/app/`).

#### `android/version.properties`

Estado atual:
```
trocado.minSdk=30
trocado.versionCode=1
trocado.versionName=1.0.0
trocado.androidSdkVersion=36
trocado.ndkVersion=29.0.14206865
```

Estado novo (remove version*):
```
trocado.minSdk=30
trocado.androidSdkVersion=36
trocado.ndkVersion=29.0.14206865
```

#### Workflow `.github/workflows/android-release.yml`

Estrutura adaptada da referência RacquetMind, com ajustes específicos do Trocado:

- **Trigger**: `workflow_dispatch` (manual). Nada automático em push/PR pra não publicar acidentalmente.
- **Permissions**: `contents: write` — só pra push da tag depois do upload no Play succeed.
- **Concurrency**: nenhuma (releases são raras, não vale conflict).
- **Steps em ordem**:
  1. Checkout main (fetch-depth 0 pra tag).
  2. Record start time (pra summary final).
  3. Parse version de `pubspec.yaml` (regex `^version: X.Y.Z+N$`, falha fast se malformado).
  4. Validar 6 secrets pré-flight (lista no script; falha fast).
  5. Setup Java 17 (Temurin), Flutter stable, Gradle cache, Accept Android SDK licenses, NDK cache (com key pelo `trocado.ndkVersion`).
  6. Decodificar keystore do base64 pra `.keys/trocado.jks` + sanity check via `keytool -list`.
  7. `flutter pub get`.
  8. Cache Firebase CLI install (npm global) + install se cache miss + `firebase --version` pra sanity.
  9. Escrever JSON do service account em `.keys/play-sa.json` + exportar `GOOGLE_APPLICATION_CREDENTIALS`.
  10. Resolver Firebase app ID do `android/app/google-services.json` via `jq` (filtra por package `br.com.bed.trocado`).
  11. **Build AAB**:
     ```bash
     export TROCADO_KEYSTORE_PATH=$PWD/.keys/trocado.jks
     flutter build appbundle --release \
       --obfuscate \
       --split-debug-info=build/symbols \
       --dart-define=BASE_URL=$BASE_URL
     ```
  12. Upload símbolos Dart pro Crashlytics: `firebase crashlytics:symbols:upload --app="$FIREBASE_APP_ID" build/symbols` (com `continue-on-error: true` pra não bloquear a release por blip transiente — warning explícito no summary se falhar).
  13. Upload AAB + symbols como artifacts (retenção 30d AAB, 90d symbols).
  14. **Upload pro Play Console** via `r0adkll/upload-google-play@v1.1.5` — track `internal`, status `draft`, mappingFile do ProGuard.
  15. Tag `vX.Y.Z+N` no commit — só roda se passos anteriores succeed (sem if explícito, jobs param em fail). Skip se tag já existe (idempotente em re-dispatches).
  16. Cleanup credentials (`.keys/*.jks`, `.keys/play-sa.json`) — `if: always()`.
  17. Summary markdown no `$GITHUB_STEP_SUMMARY` com versão, AAB size, build duration, total runtime, Crashlytics outcome, próximo passo no Play Console.

#### `CLAUDE.md` — nova seção `## Releases`

Documentar:
- Como bumpar versão (PR pra mudar `pubspec.yaml` antes do dispatch).
- Como disparar o workflow (`gh workflow run android-release.yml` ou via UI).
- Como rollout no Play Console depois que a action sobe o draft.
- Lembrete que iOS release ainda é manual (até virar spec).

## Scope

### Em escopo
- `.github/workflows/android-release.yml` com pipeline completa.
- Refactor `android/app/build.gradle.kts` — remove version* do defaultConfig, signing release com env vars.
- Refactor `android/version.properties` — remove version*.
- `CLAUDE.md` seção `## Releases`.
- Documentação dos pré-requisitos manuais em `tasks.md`.

### Fora de escopo (futuras changes)
- **iOS App Store release** — Fastlane / xcrun altool / dSYM upload. Spec separada.
- **Promoção automática internal → beta → production** — gate humano no Play Console é intencional.
- **Notas de release / changelog automático** — texto do "What's new" é manual no Play Console.
- **Notificação Slack / email / Discord** post-release — sem integração.
- **Multi-flavor builds no CI** — Trocado é production-only (decidido nesta sessão).
- **Build de desenvolvimento via CI** — só release. Dev local continua manual.
- **PR-based version bump automation** — bump do pubspec é PR humano antes do dispatch; não há bot.
- **Cache global pelo `setup-gradle` em PRs** — esta action é só dispatch manual, não roda em PR.
- **Backend mock no CI pra testes E2E** — testes E2E nem existem ainda; a action só compila + sobe.
