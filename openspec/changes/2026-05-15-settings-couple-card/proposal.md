# Proposal: settings-couple-card

## Intenção

Na `SettingsScreen`, a seção "Casal" hoje mostra **sempre** o card `SettingsInvitePartnerWidget` ("Convidar parceiro · Comecem a usar juntos"), mesmo quando o user já está em casal. Esta spec adiciona consulta ao endpoint `GET /api/v1/couple` e renderiza condicionalmente:

- **Fora de casal** (404 `not_in_couple`) → card de convite atual (mantém comportamento).
- **Em casal** (200) → novo `SettingsCoupleConnectedWidget`: par de avatares sobrepostos (eu + parceiro), título `"<meu nome> & <nome do parceiro>"`, subtítulo `"Conectados há <tempo relativo>"`, chevron à direita.

## Motivação

User com casal ativo vê hoje uma CTA inválida ("Convidar parceiro") — o backend rejeita o `POST /api/v1/couple/invites` com `400` ("já está em casal"), mas a UI nunca evita o caminho. Pior: não há affordance visual de que o casal existe dentro do app. O screenshot de referência fornecido pelo user mostra o padrão desejado: avatares sobrepostos + "Gabriel & Marina · Conectados há 4 meses".

Backend já entrega `GET /api/v1/couple` ([[Trocado/BackEnd/03 - API Endpoints]]). Cliente só consome — não há nada novo a especificar do lado servidor.

## Camadas afetadas

- `domain/models/couple/` — novo `CoupleModel`.
- `domain/repositories/` — `ICoupleRepository.findActive()`.
- `domain/services/` — `IDateFormatterService.formatRelativePast(int millis)` (novo método na interface).
- `infrastructure/clients/http/endpoint_key.dart` — novo `couple` (path `/api/v1/couple`).
- `infrastructure/clients/http/responses/failure/failure_code_response.dart` — novo enum value `notInCouple('not_in_couple')`.
- `infrastructure/clients/http/responses/couple/` — novo `couple_response.dart`.
- `infrastructure/datasources/remote/remote_couple_data_source.dart` — `findActive()` na interface + impl.
- `infrastructure/services/date_formatter_service.dart` — implementação de `formatRelativePast`.
- `data/extensions/` — novo `couple_response_extension.dart`; ajustar `failure_response_extension.dart` pra mapear `notInCouple` → `NotFoundFailure`.
- `data/repositories/couple_repository.dart` — `findActive()` forward.
- `presentation/ui/settings/notifiers/` — novo `couple_notifier.dart` (AsyncNotifier expondo `Future<CoupleModel?>`). Fica em `settings/` porque é a única consumer; promove se outra feature precisar.
- `presentation/ui/settings/data/` — novo `couple_card_presentation_data.dart` com `coupleTitle`, `connectedSubtitle` já formatados.
- `presentation/ui/settings/widgets/` — novo `settings_couple_connected_widget.dart`, novo `settings_couple_status_widget.dart` (orquestrador que decide qual card mostrar baseado no provider).
- `presentation/ui/settings/screens/settings_screen.dart` — substitui `SettingsInvitePartnerWidget` pelo `SettingsCoupleStatusWidget`; novo callback `onCoupleDetails`.
- `presentation/ui/settings/locations/settings_location.dart` — wiring do `onCoupleDetails` (no-op por enquanto; ver "Fora do escopo").
- `presentation/widgets/avatar/` — novo `avatar_pair_widget.dart` (par de avatares sobrepostos, reutilizável).
- `main/providers/` — sem mudanças (providers já existem; o novo `coupleNotifier` é `@riverpod` na própria feature).

## Fora do escopo

