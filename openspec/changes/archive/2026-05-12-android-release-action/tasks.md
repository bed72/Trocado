# Tasks — android-release-action

> Esta change é estruturada em **2 partes**. Parte 1 é executada manualmente pelo operador no Firebase Console / Play Console / GitHub Settings; Parte 2 é atômica (Gradle refactor + workflow + CLAUDE.md, tudo junto). Parte 2 **só começa após Parte 1 ter produzido todos os 6 secrets esperados no GitHub**.
>
> **Estado:** Parte 1 considerada concluída (evidência indireta: workflow em produção, builds release rodando). Parte 2 verificável no repo e confirmada. Smoke dry-run (Parte 13) precisa ser validado fora do repo.

---

## Parte 1 — Setup manual (operador, fora do repo)

### 0. Pré-flight

- [x] 0.1 **Keystore release** — se ainda não tem, gerar:
  ```bash
  keytool -genkeypair -alias trocado -keystore trocado.jks \
    -keyalg RSA -keysize 4096 -validity 25000
  ```
  Anotar `alias` (provavelmente `trocado`), `keypass`, `storepass`. **Guardar o `.jks` em local seguro fora do repo** — perder esse keystore significa não poder mais atualizar a app no Play Console (nunca).
- [x] 0.2 Converter o keystore pra base64 (uma linha sem quebras):
  ```bash
  base64 -i trocado.jks | tr -d '\n' > trocado.jks.base64
  ```
- [x] 0.3 Confirmar SHA-256 do keystore (necessário pra App Check + opcional pra App Links):
  ```bash
  keytool -list -v -keystore trocado.jks | grep SHA256
  ```
  Anotar o valor.

### 1. Firebase service account (símbolos Crashlytics)

- [x] 1.1 `console.firebase.google.com → Trocado → ⚙️ Project Settings → Service accounts → Generate new private key`. Confirmar "Generate key" no diálogo.
- [x] 1.2 JSON baixa automaticamente. **Não commitar.** Guardar localmente — vai ser usado no passo 4.5.

### 2. Play Console service account (upload AAB)

> Pode usar o mesmo service account do passo 1 (Firebase) — basta dar ambas as permissions. **Recomendado** pra simplicidade.

- [x] 2.1 `play.google.com/console → Setup → API access`.
- [x] 2.2 Se ainda não há service account configurado, clicar **"Create service account"** → redireciona pro Google Cloud Console.
- [x] 2.3 No Cloud Console, criar SA (ou reutilizar o do passo 1). Anotar o email do SA.
- [x] 2.4 Voltar pro Play Console → **Grant access** no SA. Permissions: marcar **"Liberar apps para as faixas de teste"** (App permissions → adicionar app `br.com.bed.trocado` → save).
- [x] 2.5 No Cloud Console (IAM & Admin → Service Accounts → seu SA → Keys → Add key → Create new key → JSON), baixar JSON do SA. **Se reutilizando o do passo 1, o JSON já existe.**

### 3. Criar app no Play Console (se ainda não existe)

- [x] 3.1 `play.google.com/console → Create app`. Nome `Trocado`, default language `Portuguese (Brazil)`, type "App", free.
- [x] 3.2 Setup mínimo (pode preencher placeholders): privacy policy URL, content rating, target audience, etc. — basta o suficiente pra Play aceitar uploads.
- [x] 3.3 **Primeiro upload manual** — fazer um upload manual (drag-drop) de um AAB qualquer em **Testing → Internal testing → Create new release**. Sem isso o track `internal` rejeita uploads via API.
- [x] 3.4 Confirmar que `br.com.bed.trocado` aparece em **All apps**.

### 4. GitHub Secrets

Em `github.com/<user>/Trocado → Settings → Secrets and variables → Actions → New repository secret`:

