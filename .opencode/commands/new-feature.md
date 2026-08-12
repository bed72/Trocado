---
description: Guide implementation of a new Trocado feature using the project's Clean Architecture and MVI conventions.
agent: build
---

# New Feature Checklist

Apply this checklist to the requested feature: $ARGUMENTS

## Standard flow

```
Notifier -> Repository -> DataSource -> Client
```

## Checklist by layer

### 1. Domain — contracts (pure Dart, zero Flutter)

- [ ] Create the model in `lib/src/domain/models/` with fields before the constructor and a required `copyWith()`.
- [ ] Create the repository interface in `lib/src/domain/repositories/` returning `Either<Failure, T>` and never throwing exceptions.

### 2. Infrastructure — request, response, and datasource

- [ ] Create `XxxRequest` in `lib/src/infrastructure/clients/http/requests/` with `toJson()`.
- [ ] Create `XxxResponse` in `lib/src/infrastructure/clients/http/responses/` with `fromJson()` only; never add `toModel()`.
- [ ] Create the datasource interface in `lib/src/infrastructure/datasources/` returning `Either<FailureResponse, XxxResponse>`.
- [ ] Accept domain parameters in the interface, never `XxxRequest`.
- [ ] Create the remote datasource in `lib/src/infrastructure/datasources/remote/` using `IHttpClient`.
- [ ] Create `XxxRequest` inside the concrete datasource implementation and map both sides of the client's `Either<Map, Map>` with `fromJson`.

### 3. Data — repository and extensions

- [ ] Create `lib/src/data/extensions/xxx_response_extension.dart` with `XxxResponse.toModel()`.
- [ ] Create the repository in `lib/src/data/repositories/` receiving the datasource interface, not its concrete implementation.
- [ ] Pass domain parameters directly to the datasource; do not create `XxxRequest` in the repository.
- [ ] Convert `FailureResponse` with `failure.toFailure()` and the response with `response.toModel()`.
- [ ] Use `data.either(...)` when no async operation exists between the two branches; use an early return when it does.

### 4. Presentation — MVI

- [ ] Create a sealed `XxxIntent` covering every user interaction.
- [ ] Create `XxxState` with `copyWith()` and fields before the constructor.
- [ ] Create `XxxNotifier` with `@Riverpod()` and `dispatch(XxxIntent)`.
- [ ] If a service formats or transforms data, create `PresentationData` in `lib/src/presentation/ui/<feature>/data/` or promote shared data to `lib/src/presentation/data/<family>/`.
- [ ] Keep the feature self-contained. Shared widgets go in `lib/src/presentation/widgets/<family>/` and navigation is injected as `VoidCallback` by the location.
- [ ] Create previews under `lib/src/presentation/ui/<feature>/preview/{screens,widgets,mocks}/` with `@TrocadoPreview(group:, name:)`.
- [ ] Run `dart run build_runner build --delete-conflicting-outputs`.

### 5. Tests

- [ ] Add failure tests when introducing a new `Failure` subtype.
- [ ] Test the repository in `test/src/data/repositories/` with a mock `IHttpClient`.
- [ ] Test notifier intents in `test/src/presentation/providers/` with `ProviderContainer` and a mock repository.
- [ ] Run `flutter test` and `flutter analyze`.

## Mandatory rules

- Fields precede constructors in every class.
- Do not add explanatory comments to code.
- Code generation is exclusively for Riverpod providers.
- There is no `use_cases/`; feature logic belongs in the notifier.
- Follow the SDD workflow from the `sdd` command before implementation.