- **Tela de detalhes do casal** (destino do `onCoupleDetails`). O callback existe e é cabeado no `SettingsLocation`, mas aponta pra `() {}` no-op. Spec separada vai definir o que essa tela mostra (dissolver casal, ver parceiro, etc.). O tap no card connected fica sem efeito visível nessa entrega — aceitamos isso por ora porque o ganho da spec atual já é mostrar o estado correto.
- **Dissolver casal** (`DELETE /api/v1/couple`).
- **Invalidação cross-feature** após dissolver casal ou aceitar convite — entra na spec do `partner-invite-accept` (que ainda não existe). Por ora, o `coupleNotifier` é refrescado via pull-to-refresh manual / re-entrada na screen / restart do app. Não há uma mutação client-side hoje que altere o status de casal (o `POST invite` só **gera** convite, não cria casal — quem cria casal é o `POST /api/v1/invites/{code}/accept` que ainda não é consumido pelo app).
- **Caching agressivo do estado de casal** além do que o `@Riverpod(keepAlive: true)` já oferece. O backend cacheia 60min em Redis; cliente confia no servidor.
- **Empty state distinto pra falha de rede / outros erros**. Se o GET falhar com algo diferente de `NotFoundFailure`, caímos no card de convite (state ambíguo). Aceitável porque a settings screen não é caminho crítico e o card de convite é o default histórico.
- **Skeleton enquanto carrega**. Enquanto `AsyncLoading`, mostra o card de convite (default). Trocar pra skeleton dá flicker desnecessário quando o user já está em casal — o "verdadeiro" é detectado em ~1 frame, e o card connected substitui sem animação.
- **Foto de perfil / upload de avatar**. Avatar continua sendo as iniciais coloridas (`AvatarWidget`). Spec separada quando upload for adicionado.
- **Localização** do "há X meses". Hardcoded em `pt_BR`. Projeto inteiro hoje é só `pt_BR`.

## Decisões de design

1. **`coupleNotifier` retorna `Future<CoupleModel?>` — null = fora de casal.**
   Outras opções avaliadas: (a) lançar `NotFoundFailure` e tratar via `AsyncError`; (b) sealed class `CoupleStatus { connected(model), disconnected, loading }`. Optei por `null`: `not_in_couple` é estado de negócio normal (não erro), e `AsyncValue<CoupleModel?>` já carrega o "loading" e "error" semânticos do Riverpod. Sealed class seria overkill com só 2 estados business + 2 estados infra que o `AsyncValue` resolve.

2. **Falha não-`NotFoundFailure` cai no card de convite.**
   Mesmo tratamento de "fora de casal". Justificativa: settings não é blocker; mostrar o card de convite quando a rede está offline é menos ruim que mostrar erro inline. Quando voltar online, o `keepAlive` força refetch na próxima leitura (não, esperando — vamos sempre tentar refetch). Decisão simples: `data.fold((failure) => failure is NotFoundFailure ? null : null, (couple) => couple)`. Equivalente a `data.right ?? null`.

3. **`not_in_couple` é um code novo no `FailureCodeResponse` — mapeia pra `NotFoundFailure`.**
   Backend retorna `{ errors: [{ field: null, message, code: "not_in_couple" }] }` (HTTP `403` ou `404` — o `code` é o canal canônico, status code é detalhe; ver [[Trocado/BackEnd/04 - Security]] §7). Enum hoje só conhece `not_found`/`server_error`/`network_error`/`unknown`, então sem ajuste o code cairia em `ValidationFailure(message)` — funcional mas semanticamente errado. Adicionar `notInCouple('not_in_couple')` ao enum e mapear no `FailureResponseExtension` pra `NotFoundFailure` deixa a intenção clara e reaproveita o tipo de falha existente. Não criamos um `NotInCoupleFailure` novo — overkill por ora; `NotFoundFailure` carrega o sinal correto pro `CoupleNotifier`.

