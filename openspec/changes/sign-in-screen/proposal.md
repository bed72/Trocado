# Proposal — sign-in-screen

## Intenção

Implementar a tela de Sign-In do Trocado: primeiro ponto de entrada do usuário após a splash. Permite autenticação com e-mail e senha via API REST.

## Motivação

Backend, repository, datasource e models de autenticação já estão implementados. Falta apenas a camada de apresentação para fechar o fluxo de autenticação.

## Camadas afetadas

- `presentation/` — screen, state, intent, notifier
- `main/` — location (rota), provider do repositório
- `pubspec.yaml` — adição de Riverpod (primeira feature a usar o pacote)
- `main.dart` — ProviderScope
- `app_route.dart` — rota `/sign-in`

## Fora do escopo

- Recuperação de senha (botão presente na UI, onTap vazio)
- Cadastro / criação de conta (botão presente na UI, onTap vazio)
- Refresh token / renovação automática de sessão
- Validação de campo no cliente (formato de e-mail, tamanho mínimo de senha)
- Fluxo de logout