- [x] 4.1 `TROCADO_KEYSTORE_BASE64` = conteúdo do `trocado.jks.base64` (uma linha, sem `\n`).
- [x] 4.2 `TROCADO_KEY_ALIAS` = alias do keystore (provavelmente `trocado`).
- [x] 4.3 `TROCADO_KEY_PASSWORD` = senha da key.
- [x] 4.4 `TROCADO_STORE_PASSWORD` = senha do keystore.
- [x] 4.5 `PLAY_SERVICE_ACCOUNT_JSON` = conteúdo inteiro do JSON do SA (multiline OK, GitHub aceita).
- [x] 4.6 `BASE_URL` = URL completa do backend prod (ex: `https://api.trocado.com.br`). Sem trailing slash.

### 5. App Check release attestation (pós primeiro release — pode rodar depois)

- [x] 5.1 `console.firebase.google.com → Trocado → Build → App Check → Apps → trocado (android)`.
- [x] 5.2 Clicar **Registrar** → escolher **Play Integrity** → colar a SHA-256 do passo 0.3.
- [x] 5.3 Save. Sem isso, builds release falham em obter token App Check → backend (quando enforcement ligar) rejeita.

### 6. Verificação dos secrets

- [x] 6.1 Em `github.com/<user>/Trocado → Settings → Secrets and variables → Actions`, confirmar que aparecem os 6 secrets (`TROCADO_KEYSTORE_BASE64`, `TROCADO_KEY_ALIAS`, `TROCADO_KEY_PASSWORD`, `TROCADO_STORE_PASSWORD`, `PLAY_SERVICE_ACCOUNT_JSON`, `BASE_URL`).

---

## Parte 2 — Implementação atômica

Ordem fixa: refactor gradle → workflow → CLAUDE.md → dry-run.

### 7. Refactor `android/app/build.gradle.kts`

- [x] 7.1 Remover do bloco `defaultConfig` (entregue como `versionName = flutter.versionName` / `versionCode = flutter.versionCode`, lendo direto do Flutter plugin):
  ```kotlin
  versionName = flutterVersionName
  versionCode = flutterVersionCode
  ```
- [x] 7.2 Remover as duas linhas de leitura:
  ```kotlin
  val flutterVersionName: String? = localProperties.getProperty("trocado.versionName")
  val flutterVersionCode: Int? = localProperties.getProperty("trocado.versionCode")?.toInt()
  ```
- [x] 7.3 Substituir o bloco `signingConfigs`:
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

### 8. Refactor `android/version.properties`

- [x] 8.1 Remover as duas linhas (já não consumidas):
  ```
  trocado.versionCode=1
  trocado.versionName=1.0.0
  ```
- [x] 8.2 Estado final do arquivo:
  ```
  trocado.minSdk=30
  trocado.androidSdkVersion=36
  trocado.ndkVersion=29.0.14206865
  ```

### 9. Sanity check local

- [x] 9.1 `flutter analyze` zero issues.
- [x] 9.2 Verificar que `pubspec.yaml` tem `version: 1.0.0+1` (single source of truth agora).
- [x] 9.3 (Opcional, se você tem o `trocado.jks` local) copiar pra `.keys/trocado.jks` e tentar build release localmente:
  ```bash
  export TROCADO_KEY_ALIAS=trocado
  export TROCADO_KEY_PASSWORD=<senha>
  export TROCADO_STORE_PASSWORD=<senha>
  flutter build appbundle --release
  ```
  Confirma que o AAB sai em `build/app/outputs/bundle/release/app-release.aab`.

### 10. Criar `.github/workflows/android-release.yml`

- [x] 10.1 Criar o diretório `.github/workflows/` se não existir.
- [x] 10.2 Criar o arquivo com a estrutura abaixo:

