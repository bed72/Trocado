# Spec: home-app-bar

## Requirements

---

### Requirement: Buscar dados do usuário autenticado

The system SHALL buscar as informações do usuário via `GET /api/v1/me` ao montar a `HomeScreen`.

#### Scenario: Sucesso na busca

Given o usuário está autenticado e o token é válido
When `UserNotifier.build()` é executado
Then o `AsyncValue` transita para `AsyncData<UserModel>` com `id`, `name`, `email` e `avatar` (nullable)

#### Scenario: Falha na busca

Given a API retorna um erro (ex: 401, 500)
When `UserNotifier.build()` é executado
Then o `AsyncValue` transita para `AsyncError` com a `Failure` correspondente

---

### Requirement: Saudação dinâmica por horário

The system SHALL exibir uma saudação diferente conforme o horário local do dispositivo.

| Horário | Saudação |
|---|---|
| 05:00–11:59 | "Bom dia" |
| 12:00–17:59 | "Boa tarde" |
| 18:00–23:59 | "Boa noite" |
| 00:00–04:59 | "Isso são horas..." |

#### Scenario: Bom dia

Given `DateTime.now().hour` é 9
When `GreetingWidget` é renderizado
Then exibe "Bom dia" acima do nome do usuário

#### Scenario: Boa tarde

Given `DateTime.now().hour` é 14
When `GreetingWidget` é renderizado
Then exibe "Boa tarde" acima do nome do usuário

#### Scenario: Boa noite

Given `DateTime.now().hour` é 20
When `GreetingWidget` é renderizado
Then exibe "Boa noite" acima do nome do usuário

#### Scenario: Isso são horas

Given `DateTime.now().hour` é 3
When `GreetingWidget` é renderizado
Then exibe "Isso são horas..." acima do nome do usuário

---

### Requirement: Avatar com fallback

The system SHALL exibir o avatar do usuário como imagem circular se disponível, ou um ícone `person` caso `avatar` seja `null`.

#### Scenario: Avatar presente

Given `UserModel.avatar` é uma URL válida
When `AvatarWidget` é renderizado
Then exibe `CircleAvatar` com `NetworkImage(avatar)`

#### Scenario: Avatar ausente

Given `UserModel.avatar` é `null`
When `AvatarWidget` é renderizado
Then exibe `CircleAvatar` com `Icon(Icons.person)`

---

### Requirement: Estado de loading com shimmer

The system SHALL exibir um efeito de shimmer (via `skeletonizer`) enquanto os dados do usuário estão sendo carregados.

#### Scenario: Carregando

Given `userNotifierProvider` retorna `AsyncLoading`
When `HomeAppBarWidget` é renderizado
Then exibe o layout completo envolvido em `Skeletonizer` ativo com placeholders

#### Scenario: Carregado

Given `userNotifierProvider` retorna `AsyncData`
When `HomeAppBarWidget` é renderizado
Then exibe avatar real, saudação e nome sem shimmer

---

### Requirement: Ícones de ação clicáveis

The system SHALL exibir dois `IconButton`s no lado direito da AppBar: notificações e configurações.

#### Scenario: Notificação pressionada

Given a `HomeAppBarWidget` está visível
When o usuário toca no ícone de notificações
Then `onNotification` callback é invocado

#### Scenario: Settings pressionado

Given a `HomeAppBarWidget` está visível
When o usuário toca no ícone de configurações
Then `onSettings` callback é invocado

---

### Requirement: Widgets desacoplados e reutilizáveis

The system SHALL implementar `AvatarWidget`, `GreetingWidget` e `HomeAppBarWidget` como `StatelessWidget`s independentes que recebem todos os dados via parâmetros de construtor, sem acesso direto a providers internamente.
