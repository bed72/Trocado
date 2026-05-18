# Design: settings-couple-card

## Contrato da API

**Endpoint:** `GET /api/v1/couple` ([[Trocado/BackEnd/03 - API Endpoints]] §Couples).

**Auth:** `Authorization: Bearer <access>` (injetado por `AuthenticationInterceptor`).

**Body:** vazio. **Query:** nenhuma.

**Response 200:**

```json
{
  "id": 1,
  "partner": { "id": 2, "email": "partner@trocado.app", "name": "Marina" },
  "created_at": "2026-01-12T14:30:00Z"
}
```

**Response 403 ou 404 `not_in_couple`:**

```json
{
  "errors": [
    { "field": null, "message": "Você não está em um casal.", "code": "not_in_couple" }
  ]
}
```

O HTTP status pode ser `403` ou `404` dependendo do path do permission check no backend ([[Trocado/BackEnd/04 - Security]] §7). **O cliente confia no `code`, não no status** — é assim que o `FailureResponseExtension` já decide hoje.

**Outros 4xx/5xx:** envelope canônico com codes diversos.

Cache backend: 60min por usuário (`couple:{user_id}`). Cliente confia.

---

## Domain

### `CoupleModel` (novo)

`lib/src/domain/models/couple/couple_model.dart`:

```dart
import 'package:equatable/equatable.dart';

import 'package:trocado/src/domain/models/user_model.dart';

final class CoupleModel extends Equatable {
  final int id;
  final int createdAt;
  final UserModel partner;

  const CoupleModel({
    required this.id,
    required this.partner,
    required this.createdAt,
  });

  CoupleModel copyWith({int? id, UserModel? partner, int? createdAt}) =>
      CoupleModel(
        id: id ?? this.id,
        partner: partner ?? this.partner,
        createdAt: createdAt ?? this.createdAt,
      );

  @override
  List<Object?> get props => [id, partner, createdAt];
}
```

Reusa `UserModel` para `partner` — backend retorna exatamente `{id, email, name}`.

### `ICoupleRepository` — extensão

`lib/src/domain/repositories/interface_couple_repository.dart`:

```dart
abstract interface class ICoupleRepository {
  Future<Either<Failure, InviteModel>> createInvite();
  Future<Either<Failure, CoupleModel>> findActive();
}
```

### `IDateFormatterService` — extensão

`lib/src/domain/services/date_formatter_service.dart`:

```dart
abstract interface class IDateFormatterService {
  // ... existentes
  String formatRelativePast(int millis);
}
```

`formatRelativePast(int)` retorna **apenas** o trecho relativo (`"4 meses"`, `"1 semana"`, `"alguns dias"`). Concatenação `"Conectados há $relativo"` fica no presentation data.

---

## Infrastructure

### `FailureCodeResponse.notInCouple` (novo)

`lib/src/infrastructure/clients/http/responses/failure/failure_code_response.dart`:

```dart
enum FailureCodeResponse {
  unknown('unknown'),
  notFound('not_found'),
  notInCouple('not_in_couple'),
  serverError('server_error'),
  networkError('network_error');
  // ... resto inalterado
}
```

### `FailureResponseExtension` — branch novo

`lib/src/data/extensions/failure_response_extension.dart`:

```dart
return switch (FailureCodeResponse.fromString(failure.code ?? '')) {
  .notFound => const NotFoundFailure(),
  .notInCouple => const NotFoundFailure(),   // ← novo
  .serverError => const ServerFailure(),
  .networkError => const NetworkFailure(),
  _ => ValidationFailure(failure.message ?? 'Falha desconhecida.'),
};
```

Mapeia o code `not_in_couple` pro mesmo `NotFoundFailure`. Justifica: o `CoupleNotifier` trata "fora de casal" como `null`, e o tipo `NotFoundFailure` captura semanticamente o "recurso ausente". Não criamos `NotInCoupleFailure` novo — o domínio de erros do projeto fica enxuto e o sinal está em `NotFoundFailure` já que nenhum outro caller atualmente distingue "casal não existe" de outros 404s. Se virar necessário (ex: tela `/couple/details` precisar diferenciar), promove pra failure dedicado.

### `EndpointKey.couple` (novo)

`lib/src/infrastructure/clients/http/endpoint_key.dart`:

```dart
enum EndpointKey {
  // ...
  couple('/api/v1/couple'),
  coupleInvites('/api/v1/couple/invites'),
  // ...
}
```

### `CoupleResponse` (novo)

`lib/src/infrastructure/clients/http/responses/couple/couple_response.dart`:

```dart
import 'package:trocado/src/infrastructure/clients/http/responses/user_response.dart';

final class CoupleResponse {
  final int id;
  final String createdAt;
  final UserResponse partner;

  const CoupleResponse({
    required this.id,
    required this.partner,
    required this.createdAt,
  });

  factory CoupleResponse.fromJson(Map<String, dynamic> json) => CoupleResponse(
    id: json['id'] as int,
    createdAt: json['created_at'] as String,
    partner: UserResponse.fromJson(json['partner'] as Map<String, dynamic>),
  );
}
```

`created_at` fica `String` aqui — a conversão ISO → `int` millis acontece na extension de mapping (`couple_response_extension.dart`).

### `IRemoteCoupleDataSource` — extensão

`lib/src/infrastructure/datasources/remote/remote_couple_data_source.dart`:

```dart
abstract interface class IRemoteCoupleDataSource {
  Future<Either<FailureResponse, InviteResponse>> createInvite();
  Future<Either<FailureResponse, CoupleResponse>> findActive();
}

// impl:
@override
Future<Either<FailureResponse, CoupleResponse>> findActive() async {
  final response = await _client.get(
    parameter: Requests(EndpointKey.couple.path),
  );

  return response.either(FailureResponse.fromJson, CoupleResponse.fromJson);
}
```

Verificar antes de implementar: o `IHttpClient.get` tem assinatura `get({required Requests parameter})`? Espera-se que sim (mesmo shape de `post`/`delete`). Confirmar lendo `infrastructure/clients/http/http_client.dart`. Se a assinatura for diferente, ajustar.

### `DateFormatterService.formatRelativePast` (novo)

`lib/src/infrastructure/services/date_formatter_service.dart`:

```dart
@override
String formatRelativePast(int millis) {
  final past = DateTime.fromMillisecondsSinceEpoch(millis);
  final diff = _now().difference(past);
  final days = diff.inDays;

  if (days < 7) return 'alguns dias';

  if (days < 30) {
    final weeks = days ~/ 7;
    return weeks == 1 ? '1 semana' : '$weeks semanas';
  }

  if (days < 365) {
    final months = days ~/ 30;
    return months == 1 ? '1 mês' : '$months meses';
  }

  final years = days ~/ 365;
  return years == 1 ? '1 ano' : '$years anos';
}
```

Aproximação: `~/ 30` e `~/ 365` (não calendar-exact). Justifica: ganho marginal de precisão não compensa complexidade — "há 4 meses" vs "há 4 meses e 2 dias" é o mesmo pra UX. Esse cálculo determinístico facilita os testes.

---

## Data

### `CoupleResponseExtension` (novo)

`lib/src/data/extensions/couple_response_extension.dart`:

```dart
import 'package:trocado/src/data/extensions/user_response_extension.dart';

import 'package:trocado/src/domain/models/couple/couple_model.dart';

import 'package:trocado/src/infrastructure/clients/http/responses/couple/couple_response.dart';

extension CoupleResponseExtension on CoupleResponse {
  CoupleModel toModel() => CoupleModel(
    id: id,
    partner: partner.toModel(),
    createdAt: DateTime.parse(createdAt).millisecondsSinceEpoch,
  );
}
```

Reaproveita `UserResponseExtension.toModel()` (já existe).

### `CoupleRepository.findActive`

`lib/src/data/repositories/couple_repository.dart`:

```dart
@override
Future<Either<Failure, CoupleModel>> findActive() async {
  final data = await _dataSource.findActive();

  return data.either(
    (failure) => failure.toFailure(),
    (response) => response.toModel(),
  );
}
```

---

## Presentation

### `CoupleNotifier` (novo)

`lib/src/presentation/ui/settings/notifiers/couple_notifier.dart`:

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:trocado/src/main/providers/repositories_provider.dart';

import 'package:trocado/src/domain/failures/failure.dart';
import 'package:trocado/src/domain/models/couple/couple_model.dart';
import 'package:trocado/src/domain/repositories/interface_couple_repository.dart';

part 'couple_notifier.g.dart';

@Riverpod(keepAlive: true)
final class CoupleNotifier extends _$CoupleNotifier {
  late ICoupleRepository _repository;

  @override
  Future<CoupleModel?> build() async {
    _repository = ref.watch(coupleRepositoryProvider);

    final data = await _repository.findActive();

    return data.fold((Failure _) => null, (couple) => couple);
  }
}
```

`keepAlive: true` porque o estado é estável durante a sessão e raramente muda. Retorna `null` em qualquer failure — `NotFoundFailure` é o caminho esperado, demais failures degradam pro mesmo state (card de convite).

### `CoupleCardPresentationData` (novo)

`lib/src/presentation/ui/settings/data/couple_card_presentation_data.dart`:

```dart
import 'package:equatable/equatable.dart';