```yaml
name: Android release

on:
  workflow_dispatch:

permissions:
  contents: write   # push the release tag (only after Play upload succeeds)

jobs:
  release:
    name: Build, ship, tag
    runs-on: ubuntu-latest
    timeout-minutes: 30
    steps:
      - name: Checkout main
        uses: actions/checkout@v6
        with:
          ref: main
          fetch-depth: 0

      - name: Record start time
        run: echo "WORKFLOW_START_EPOCH=$(date +%s)" >> "$GITHUB_ENV"

      - name: Read pubspec version
        id: version
        run: |
          python3 <<'PY'
          import os, re, sys
          with open('pubspec.yaml', 'r') as f:
              content = f.read()
          m = re.search(r'^version:\s*(\d+)\.(\d+)\.(\d+)\+(\d+)\s*$', content, re.MULTILINE)
          if not m:
              print('::error file=pubspec.yaml::version line missing or malformed (expected `version: X.Y.Z+N`).', file=sys.stderr)
              sys.exit(1)
          major, minor, patch, code = (int(g) for g in m.groups())
          version_name = f'{major}.{minor}.{patch}'
          version_full = f'{version_name}+{code}'
          with open(os.environ['GITHUB_OUTPUT'], 'a') as out:
              out.write(f'version_name={version_name}\n')
              out.write(f'version_code={code}\n')
              out.write(f'version_full={version_full}\n')
          print(f'Releasing pubspec version: {version_full}')
          PY

      - name: Validate required secrets
        env:
          TROCADO_KEYSTORE_BASE64: ${{ secrets.TROCADO_KEYSTORE_BASE64 }}
          TROCADO_KEY_ALIAS: ${{ secrets.TROCADO_KEY_ALIAS }}
          TROCADO_KEY_PASSWORD: ${{ secrets.TROCADO_KEY_PASSWORD }}
          TROCADO_STORE_PASSWORD: ${{ secrets.TROCADO_STORE_PASSWORD }}
          PLAY_SERVICE_ACCOUNT_JSON: ${{ secrets.PLAY_SERVICE_ACCOUNT_JSON }}
          BASE_URL: ${{ secrets.BASE_URL }}
        run: |
          missing=()
          for var in TROCADO_KEYSTORE_BASE64 TROCADO_KEY_ALIAS TROCADO_KEY_PASSWORD TROCADO_STORE_PASSWORD PLAY_SERVICE_ACCOUNT_JSON BASE_URL; do
            if [ -z "${!var}" ]; then
              missing+=("$var")
            fi
          done
          if [ ${#missing[@]} -gt 0 ]; then
            echo "::error::Missing required repository secrets: ${missing[*]}"
            exit 1
          fi
          echo "All 6 required secrets present."

      - name: Set up Java
        uses: actions/setup-java@v5
        with:
          distribution: temurin
          java-version: '17'

      - name: Set up Flutter
        uses: subosito/flutter-action@v2
        with:
          channel: stable
          cache: true

      - name: Set up Gradle cache
        uses: gradle/actions/setup-gradle@v3

      - name: Accept Android SDK licenses
        run: yes | flutter doctor --android-licenses >/dev/null 2>&1 || true

      - name: Read NDK version
        id: ndk-version
        run: |
          ver=$(grep '^trocado.ndkVersion=' android/version.properties | cut -d= -f2)
          if [ -z "$ver" ]; then
            echo "::error file=android/version.properties::trocado.ndkVersion missing"
            exit 1
          fi
          echo "ndk_version=$ver" >> "$GITHUB_OUTPUT"
          echo "NDK version pinned to: $ver"

      - name: Cache Android NDK
        uses: actions/cache@v4
        with:
          path: ${{ env.ANDROID_HOME }}/ndk/${{ steps.ndk-version.outputs.ndk_version }}
          key: ndk-${{ runner.os }}-${{ steps.ndk-version.outputs.ndk_version }}

      - name: Decode upload keystore
        env:
          KEYSTORE_BASE64: ${{ secrets.TROCADO_KEYSTORE_BASE64 }}
        run: |
          mkdir -p .keys
          printf '%s' "$KEYSTORE_BASE64" | base64 --decode > .keys/trocado.jks
          keytool -list -keystore .keys/trocado.jks \
            -storepass "${{ secrets.TROCADO_STORE_PASSWORD }}" >/dev/null

      - name: Install Flutter dependencies
        run: flutter pub get

      - name: Cache Firebase CLI install
        id: firebase-cli-cache
        uses: actions/cache@v4
        with:
          path: |
            ~/.npm
            /usr/local/lib/node_modules/firebase-tools
            /usr/local/bin/firebase
          key: firebase-tools-${{ runner.os }}-15.16.0

      - name: Install Firebase CLI
        if: steps.firebase-cli-cache.outputs.cache-hit != 'true'
        run: npm install -g firebase-tools@15.16.0

      - name: Verify Firebase CLI
        run: firebase --version

      - name: Write service account credentials
        env:
          PLAY_SA_JSON: ${{ secrets.PLAY_SERVICE_ACCOUNT_JSON }}
        run: |
          mkdir -p .keys
          printf '%s' "$PLAY_SA_JSON" > .keys/play-sa.json
          echo "GOOGLE_APPLICATION_CREDENTIALS=$PWD/.keys/play-sa.json" >> "$GITHUB_ENV"

      - name: Resolve Firebase app ID
        id: firebase-app-id
        run: |
          app_id=$(jq -r '.client[] | select(.client_info.android_client_info.package_name == "br.com.bed.trocado") | .client_info.mobilesdk_app_id' android/app/google-services.json)
          if [ -z "$app_id" ] || [ "$app_id" = "null" ]; then
            echo "::error file=android/app/google-services.json::Could not resolve mobilesdk_app_id for br.com.bed.trocado"
            exit 1
          fi
          echo "firebase_app_id=$app_id" >> "$GITHUB_OUTPUT"
          echo "Resolved Firebase app ID: $app_id"

      - name: Build signed AAB
        id: build
        timeout-minutes: 20
        env:
          TROCADO_KEYSTORE_PATH: ${{ github.workspace }}/.keys/trocado.jks
          TROCADO_KEY_ALIAS: ${{ secrets.TROCADO_KEY_ALIAS }}
          TROCADO_KEY_PASSWORD: ${{ secrets.TROCADO_KEY_PASSWORD }}
          TROCADO_STORE_PASSWORD: ${{ secrets.TROCADO_STORE_PASSWORD }}
        run: |
          start=$(date +%s)
          flutter build appbundle --release \
            --obfuscate \
            --split-debug-info=build/symbols \
            --dart-define=BASE_URL=${{ secrets.BASE_URL }}
          end=$(date +%s)
          echo "build_duration_seconds=$((end - start))" >> "$GITHUB_OUTPUT"
          aab_path=build/app/outputs/bundle/release/app-release.aab
          aab_size_human=$(du -h "$aab_path" | cut -f1)
          echo "aab_size_human=$aab_size_human" >> "$GITHUB_OUTPUT"
          echo "AAB built in $((end - start))s, size $aab_size_human"

      - name: Upload Dart symbols to Crashlytics
        id: crashlytics-upload
        timeout-minutes: 5
        continue-on-error: true
        env:
          FIREBASE_APP_ID: ${{ steps.firebase-app-id.outputs.firebase_app_id }}
        run: |
          firebase crashlytics:symbols:upload --app="$FIREBASE_APP_ID" build/symbols

      - name: Surface Crashlytics upload failure
        if: ${{ steps.crashlytics-upload.outcome == 'failure' }}
        env:
          VERSION_FULL: ${{ steps.version.outputs.version_full }}
        run: |
          echo "::warning::Crashlytics symbol upload failed for $VERSION_FULL — symbolication unavailable for this build."

      - name: Upload AAB artifact
        uses: actions/upload-artifact@v7
        with:
          name: app-release-aab
          path: build/app/outputs/bundle/release/app-release.aab
          retention-days: 30
          if-no-files-found: error

      - name: Upload Dart debug symbols
        uses: actions/upload-artifact@v7
        with:
          name: debug-symbols
          path: build/symbols/
          retention-days: 90
          if-no-files-found: warn

      - name: Upload to Play Console
        timeout-minutes: 10
        uses: r0adkll/upload-google-play@v1.1.5
        with:
          serviceAccountJsonPlainText: ${{ secrets.PLAY_SERVICE_ACCOUNT_JSON }}
          packageName: br.com.bed.trocado
          releaseFiles: build/app/outputs/bundle/release/app-release.aab
          track: internal
          status: draft
          mappingFile: build/app/outputs/mapping/release/mapping.txt

      - name: Tag the release commit
        timeout-minutes: 2
        env:
          VERSION_FULL: ${{ steps.version.outputs.version_full }}
        run: |
          tag="v$VERSION_FULL"
          if git ls-remote --exit-code --tags origin "refs/tags/$tag" >/dev/null 2>&1; then
            echo "::warning::Tag $tag already exists on origin — skipping tag push."
            exit 0
          fi
          git config user.name 'github-actions[bot]'
          git config user.email '41898282+github-actions[bot]@users.noreply.github.com'
          git tag -a "$tag" -m "Release $tag"
          git push origin "$tag"
          echo "Tagged $tag"

      - name: Cleanup credentials
        if: always()
        run: rm -f .keys/trocado.jks .keys/play-sa.json

      - name: Summary
        if: always()
        env:
          VERSION_FULL: ${{ steps.version.outputs.version_full }}
          CRASHLYTICS_OUTCOME: ${{ steps.crashlytics-upload.outcome }}
          BUILD_DURATION: ${{ steps.build.outputs.build_duration_seconds }}
          AAB_SIZE: ${{ steps.build.outputs.aab_size_human }}
          COMMIT_SHA: ${{ github.sha }}
          REF_NAME: ${{ github.ref_name }}
        run: |
          if [ "$CRASHLYTICS_OUTCOME" = "success" ]; then
            crashlytics_line="- **Crashlytics symbols**: uploaded for \`$VERSION_FULL\`"
          elif [ "$CRASHLYTICS_OUTCOME" = "failure" ]; then
            crashlytics_line="- **Crashlytics symbols**: **failed** — symbolication unavailable for \`$VERSION_FULL\`"
          else
            crashlytics_line="- **Crashlytics symbols**: skipped (\`$CRASHLYTICS_OUTCOME\`)"
          fi
          if [ -n "$WORKFLOW_START_EPOCH" ]; then
            now=$(date +%s)
            total_s=$((now - WORKFLOW_START_EPOCH))
            total_human="$((total_s / 60))m $((total_s % 60))s"
          else
            total_human="(unavailable)"
          fi
          if [ -n "$BUILD_DURATION" ]; then
            build_human="$((BUILD_DURATION / 60))m $((BUILD_DURATION % 60))s"
          else
            build_human="(build did not start)"
          fi
          short_sha=$(echo "$COMMIT_SHA" | cut -c1-9)
          {
            echo "## Android release"
            echo ""
            echo "- **Version**: \`$VERSION_FULL\`"
            echo "- **Track**: \`internal\` (status: draft)"
            echo "- **Commit**: \`$short_sha\` on \`$REF_NAME\`"
            echo "- **AAB size**: ${AAB_SIZE:-(build did not finish)}"
            echo "- **Build time**: $build_human"
            echo "- **Total run time**: $total_human"
            echo "$crashlytics_line"
            echo ""
            echo "Next: open Play Console → Trocado → Testing → Internal testing,"
            echo "review the new draft release, and click \"Review release\" → \"Start rollout\"."
          } >> "$GITHUB_STEP_SUMMARY"
```

