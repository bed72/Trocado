# Proposal: couple-invite-scan-flow-fix

## Intenção

Corrigir bugs do fluxo de aceitar convite de casal por QR/código manual, descobertos em runtime após `2026-05-21-couple-scan-qr-code`. Três correções dependentes:

1. **Parse do deep link no scan.** O QR carrega `trocado://invite/<code>` (campo `qr_data` retornado pela API e usado também no botão de compartilhar). O scanner antes mandava o valor cru pro endpoint, gerando `GET /api/v1/couple/invites/trocado://invite/36APAY` → 404. **Fix parcial já aplicado** em `lib/src/presentation/ui/couple/scan/notifiers/couple_scan_notifier.dart` (método `_parseCode` via `Uri.tryParse`); esta spec formaliza o fix existente e o cobre nos testes.
2. **Remover `lookupInvite`.** O endpoint `GET /api/v1/couple/invites/{code}` **não existe no backend** (confirmado via Swagger e teste manual). O fluxo de "preview do parceiro antes de aceitar" foi planejado em `2026-05-21-couple-scan-qr-code` assumindo essa rota — assumida errada. Toda a infra de lookup vira morta: response, model, extension, método de datasource, método de repositório, testes correspondentes, e tudo na UI que dependia do `InviteLookupModel` antes do accept.
3. **Corrigir path do accept.** O datasource monta `POST /api/v1/couple/invites/{code}/accept`, mas o backend expõe a rota em `POST /api/v1/invites/{code}/accept` (sem `/couple` no meio). Vai dar 404 quando o user tocar "Aceitar convite". Criar `EndpointKey.invites = '/api/v1/invites'` e usar no `acceptInvite`.

## Motivação

1. **Feature quebrada end-to-end.** Sem essas correções: o fluxo de scan dá 404 no lookup (não passa do scan), e mesmo com o fix do parse o accept também daria 404. A feature inteira (couple-scan-qr-code) é não-funcional em produção.

2. **Decisão de produto: tela de confirm sem preview do parceiro.** Sem lookup, a `CoupleScanConfirmScreen` não tem como mostrar dados do parceiro **antes** de aceitar. Confirmado com o usuário: a tela passa a mostrar apenas o **código** ("Aceitar convite **ABCDEF**?"). Após accept com sucesso, o toast traz o nome do parceiro (`'Você está conectado com Marina.'`) usando os dados que vêm no response do POST.

3. **Payload do accept bate com o `InviteLookupModel` atual.** O `POST /api/v1/invites/{code}/accept` devolve `{ couple_id, partner: { id, email, name } }` — exatamente os campos de `InviteLookupModel`/`InviteLookupResponse`. Em vez de deletar e recriar tudo, **renomear** semanticamente:
   - `InviteLookupModel` → `InviteAcceptModel`
   - `InviteLookupResponse` → `InviteAcceptResponse`
   - `InviteLookupResponseExtension` → `InviteAcceptResponseExtension`
   - `invite_lookup_mock.dart` → `invite_accept_mock.dart` (mock helper)

   Mantém a tipagem útil sem carregar nome `Lookup` que não corresponde mais ao uso.

## Camadas afetadas

### Infrastructure

- `lib/src/infrastructure/clients/http/endpoint_key.dart` — adicionar `invites('/api/v1/invites')` ao enum. Remover **não**: `coupleInvites` continua usado pelo `createInvite` (POST `/api/v1/couple/invites`).
- `lib/src/infrastructure/clients/http/responses/couple/invite_lookup_response.dart` → renomear arquivo para `invite_accept_response.dart` e classe para `InviteAcceptResponse` (mantém `fromJson` idêntico).
- `lib/src/infrastructure/datasources/remote/remote_couple_data_source.dart` — remover `lookupInvite` da interface e da implementação. `acceptInvite` muda o path para `'${EndpointKey.invites.path}/$code/accept'`.

### Domain

- `lib/src/domain/models/couple/invite_lookup_model.dart` → renomear arquivo para `invite_accept_model.dart` e classe para `InviteAcceptModel` (campos `coupleId`/`partner` inalterados).
- `lib/src/domain/repositories/interface_couple_repository.dart` — remover `lookupInvite` da interface. `acceptInvite` passa a retornar `Future<Either<Failure, InviteAcceptModel>>`.

### Data

- `lib/src/data/extensions/invite_lookup_response_extension.dart` → renomear arquivo para `invite_accept_response_extension.dart`. Extension `InviteLookupResponseExtension on InviteLookupResponse` → `InviteAcceptResponseExtension on InviteAcceptResponse`, retornando `InviteAcceptModel`.
- `lib/src/data/repositories/couple_repository.dart` — remover método `lookupInvite`. `acceptInvite` continua igual em forma, só muda o tipo de retorno (`InviteAcceptModel`).

