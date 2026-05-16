# Tasks: settings-couple-card

## domain/

- [ ] `lib/src/domain/models/couple/couple_model.dart` (NOVO) — `CoupleModel` com `id`, `partner: UserModel`, `createdAt: int`; `copyWith`; Equatable
- [ ] `lib/src/domain/repositories/interface_couple_repository.dart` — adicionar `Future<Either<Failure, CoupleModel>> findActive()`
- [ ] `lib/src/domain/services/date_formatter_service.dart` — adicionar `String formatRelativePast(int millis)`

## infrastructure/

- [ ] `lib/src/infrastructure/clients/http/endpoint_key.dart` — adicionar `couple('/api/v1/couple')`
- [ ] `lib/src/infrastructure/clients/http/responses/failure/failure_code_response.dart` — adicionar `notInCouple('not_in_couple')`
- [ ] `lib/src/infrastructure/clients/http/responses/couple/couple_response.dart` (NOVO) — `CoupleResponse` com `fromJson`, encapsula `UserResponse`
- [ ] `lib/src/infrastructure/datasources/remote/remote_couple_data_source.dart` — adicionar `findActive()` na interface + impl: `_client.get(parameter: Requests(EndpointKey.couple.path))` mapeado via `response.either(FailureResponse.fromJson, CoupleResponse.fromJson)`
- [ ] `lib/src/infrastructure/services/date_formatter_service.dart` — implementar `formatRelativePast`

## data/

- [ ] `lib/src/data/extensions/couple_response_extension.dart` (NOVO) — `toModel()` mapeando `UserResponse.toModel()` + `DateTime.parse(createdAt).millisecondsSinceEpoch`
- [ ] `lib/src/data/extensions/failure_response_extension.dart` — adicionar branch `.notInCouple => const NotFoundFailure()` no switch
- [ ] `lib/src/data/repositories/couple_repository.dart` — adicionar `findActive()` forward via `data.either`

## presentation/

- [ ] `lib/src/presentation/ui/settings/data/couple_card_presentation_data.dart` (NOVO) — `CoupleCardPresentationData` com `title`, `subtitle`, `currentUserInitial`, `partnerInitial`
- [ ] `lib/src/presentation/ui/settings/notifiers/couple_notifier.dart` (NOVO) — `@Riverpod(keepAlive: true)` `AsyncNotifier<CoupleCardPresentationData?>`; injeta `coupleRepositoryProvider`, `dateFormatterServiceProvider`, `userProvider`; constrói `CoupleCardPresentationData` em sucesso, retorna `null` em qualquer failure
- [ ] `lib/src/presentation/widgets/avatar/avatar_pair_widget.dart` (NOVO) — par de avatares 40px sobrepostos 16px; primeiro `primary @ 0.4`, segundo `primary cheio`; borda branca 2px
- [ ] `lib/src/presentation/ui/settings/widgets/settings_couple_connected_widget.dart` (NOVO) — Card com `AvatarPairWidget` + título `data.title` + subtítulo `data.subtitle` + chevron; `BounceWidget.withOnPress(onTap)`
- [ ] `lib/src/presentation/ui/settings/widgets/settings_couple_status_widget.dart` (NOVO) — `Consumer` lendo `coupleNotifierProvider`; switch expression renderiza `SettingsCoupleConnectedWidget` quando `AsyncData(value != null)`, caso contrário `SettingsInvitePartnerWidget`
- [ ] `lib/src/presentation/ui/settings/screens/settings_screen.dart` — adicionar `onCoupleDetails: VoidCallback` no construtor; substituir `SettingsInvitePartnerWidget(onTap: onInvitePartner)` por `SettingsCoupleStatusWidget(onInvitePartner: ..., onCoupleDetails: ...)` em `_buildCouple`
- [ ] `lib/src/presentation/ui/settings/locations/settings_location.dart` — passar `onCoupleDetails: () {}` placeholder

## main/providers/