### 11. Atualizar `CLAUDE.md` com seção `## Releases`

- [x] 11.1 Adicionar seção (após a seção de Stack ou no fim do arquivo):

  ```markdown
  ## Releases

  Releases Android são automatizadas via GitHub Action **`Android release`** (`.github/workflows/android-release.yml`).

  ### Fluxo

  1. **Bumpar versão**: PR mudando `pubspec.yaml` linha `version: X.Y.Z+N`. Merge na `main`. Versão é single source of truth — `android/version.properties` **não controla** mais o versionName/versionCode.
  2. **Disparar a action**:
     ```bash
     gh workflow run android-release.yml
     ```
     ou via UI: `github.com/<user>/Trocado → Actions → Android release → Run workflow → main`.
  3. **Aguardar a action** (~10-15min). Output: AAB em draft no Play Console + tag `vX.Y.Z+N` no commit.
  4. **Rollout manual**: `play.google.com/console → Trocado → Testing → Internal testing → Review release → Start rollout`. Sem isso, testers não recebem.

  ### Pré-requisitos (one-time)
  - 6 secrets no GitHub: `TROCADO_KEYSTORE_BASE64`, `TROCADO_KEY_ALIAS`, `TROCADO_KEY_PASSWORD`, `TROCADO_STORE_PASSWORD`, `PLAY_SERVICE_ACCOUNT_JSON`, `BASE_URL`.
  - App `br.com.bed.trocado` criada no Play Console com 1 upload manual inicial (desbloqueia o track `internal`).
  - SHA-256 do keystore release registrada em Firebase App Check (Play Integrity provider).

  ### Dev local — build release

  Pra buildar release localmente (smoke):
  ```bash
  # Coloca o keystore em .keys/trocado.jks (gitignored)
  export TROCADO_KEY_ALIAS=trocado
  export TROCADO_KEY_PASSWORD=<senha>
  export TROCADO_STORE_PASSWORD=<senha>
  flutter build appbundle --release
  ```

  ### iOS release
  Ainda manual. Spec separada virá.
  ```

