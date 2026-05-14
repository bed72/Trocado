# Proposal: generate-couple-invite-qr-code

> Spec filha de `2026-05-13-partner-invite-screen` (Adendo 1). A spec pai deixou o callback `onGenerate` do `PartnerInviteActionsWidget` como `() {}` stub esperando o wiring real. Esta spec resolve esse callback: ao tocar em "Gerar QR code" o app gera um convite no backend e abre uma tela dedicada com o QR + botão de compartilhar.

## Intenção

Implementar o fluxo **gerar convite de casal**:

1. Ao tocar em "Gerar QR code" na `PartnerInviteScreen`, navegar para uma nova `InviteQrCodeScreen`.
2. A `InviteQrCodeScreen`, ao montar, chama `POST /api/v1/couple/invites` (sem body) e renderiza o QR code do `qr_data` retornado.
3. Abaixo do QR: o código curto (ex: `A3K7FN`), a expiração formatada, e um botão "Compartilhar" que abre o share sheet nativo com o link do convite.

A spec **não cobre** o lado oposto do fluxo (scanear, deep link de aceite, accept endpoint, visualizar/desfazer casal). Cada um vira sua própria spec.

## Motivação

A `PartnerInviteScreen` (Adendo 1 da spec pai) entregou o layout com 2 CTAs renomeados pelo user pra "Scanear QR code" (primary) e "Gerar QR code" (secondary). Os callbacks são `() {}` stubs. Sem essa spec, o botão "Gerar QR code" não faz nada — bloqueia o teste do fluxo do convidador.

Gerar é o caminho **mais simples** dos dois (sem permissão de câmera, sem deep link handler, sem decode), por isso entra primeiro. Scanear vira spec separada.

## Relação com a spec pai

- A spec pai (`2026-05-13-partner-invite-screen`) declara: *"Os `VoidCallback`s passados ao `PartnerInviteActionsWidget` SHALL ser `() {}` literais nesta spec. Wiring real (clipboard, navegação, endpoint) é responsabilidade de spec filha."*
- Esta spec é uma dessas filhas — resolve **apenas o callback `onGenerate`**. `onScan` continua `() {}` até a spec de scan/aceite.
- A `PartnerInviteLocation` ganha 1 callback novo (`onGenerate`) seguindo o mesmo padrão da `SettingsLocation` (que já injeta `onInvitePartner`, `onEditProfile`, etc.).

## Camadas afetadas

- `lib/app_route.dart` — novo entry `partnerInviteQrCode` em `AppRoutes`.
- `lib/src/infrastructure/clients/http/endpoint_key.dart` — novo entry `coupleInvites('/api/v1/couple/invites')`.
- `lib/src/domain/models/couple/` (NOVA pasta) — `InviteModel`.
- `lib/src/domain/repositories/` — `interface_couple_repository.dart` com `createInvite()`.
- `lib/src/infrastructure/clients/http/responses/couple/` (NOVA pasta) — `InviteResponse`.
- `lib/src/infrastructure/clients/share/` (NOVA pasta) — `IShareClient` + `ShareClient` (wrapper de `share_plus`).
- `lib/src/infrastructure/datasources/remote/` — `RemoteCoupleDataSource` com `createInvite()`.
- `lib/src/data/extensions/` — `invite_response_extension.dart` (`toModel()`).
- `lib/src/data/repositories/` — `CoupleRepository` com `createInvite()`.
- `lib/src/presentation/ui/partner/` — `notifiers/` (NOVA pasta), `data/` (NOVA pasta), screen nova, location nova, widget novo (`InviteQrCardWidget`).
- `lib/src/presentation/ui/partner/screens/partner_invite_screen.dart` — recebe `onGenerate` no construtor, encaminha pro `PartnerInviteActionsWidget`.
- `lib/src/presentation/ui/partner/locations/partner_invite_location.dart` — passa `onGenerate: () => context.navigate(InviteQrCodeLocation())`.
- `lib/src/main/providers/clients_provider.dart` — `shareClientProvider`.
- `lib/src/main/providers/data_sources.provider.dart` — `remoteCoupleDataSourceProvider`.
- `lib/src/main/providers/repositories_provider.dart` — `coupleRepositoryProvider`.
- `pubspec.yaml` — adicionar `pretty_qr_code: ^3.6.0` e `share_plus: ^11.0.0`.

## Fora do escopo

- **Scanear QR code** — o callback `onScan` continua `() {}`. Vira spec dedicada (precisa de `mobile_scanner` + permissão de câmera + tela de confirmação + accept endpoint).
- **Deep link `trocado://invite/{code}`** — handler de deep link, parsing do code, navegação pra confirmação. Vira spec dedicada (encavalada com Universal Links/App Links).
- **Aceitar convite** (`POST /invites/{code}/accept`) — sem tela de confirmação, sem state, sem endpoint integrado.
- **Visualizar casal** (`GET /couple`) — mostrar parceiro vinculado nas Settings. Vira spec dedicada.
- **Desfazer casal** (`DELETE /couple`) — vira spec dedicada.
- **Universal Links / App Links / fallback web** — domínio + arquivos de associação + página de fallback. Trabalho de infra; spec separada quando o domínio estiver pronto.
- **Regenerar convite na mesma tela** — botão "Gerar outro" / "Atualizar QR". Por ora cada abertura da tela gera 1 convite novo; user fecha e reabre se quiser outro.
- **Copiar código** — botão dedicado pra `Clipboard.setData(text: code)`. O share sheet já cobre o caso de uso. Adicionar depois se virar feedback recorrente.
- **Compartilhar o QR como imagem** (PNG anexado no share) — share só do texto/link por ora. Pode evoluir depois.
- **Empty state do invite ativo** — se o backend já tiver um convite válido aberto, o POST pode (ou não) reutilizar. Tratamos a resposta como qualquer outra — não há lógica especial cliente-side de "convite já existe".
- **Tela de "casal já vinculado"** — se o user já tem parceiro, o backend retorna erro no POST. Mostramos o erro padrão (`ValidationFailure.message`) na failure state. Não há roteamento condicional cliente-side.
- **Animação/transição customizada** entre `PartnerInviteScreen` e `InviteQrCodeScreen` — page transition default do `duck_router`.