- [ ] (nenhuma mudança — `coupleRepositoryProvider`, `dateFormatterServiceProvider`, `userProvider` já existem; o `coupleNotifierProvider` é gerado pelo `@Riverpod` na própria feature)

## test/

- [ ] `test/mocks/mocks.dart` — adicionar `MockCoupleRepository` (se já não houver; spec do invite criou `MockCoupleRepository`, confirmar — caso já exista, no-op)
- [ ] `test/src/infrastructure/responses/couple_response_test.dart` (NOVO) — `fromJson` extrai `id`, `partner` (id/email/name) e `createdAt` string
- [ ] `test/src/infrastructure/services/date_formatter_service_test.dart` (ESTENDER) — group `formatRelativePast`: < 7d → `'alguns dias'`; 7/14d → `'1 semana'`/`'2 semanas'`; 30/120d → `'1 mês'`/`'4 meses'`; 365/800d → `'1 ano'`/`'2 anos'`
- [ ] `test/src/infrastructure/datasources/remote/remote_couple_data_source_test.dart` (ESTENDER ou NOVO se não existir) — group `findActive`: GET no path `/api/v1/couple` retorna `Right(CoupleResponse)`; erro HTTP retorna `Left(FailureResponse)`
- [ ] `test/src/data/repositories/couple_repository_test.dart` (ESTENDER ou NOVO) — group `findActive`: success → `Right(CoupleModel)`; cada code de `FailureResponse` mapeia pro `Failure` correto (NotFound/Network/Server/Validation); **incluir caso `code: 'not_in_couple'` → `NotFoundFailure`**
- [ ] `test/src/data/extensions/failure_response_extension_test.dart` (ESTENDER se existir, NOVO se não) — caso `code: 'not_in_couple'` mapeia pra `NotFoundFailure`
- [ ] `test/src/presentation/providers/couple_notifier_test.dart` (NOVO) — `null` em qualquer failure; presentation data construído corretamente em sucesso (title concatenado, subtitle com `formatRelativePast`, initials); rebuild quando `userProvider` invalida

## Pré-condições (já satisfeitas)

- `IHttpClient.get({required Requests parameter})` existe — confirmar antes de implementar
- `EndpointKey` enum aceita novo valor
- `FailureResponseExtension.toFailure()` existe e mapeia `not_found` → `NotFoundFailure`
- `UserResponse`, `UserResponseExtension.toModel()` existem
- `userProvider` (AsyncNotifier) existe
- `dateFormatterServiceProvider` existe (`main/providers/services_provider.dart`)
- `coupleRepositoryProvider` existe
- `IRemoteCoupleDataSource`, `RemoteCoupleDataSource`, `CoupleRepository` existem
- `AvatarWidget`, `BounceWidget`, `IconCardWidget` existem (referência visual)
- `SettingsInvitePartnerWidget` existe e mantém o comportamento atual

## Verificação

- [ ] `dart run build_runner build --delete-conflicting-outputs` — gera `couple_notifier.g.dart`
- [ ] `flutter analyze` — zero issues nos arquivos tocados
- [ ] `flutter test` — todos os testes passam, incluindo os novos
- [ ] Smoke positivo: rodar app autenticado **com casal ativo** → abrir Settings → card mostra avatares sobrepostos + `"<user> & <partner>"` + `"Conectados há X"` + chevron → tocar não navega pra lugar nenhum (placeholder consciente)
- [ ] Smoke negativo: app autenticado **sem casal** → Settings → card invite atual (`person_add_alt`, "Convidar parceiro · Comecem a usar juntos") → tap vai pra `PartnerInviteLocation`
- [ ] Smoke offline: matar rede após login → Settings → card invite (fallback) → não trava, não mostra erro inline
- [ ] `SettingsScreen` não importa nada de `infrastructure/` nem `data/`
- [ ] `SettingsCoupleStatusWidget` não importa nada de `data/` nem `infrastructure/`