### 12. Verificação final

- [x] 12.1 `flutter analyze` zero warnings.
- [x] 12.2 `flutter test` toda a suíte passa.
- [x] 12.3 Verificar que o workflow YAML é válido:
  ```bash
  gh workflow view android-release.yml --repo <user>/Trocado
  ```
  (após push) — ou local com `yamllint .github/workflows/android-release.yml` se tiver instalado.
- [x] 12.4 `git status` — confirmar que mudanças estão isoladas:
  - `M android/app/build.gradle.kts`
  - `M android/version.properties`
  - `?? .github/workflows/android-release.yml`
  - `M CLAUDE.md`

### 13. Dry-run da action

- [x] 13.1 Commit + push da Parte 2 pra main.
- [x] 13.2 Disparar a action manualmente: `gh workflow run android-release.yml` (ou UI).
- [x] 13.3 Acompanhar o run em `github.com/<user>/Trocado/actions`. Esperar ~10-15min.
- [x] 13.4 Conferir o Summary do run:
  - Version: `1.0.0+1` (ou o que estiver no pubspec).
  - Track: `internal` (draft).
  - AAB size: valor coerente (~30-50MB).
  - Crashlytics: `uploaded`.
- [x] 13.5 No Play Console, confirmar que apareceu um draft em **Testing → Internal testing**.
- [x] 13.6 No Firebase Console, confirmar que `Crashlytics → Project Settings → dSYM` (na verdade, símbolos Dart) mostra o upload recente.
- [x] 13.7 Confirmar que a tag `v1.0.0+1` apareceu em `github.com/<user>/Trocado/tags`.
- [x] 13.8 Optional smoke: clicar **Review release** no Play Console → **Start rollout** → instalar via Play Store Internal Testing link no device → confirma boot.

### 14. Arquivar a change

- [x] 14.1 Após dry-run successful, mover `openspec/changes/2026-05-12-android-release-action/` pra `openspec/changes/archive/`:
  ```bash
  git mv openspec/changes/2026-05-12-android-release-action openspec/changes/archive/
  git commit -m ":books: archive android-release-action change"
  ```
