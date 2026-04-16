# Tasks: home-app-bar

## domain/

- [ ] Criar `lib/src/domain/repositories/interface_user_repository.dart` com `IUserRepository.me()`

## infrastructure/

- [ ] Adicionar `me` em `EndpointKey` (`lib/src/infrastructure/clients/http/endpoint_key.dart`)
- [ ] Criar `lib/src/infrastructure/clients/http/responses/me_response.dart` com `MeResponse.fromJson`
- [ ] Criar `lib/src/infrastructure/datasources/remote/remote_user_data_source.dart` com `IRemoteUserDataSource` + `RemoteUserDataSource`

## data/

- [ ] Criar `lib/src/data/extensions/me_response_extension.dart` com `MeResponseExtension.toModel()`
- [ ] Criar `lib/src/data/repositories/user_repository.dart` com `UserRepository implements IUserRepository`

## presentation/

- [ ] Criar `lib/src/presentation/widgets/home/avatar_widget.dart` (`AvatarWidget`)
- [ ] Criar `lib/src/presentation/widgets/home/greeting_widget.dart` (`GreetingWidget`)
- [ ] Criar `lib/src/presentation/widgets/home/home_app_bar_widget.dart` (`HomeAppBarWidget`)
- [ ] Criar `lib/src/presentation/screens/home/user_notifier.dart` + rodar `build_runner`
- [ ] Atualizar `HomeScreen` para usar `HomeAppBarWidget` + `Consumer` interno

## main/

- [ ] Adicionar `remoteUserDataSourceProvider` em `data_sources.provider.dart`
- [ ] Adicionar `userRepositoryProvider` em `repositories_provider.dart`

## Testes

- [ ] Criar `test/src/infrastructure/responses/me_response_test.dart` — testes de `fromJson`
- [ ] Criar `test/src/data/repositories/user_repository_test.dart` — mock em `IHttpClient`
- [ ] Criar `test/src/presentation/providers/user_notifier_test.dart` — mock em `IUserRepository`