4. **Avatares sobrepostos como widget reutilizável.**
   `AvatarPairWidget` em `presentation/widgets/avatar/` recebe `firstName`/`secondName` e tamanhos. Justificativa: par sobreposto é UI padrão (vai aparecer em outras telas — `BudgetsSharedCard`, header da home no modo casal, futuro detalhe de casal). Promover desde já evita duplicar quando essas screens chegarem. Nome bate com o existente `AvatarWidget` (família `avatar/`).

5. **Cores dos dois avatares: primary com alphas diferentes.**
   Primeiro avatar (`me`) usa `primary.withAlpha(0.4)` (mais claro), segundo (`partner`) usa `primary` cheio. Reaproveita o `AvatarWidget` existente — vai precisar de um param `backgroundOpacity` ou `color` override. Pra não inflar a API do `AvatarWidget`, o `AvatarPairWidget` constrói os dois `Container`s direto seguindo o estilo do `AvatarWidget` (mesma fonte, mesmo radius, mesma lógica de inicial), sem repropagar tudo. Trade-off: ~30 linhas duplicadas pra evitar acoplar `AvatarWidget` a uma API que só faz sentido em par.

6. **Tamanho dos avatares no card: 40px com 16px de overlap.**
   Card do `IconCardWidget` é compacto — o slot do ícone tem ~40px. Manter na mesma altura visual.

7. **Subtítulo "Conectados há X" via `IDateFormatterService.formatRelativePast`.**
   Novo método no service. Implementação calcula `diff` entre `now()` e o `createdAt`, retorna:
   - `< 7 dias` → `"alguns dias"`
   - `< 30 dias` → `"X semana[s]"`
   - `< 365 dias` → `"X mês/meses"`
   - `>= 365 dias` → `"X ano[s]"`

   Concatenação `"Conectados há $relativo"` é feita no presentation data, não no service — service só formata o trecho relativo. Esse método é puro (dado `int` → `String`), entra em `IDateFormatterService` mesmo (em vez de helper local) porque já é o lugar canônico do projeto pra formatação de data.

8. **`CoupleNotifier` em `presentation/ui/settings/notifiers/`.**
   Não promover pra `presentation/notifiers/` ainda. Único consumer é a Settings — quando uma segunda feature ler casal (ex: home sabendo se deve mostrar visão shared), promove e move o arquivo. YAGNI por ora.

9. **`SettingsCoupleStatusWidget` decide o switch.**
   A Settings screen continua agnóstica — passa só o callback `onCoupleDetails` e o `onInvitePartner`; o widget consome o provider e renderiza um dos dois cards. Mantém a screen "burra" e o switch testável isoladamente. Alternativa rejeitada: fazer o switch dentro do `SettingsScreen._buildCouple`. Faria a screen ler o provider, contradiz convenção do projeto (notifier é a porta — exceto por providers de leitura simples diretamente em widgets compartilhados é OK).

10. **`SettingsCoupleStatusWidget` lê o provider direto.**
    Exceção justificada à regra "screens nunca leem provider de service": é um widget de feature, não screen, e o provider em questão **não** é de service — é o `coupleNotifier` (state). Equivalente ao padrão de `Consumer`-via-widget em outros lugares (`HomeAppBarWidget` lê `userProvider`, `PartnerPairIndicatorWidget` recebe `userState` externamente — esse último é o padrão "inverter o controle" mas exige a screen carregar o state). Aqui o widget é puro o suficiente.

11. **Naming: `SettingsCoupleConnectedWidget` vs `SettingsCoupleCardWidget`.**
    Optei por `Connected` no nome pra reforçar a semântica: é o card que aparece quando o casal **existe**. `SettingsInvitePartnerWidget` (que já existe) tem o naming espelho na semântica "fazer convite". Ambos vivem em `ui/settings/widgets/`.

12. **`onCoupleDetails` no callback set do `SettingsScreen`.**
    Mesma assinatura `VoidCallback` que os outros callbacks. `SettingsLocation` injeta `() {}` placeholder. Quando a tela de detalhes de casal entrar, é um diff de uma linha.