final class CoupleCardPresentationData extends Equatable {
  final String title;
  final String subtitle;
  final String partnerInitial;
  final String currentUserInitial;

  const CoupleCardPresentationData({
    required this.title,
    required this.subtitle,
    required this.partnerInitial,
    required this.currentUserInitial,
  });

  @override
  List<Object?> get props => [
    title,
    subtitle,
    partnerInitial,
    currentUserInitial,
  ];
}
```

Construído pelo `SettingsCoupleStatusWidget` consumindo `coupleNotifier` + `userNotifier` (`userProvider` existente) + `dateFormatterServiceProvider`.

> [!warning] Service-via-notifier
> A regra do projeto é "services só via notifier". O `SettingsCoupleStatusWidget` precisa do `IDateFormatterService` pra montar o subtitle. Duas opções:
> - **(A)** Mover a construção do `CoupleCardPresentationData` pra dentro do `CoupleNotifier`, que injeta `dateFormatterServiceProvider` + `userProvider`. State do `CoupleNotifier` vira `Future<CoupleCardPresentationData?>`.
> - **(B)** Manter o widget chamando o service direto (viola convenção).
>
> **Decisão: (A)**. O `CoupleNotifier` passa a expor `Future<CoupleCardPresentationData?>`. `keepAlive: true`. Quando `userProvider` muda (raro — só ao editar nome), `CoupleNotifier` reconstrói automaticamente porque `ref.watch(userProvider.future)` participa do build. Conforme convenção [[CLAUDE.md]] §Services-via-notifier.

Versão revisada do `CoupleNotifier`:

```dart
@Riverpod(keepAlive: true)
final class CoupleNotifier extends _$CoupleNotifier {
  late ICoupleRepository _repository;
  late IDateFormatterService _dateFormatter;

  @override
  Future<CoupleCardPresentationData?> build() async {
    _repository = ref.watch(coupleRepositoryProvider);
    _dateFormatter = ref.watch(dateFormatterServiceProvider);

    final user = await ref.watch(userProvider.future);
    final data = await _repository.findActive();

    return data.fold(
      (_) => null,
      (couple) => _toPresentationData(user, couple),
    );
  }

  CoupleCardPresentationData _toPresentationData(
    UserModel user,
    CoupleModel couple,
  ) => CoupleCardPresentationData(
    title: '${user.name} & ${couple.partner.name}',
    subtitle: 'Conectados há ${_dateFormatter.formatRelativePast(couple.createdAt)}',
    currentUserInitial: _initial(user.name),
    partnerInitial: _initial(couple.partner.name),
  );

  String _initial(String name) =>
      name.trim().isEmpty ? '' : name.trim().characters.first.toUpperCase();
}
```

`_initial(...)` espelha a lógica do `AvatarWidget` (`characters.first.toUpperCase()`). Centralizar isso num helper de `domain/` é tentador mas YAGNI — duas chamadas no projeto inteiro.

### `SettingsCoupleStatusWidget` (novo)

`lib/src/presentation/ui/settings/widgets/settings_couple_status_widget.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:trocado/src/presentation/ui/settings/notifiers/couple_notifier.dart';
import 'package:trocado/src/presentation/ui/settings/widgets/settings_couple_connected_widget.dart';
import 'package:trocado/src/presentation/ui/settings/widgets/settings_invite_partner_widget.dart';

class SettingsCoupleStatusWidget extends StatelessWidget {
  final VoidCallback onInvitePartner;
  final VoidCallback onCoupleDetails;

  const SettingsCoupleStatusWidget({
    super.key,
    required this.onInvitePartner,
    required this.onCoupleDetails,
  });

  @override
  Widget build(BuildContext context) => Consumer(
    builder: (_, ref, _) {
      final state = ref.watch(coupleNotifierProvider);

      return switch (state) {
        AsyncData(:final value) when value != null =>
          SettingsCoupleConnectedWidget(data: value, onTap: onCoupleDetails),
        _ => SettingsInvitePartnerWidget(onTap: onInvitePartner),
      };
    },
  );
}
```

Switch expression cobre todos os casos: `AsyncData(value != null)` → connected; **outros** (`AsyncLoading`, `AsyncError`, `AsyncData(null)`) → invite. Mantém consistência com a decisão de "qualquer failure cai no invite".

### `SettingsCoupleConnectedWidget` (novo)

`lib/src/presentation/ui/settings/widgets/settings_couple_connected_widget.dart`:

```dart
import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/extensions/context_extension.dart';
import 'package:trocado/src/presentation/widgets/bounce_widget.dart';
import 'package:trocado/src/presentation/widgets/avatar/avatar_pair_widget.dart';