## Decisões de design

1. **`AsyncNotifier` com POST no `build()`, sem MVI.**
   O fluxo é puramente "carregar → exibir → compartilhar". Sem form, sem input do user. Segue o padrão da `SplashNotifier` (`Future<T> build()` com chamada de repositório). MVI seria peso desnecessário — o CLAUDE.md reserva MVI pra "formulários e state", não pra fluxos display-only.

   Métodos diretos no notifier:
   - `share()` → chama `IShareClient.shareText(qrData)` (não muda state).
   - `retry()` → re-executa `_create()` resetando pra `AsyncLoading` + novo `AsyncData`/`AsyncError`.

2. **Cada abertura da tela gera um convite novo.**
   `build()` chama POST. Se o user volta e entra de novo, novo POST → novo código. Não cacheamos. Justificativa: o backend é a fonte da verdade do estado do convite (com expiração). Cachear no cliente complicaria UX ("será que esse código ainda é válido?"). Custo de 1 POST extra é irrelevante.

   Consequência: NÃO usar `keepAlive: true` no provider. Provider some quando a tela desmonta; próximo monte = novo POST.

3. **`InviteModel` em `domain/models/couple/` (família nova).**
   `couple/` é a família. `InviteModel` representa o convite gerado. Futuramente `couple/` ganha `CoupleModel` (pra `GET /couple`) — não criamos agora pra não inflar escopo.

4. **`ICoupleRepository` (uma só), não `ICoupleInviteRepository`.**
   Segue o padrão de `INotificationRepository`, `IBudgetRepository`, `IExpenseRepository` — um repositório por **família de recurso**. Nesta spec adicionamos só `createInvite()`. Specs futuras adicionam `find()`, `delete()`, `acceptInvite(code)`. Evita criar 2 repos e fundir depois.

5. **`expires_at` ISO 8601 → `int` ms epoch no `InviteModel`.**
   Padrão do projeto (mesmo de `ExpenseModel.createdAt`, `NotificationModel.createdAt`). Conversão em `InviteResponseExtension.toModel()` via `DateTime.parse(expiresAt).millisecondsSinceEpoch`.

6. **`pretty_qr_code` como lib de QR.**
   Decisão alinhada antes da spec: `qr_flutter` está parado (3 anos sem update); `qr` puro exigiria `CustomPainter` próprio; `pretty_qr_code` usa `qr` por baixo, é mantida ativamente, entrega o widget pronto com shapes/embedded image. Justificativa completa no chat.

7. **`share_plus` como lib de share, atrás de um `IShareClient`.**
   Wrapper em `infrastructure/clients/share/` espelha o tratamento dado a outras APIs nativas (ex: `IMessagingClient` pra FCM). Permite mockar nos testes do notifier sem chamar a API nativa. Interface mínima — só `Future<void> shareText(String text)`.

8. **Texto compartilhado é simples e estático.**
   `'Vamos juntar nossas finanças no Trocado! Aceite meu convite: $qrData'`. Não é configurável, não é A/B testado, não é por feature flag. Se virar parâmetro depois, promovemos.

9. **`InviteQrCardWidget` extrai o "core visual" — QR + código + expiração.**
   Widget filho da `InviteQrCodeScreen` que recebe o `InviteQrCodePresentationData` e renderiza. Mantém a screen leve (só switch de `AsyncValue`). Não há reuso fora da feature por ora — vive em `presentation/ui/partner/widgets/`.

10. **`InviteQrCodePresentationData` em `presentation/ui/partner/data/`.**
    View-model com `qrData`, `code`, `formattedExpiration` (string já formatada). Notifier injeta `IDateFormatterService` no `build()` e produz esse VM. Screen NUNCA lê `dateFormatterServiceProvider` direto (regra do CLAUDE.md).

11. **Botão "Compartilhar" full-width, único CTA.**
    `ButtonWidget.elevated` com ícone `Icons.share` + label "Compartilhar". Disabled em loading/error. Não há "tentar de novo" inline na success state — só na error state.

12. **Header padrão do projeto.**
    `ScaffoldWidget` + `AppBarWidget(leading: GoBackWidget())` + `ScreenHeaderWidget(title: 'Convite', description: 'Mostre o QR code para seu par escanear.')`. Sem novidade visual.

13. **Loading via `Skeletonizer` no card do QR.**
    Mesma técnica do `PartnerPairIndicatorWidget` da spec pai. O `Skeletonizer` envolve o `InviteQrCardWidget` com dados placeholder.

14. **Erro mostra ícone + mensagem + botão "Tentar novamente".**
    Pattern compartilhado com `NotificationsFailureWidget` da `notifications-list`. Mas como esse erro é específico de uma tela só, criamos `InviteQrCodeFailureWidget` local na feature por ora — se outras telas precisarem do mesmo visual, promovemos pra `presentation/widgets/`.

15. **Sem testes de widget.**
    Projeto não tem widget tests pra esse role. Cobertura é em response/extension/repository/notifier (unit).