### Presentation — `couple/scan/`

- `lib/src/presentation/ui/couple/scan/data/couple_scan_state.dart` — remover `lookup: InviteLookupModel?` do state, remover status `.lookup` e `.lookedUp` do enum. Adicionar status `.detected` (substitui `.lookedUp`) que sinaliza "QR/código capturado, navegue pra confirm". State passa a guardar apenas `code: String` na ramificação de sucesso.
- `lib/src/presentation/ui/couple/scan/notifiers/couple_scan_notifier.dart` — remover `_lookup`, manter `_parseCode`. O dispatch de `QrDetected` / `ManualCodeSubmitted` faz: parse → set `state.code = parsed`, `state.status = .detected`. Sem chamada a `_repository.lookupInvite`. O `_repository` deixa de ser dependência do notifier de scan.
- `lib/src/presentation/ui/couple/scan/screens/couple_scan_screen.dart` — `_onStatusChanged` reage a `.detected` (em vez de `.lookedUp`) navegando pra `CoupleScanConfirmLocation(code: state.code)`. Remover `lookup` do construtor do `CoupleScanConfirmLocation`.
- `lib/src/presentation/ui/couple/scan/locations/couple_scan_confirm_location.dart` — remover prop `lookup: InviteLookupModel`. Passa só `code: String` pra `CoupleScanConfirmScreen`.
- `lib/src/presentation/ui/couple/scan/screens/couple_scan_confirm_screen.dart` — remover prop `lookup`. Substituir `CoupleScanPartnerPreviewWidget(partner: lookup.partner)` por um `Text(code)` estilizado (`headlineMedium`, `fontWeight: w600`, `letterSpacing: 4.0`) — mesma estética do code exibido em `InviteQrCardWidget`. Atualizar `description` do `ScreenHeaderWidget` para algo como `'Confirme o código do convite antes de aceitar.'`. No `_onSuccess`, ler o `partnerName` do state pra montar o toast `'Você está conectado com $partnerName.'`.
- `lib/src/presentation/ui/couple/scan/data/couple_scan_confirm_state.dart` — adicionar `partnerName: String` (default `''`) ao state. Preenchido em `_accept` ao receber `Right(InviteAcceptModel)`.
- `lib/src/presentation/ui/couple/scan/notifiers/couple_scan_confirm_notifier.dart` — em `_accept`, no branch `Right`, ler `model.partner.name` e setar `state.copyWith(status: .success, partnerName: model.partner.name)`. Invalidations continuam idênticas.
- `lib/src/presentation/ui/couple/scan/widgets/couple_scan_partner_preview_widget.dart` — **deletar**. Não é mais usado em lugar nenhum após a remoção do preview pré-accept.
- `lib/src/presentation/ui/couple/scan/preview/widgets/couple_scan_partner_preview_widget_preview.dart` — **deletar**.
- `lib/src/presentation/ui/couple/scan/preview/mocks/invite_lookup_mock.dart` → renomear para `invite_accept_mock.dart` com função `inviteAcceptMock(...)` retornando `InviteAcceptModel`. Continua usado pelos testes de notifier e repository.

### Testes

- `test/src/data/repositories/couple_repository_test.dart` — remover grupo `lookupInvite` inteiro. No grupo `acceptInvite`, atualizar tipos (`InviteLookupResponse` → `InviteAcceptResponse`) e asserções (`InviteAcceptModel`).
- `test/src/infrastructure/responses/invite_lookup_response_test.dart` → renomear para `invite_accept_response_test.dart`; trocar classe testada.
- `test/src/presentation/providers/couple_scan_notifier_test.dart` — remover mock do `ICoupleRepository` (não é mais dependência do notifier de scan). Reescrever todos os testes que checavam `.lookedUp` / `.lookup`: passam a checar `.detected` e `state.code = parsed`. Manter os testes de parse do deep link (já adicionados). Sem stubs de `lookupInvite`.
- `test/src/presentation/providers/couple_scan_confirm_notifier_test.dart` — atualizar stubs de `acceptInvite` para retornar `Right(InviteAcceptModel)`. Adicionar asserção `state.partnerName == 'Marina'` no teste de sucesso.
- `test/mocks/mocks.dart` — sem mudança estrutural (mock de `ICoupleRepository` continua válido, só perde o stub de `lookupInvite`).

## Fora do escopo