import 'package:trocado/src/presentation/ui/settings/data/couple_card_presentation_data.dart';

class SettingsCoupleConnectedWidget extends StatelessWidget {
  final VoidCallback onTap;
  final CoupleCardPresentationData data;

  const SettingsCoupleConnectedWidget({
    super.key,
    required this.data,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => BounceWidget.withOnPress(
    onPress: onTap,
    child: Card(
      margin: .zero,
      elevation: 0.0,
      clipBehavior: .antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: context.radius.cornerRadius100,
      ),
      child: Padding(
        padding: const .all(12.0),
        child: Row(
          spacing: 12.0,
          crossAxisAlignment: .center,
          children: [
            AvatarPairWidget(
              firstInitial: data.currentUserInitial,
              secondInitial: data.partnerInitial,
            ),
            Expanded(
              child: Column(
                spacing: 2.0,
                mainAxisSize: .min,
                crossAxisAlignment: .start,
                children: [
                  Text(
                    data.title,
                    maxLines: 1,
                    overflow: .ellipsis,
                    style: context.typography.bodyMedium?.copyWith(
                      fontWeight: .bold,
                      color: context.colors.onSecondaryContainer,
                    ),
                  ),
                  Text(
                    data.subtitle,
                    maxLines: 1,
                    overflow: .ellipsis,
                    style: context.typography.bodySmall?.copyWith(
                      color: context.colors.onSecondaryContainer,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 24.0,
              color: context.colors.onSecondaryContainer,
            ),
          ],
        ),
      ),
    ),
  );
}
```

Visualmente espelha `IconCardWidget` (padding 12, spacing 12, radius cornerRadius100, chevron). Único diff: o leading não é `BackgroundIconWidget` — é `AvatarPairWidget`.

### `AvatarPairWidget` (novo, compartilhado)

`lib/src/presentation/widgets/avatar/avatar_pair_widget.dart`:

```dart
import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/extensions/context_extension.dart';

class AvatarPairWidget extends StatelessWidget {
  static const double _size = 40.0;
  static const double _overlap = 16.0;

  final String firstInitial;
  final String secondInitial;

  const AvatarPairWidget({
    super.key,
    required this.firstInitial,
    required this.secondInitial,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _size * 2 - _overlap,
      height: _size,
      child: Stack(
        children: [
          Positioned(
            left: 0.0,
            child: _buildAvatar(
              context: context,
              initial: firstInitial,
              backgroundOpacity: 0.4,
            ),
          ),
          Positioned(
            left: _size - _overlap,
            child: _buildAvatar(
              context: context,
              initial: secondInitial,
              backgroundOpacity: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar({
    required BuildContext context,
    required String initial,
    required double backgroundOpacity,
  }) => Container(
    width: _size,
    height: _size,
    alignment: .center,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: context.colors.primary.withValues(alpha: backgroundOpacity),
      border: Border.all(color: context.colors.surface, width: 2.0),
    ),
    child: Text(
      initial,
      style: context.typography.titleMedium?.copyWith(
        fontWeight: .w800,
        color: backgroundOpacity > 0.6
            ? context.colors.onPrimary
            : context.colors.primary,
      ),
    ),
  );
}
```

Notas:
- `BoxShape.circle` (não `RoundedRectangleBorder` como no `AvatarWidget`) porque o screenshot mostra avatares circulares — combina melhor visualmente com o overlap. Pode ser ajustado pra `BorderRadius.circular(cornerRadius100)` se a regra de design system exigir.
- `border` na cor do `surface` cria o "anel" que separa os dois avatares quando sobrepostos.
- Cor do texto inverte quando o fundo é cheio (`onPrimary`) vs translúcido (`primary` — fica legível sobre 40% alpha).

### Screen wiring

`lib/src/presentation/ui/settings/screens/settings_screen.dart` — diffs:

1. **Novo callback** `final VoidCallback onCoupleDetails;` + parâmetro no construtor.
2. **Imports**: trocar `settings_invite_partner_widget.dart` por `settings_couple_status_widget.dart`.
3. **`_buildCouple`**:

   ```dart
   List<Widget> get _buildCouple => [
     _buildTitleItem('Casal'),
     const SizedBox(height: 8.0),
     SettingsCoupleStatusWidget(
       onInvitePartner: onInvitePartner,
       onCoupleDetails: onCoupleDetails,
     ),
   ];
   ```

### Location wiring

`lib/src/presentation/ui/settings/locations/settings_location.dart`:

```dart
SettingsScreen(
  onNotification: () {},
  onSubscription: () {},
  onCoupleDetails: () {},
  onEditProfile: () => context.navigate(ProfileDetailsLocation()),
  onInvitePartner: () => context.navigate(PartnerInviteLocation()),
  onSignIn: () => context.clear(SignInLocation(), root: true, replace: true),
),
```

`onCoupleDetails: () {}` é placeholder consciente — spec separada wireará a navegação.

---

## Decisões de design adicionais

1. **`CoupleNotifier` consome `userProvider.future` no `build`.**
   Garante que `user.name` esteja disponível quando montamos o `title`. `userProvider` é `AsyncNotifier` e já carrega no splash — em runtime real, o `future` resolve imediatamente. Se o user ainda não foi carregado, o `coupleNotifier` espera — comportamento aceitável.

2. **Pull-to-refresh / invalidação manual fora de escopo.**
   Após `keepAlive: true`, só `ref.invalidate(coupleNotifierProvider)` força reload. Não há essa chamada hoje porque nenhuma mutação client-side altera status de casal. Quando o spec de aceitar convite entrar, ele invalida — e essa é a "exceção narrada" da regra de encapsulamento (`ref.invalidate` cross-feature pós-mutação).

3. **Falha total de carregar `user` cai em error global do app.**
   Se `userProvider.future` lançar (já lança via `throw failure` em `UserNotifier._getMe`), o `coupleNotifier` propaga o erro como `AsyncError`. Switch no `SettingsCoupleStatusWidget` cai no default (invite). Aceitável.

4. **Performance.**
   `coupleNotifier` é `@Riverpod(keepAlive: true)` — não reconstrói entre visitas à settings. Reconstrói apenas se `userProvider` for invalidado (raro). Custo: 1 GET por sessão. Backend cacheia 60min, então até o servidor é leve.

5. **Sem widget tests pro `SettingsCoupleStatusWidget`.**
   Projeto não tem widget tests para widgets condicionais equivalentes. Cobertura via notifier test + análise estática.

---

## Testes

### `test/src/infrastructure/responses/couple_response_test.dart` (novo)

- `fromJson parses id, partner and createdAt`.
- `fromJson nested partner has id, email, name`.

### `test/src/infrastructure/services/date_formatter_service_test.dart` (estender)

Adicionar `group('formatRelativePast')`:

- `'< 7 days returns alguns dias'` — diff 3 dias → `'alguns dias'`.
- `'7-29 days returns X semana[s]'` — 7d → `'1 semana'`; 14d → `'2 semanas'`.
- `'30-364 days returns X mês/meses'` — 30d → `'1 mês'`; 120d → `'4 meses'`.
- `'>= 365 days returns X ano[s]'` — 365d → `'1 ano'`; 800d → `'2 anos'`.

Usa o `now()` injetável do service (já parametrizado em `DateFormatterService({required DateTime Function() now})`).

### `test/src/data/repositories/couple_repository_test.dart` (estender)

Adicionar `group('findActive')`:

- `'returns Right with CoupleModel on success'`.
- `'returns Left NotFoundFailure when datasource returns not_found code'`.
- `'returns Left NetworkFailure on network error'`.
- `'returns Left ServerFailure on server error'`.

Mock em `IRemoteCoupleDataSource` — o test do `RemoteCoupleDataSource` é coberto por response test + HTTP client mock (mesmo padrão das outras specs).

### `test/src/infrastructure/datasources/remote/remote_couple_data_source_test.dart` (estender)

Adicionar `group('findActive')`:

- `'sends GET to /api/v1/couple and returns Right on success'`.
- `'returns Left with FailureResponse on backend error'`.

Mock em `IHttpClient`.

### `test/src/presentation/providers/couple_notifier_test.dart` (novo)

- `'returns null when repository returns NotFoundFailure'`.
- `'returns null when repository returns other failure'`.
- `'returns CoupleCardPresentationData on success'` — assert title `'<user> & <partner>'`, subtitle `'Conectados há 4 meses'` (com `_now` controlado), initials.
- `'rebuilds when userProvider changes'` — invalidar `userProvider` → `coupleNotifier` re-executa build.

Mocks: `MockCoupleRepository`, `MockDateFormatterService`. Inject `userProvider` overrides via `ProviderContainer`.

### Sem widget tests

Conforme padrão do projeto.
