# Proposal: home-app-bar

## Intenção

Substituir a `AppBarWidget` genérica da `HomeScreen` por uma `HomeAppBarWidget` customizada que exibe informações do usuário autenticado: avatar, saudação dinâmica baseada no horário, nome e dois ícones de ação (notificações e configurações).

## Motivação

A tela inicial precisa de uma identidade visual personalizada para o usuário logado. A saudação varia conforme o horário do dia, tornando a experiência mais contextual. O shimmer via `skeletonizer` garante UX fluida enquanto os dados são carregados da API.

## Camadas afetadas

| Camada | O que muda |
|---|---|
| `infrastructure/` | Novo endpoint `me` em `EndpointKey`; nova `MeResponse`; nova interface `IRemoteUserDataSource` + implementação `RemoteUserDataSource` |
| `data/` | Nova extension `MeResponseExtension.toModel()`; novo `UserRepository` implementando `IUserRepository` |
| `domain/` | Nova interface `IUserRepository` — `UserModel` já existe e não precisa de alterações |
| `presentation/` | Novos widgets: `HomeAppBarWidget`, `AvatarWidget`, `GreetingWidget`; novo `UserNotifier` (`AsyncNotifier`); atualização de `HomeScreen` |
| `main/` | Novos providers: `remoteUserDataSource`, `userRepository` |

## Fora do escopo

- Tela de configurações (o ícone de settings navega para onde a tela existir, ou é um placeholder por ora)
- Tela de notificações
- Upload ou atualização de avatar
- Cache persistente do `UserModel`

## Referência visual

AppBar com dois lados:
- **Esquerda:** avatar circular (fallback: ícone `person`) + coluna com saudação dinâmica (cinza, menor) e nome do usuário (destaque, maior)
- **Direita:** ícone de notificação + ícone de configurações

Enquanto carrega: shimmer nos campos de texto e avatar.