- **Tela de "sucesso" pós-accept** com dados do parceiro. A spec mantém toast + `context.root()` (mesmo padrão da `CoupleDissolveScreen._onSuccess`). Tela dedicada vira spec separada se houver demanda.
- **Deep linking nativo** (`trocado://invite/<code>` abrindo o app via intent filter / Universal Link). Spec separada — esta só consome o deep link quando vem via QR scan.
- **Validar formato do code antes de mandar pro accept.** Continua "string opaca pro backend" — vale a decisão 13 da spec original.
- **Reescrever o fluxo de scan sem `MobileScanner`** ou trocar de lib. Não há indício de bug na lib, só na orquestração do app.
- **Refinar mensagem do toast de sucesso** (i18n, variações por gênero, etc). Hardcoded pt_BR.
- **Telemetria de eventos de scan/accept.** Mesma posição da spec original.
- **Recuperar gracefully de `EndpointKey.invites` retornando 404 não-mapeado** (ex: route 404 vs `invite_not_found`). O `FailureResponse` da API existe e a UI já mostra toast — sem retry automático.

## Decisões de design

1. **Renomear `Lookup` → `Accept`, não deletar.** O payload do accept bate 1:1 com o que era esperado do lookup. Renomear preserva os testes de `fromJson`, a extension de mapping, o mock helper, e o `final class` em domain. Deletar tudo pra recriar com nome novo geraria churn maior sem ganho semântico.

2. **`acceptInvite` muda só o path, não o método HTTP nem o body.** Continua `POST` sem body. A única alteração é o `EndpointKey` usado para montar o path.

3. **Novo `EndpointKey.invites`, não reaproveitar `coupleInvites`.** O `coupleInvites` (= `/api/v1/couple/invites`) ainda é usado pelo `createInvite` (POST que gera o code). São paths diferentes no backend (`/couple/invites` vs `/invites`), então têm que ser entradas separadas no enum.

4. **Status `.detected` substitui `.lookedUp`.** Mantém a separação semântica: "scan capturou algo válido" vs "câmera ativa". Sem o lookup intermediário, `.detected` significa "code parseado, navegue". Nome `.detected` é mais honesto que reusar `.lookedUp` (já que nada foi "looked up").

5. **`_repository` deixa de ser dependência do `CoupleScanNotifier`.** Agora o notifier só lida com câmera, permissão e parse. Toda interação com backend acontece em `CoupleScanConfirmNotifier`. Reflete o novo fluxo: scan é client-side puro, accept é o único momento de I/O.

6. **`partnerName` no `CoupleScanConfirmState`, não passar pela navegação.** Alternativa: o notifier expõe um `AcceptOutcome { partnerName }` via stream/state e a screen consome. Mais simples: state ganha um campo `partnerName: String`. Set em `_accept` no branch Right, lido em `_onSuccess` do screen.

7. **Code centralizado como Text estilizado, sem widget novo.** A exibição do code é um `Text` com 3 estilos (size, weight, letterSpacing). Não justifica `InviteCodeWidget` próprio — uma única call inline na screen. Se um terceiro lugar precisar exibir code, vira widget compartilhado em `presentation/widgets/invite/`.

8. **Deletar `CoupleScanPartnerPreviewWidget` e seu preview.** Sem uso após a remoção do preview pré-accept. Manter morto seria ruído visual no codebase. Caso uma spec futura ressuscite a ideia (preview pós-accept como "tela de sucesso"), recria com escopo próprio.

9. **`_parseCode` permanece privado do notifier.** É a única regra de transformação do scan e mora num único lugar. Promover pra função pública ou serviço seria over-engineering — o parse não tem variantes nem outro consumidor.

10. **Manter botão "Digitar código manualmente" e validação local.** O `InviteCodeValidation` (`length: 6`, alphabet, regex) continua válido — não depende de lookup. `ManualCodeSubmitted` passa pelo mesmo `_parseCode` (com `Uri.tryParse` que retorna `null` para "ABCDEF" sem prefixo, então `_parseCode` devolve o code cru via trim — funciona pros dois caminhos).

11. **Não tocar no `FailureCodeResponse`.** Os códigos `invite_not_found`, `invite_expired`, `invite_already_used`, `invite_own`, `already_in_couple` já estão (ou estavam previstos pra estar) e continuam relevantes para o accept. Esta spec não muda o enum.

12. **Spec de bug fix, não rewrite.** Apesar de tocar muitas camadas, é uma correção de feature já entregue. Sem nova feature, sem novo endpoint do nosso lado, sem mudança de UX além do confirm-sem-preview já alinhado.
