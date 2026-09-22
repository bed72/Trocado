## Why

`User` e `Authentication` dividem a mesma identidade, tabela e lifecycle, mas mantêm dois caminhos incompatíveis de criação: o CRUD cria um principal com password aleatório irrecuperável e `SignUp` cria um principal com credencial conhecida. Consolidar essas responsabilidades em `Identity` estabelece um único owner para conta, credencial e token, elimina a dependência cross-context ampla e prepara ownership futuro sem levar Laravel ao Domain ou à Application.

## What Changes

- Consolidar `app/User` e `app/Authentication` no bounded context `app/Identity`, preservando `Domain`, `Application`, `Infrastructure` e `Presentation`.
- Manter `UserEntity`, `NameValueObject`, `EmailValueObject` e `PasswordValueObject` livres de framework; `UserEntity` carrega o nome canônico como `NameValueObject`, enquanto password hash, Auth, Eloquent e Sanctum permanecem em Infrastructure.
- Normalizar espaços externos e repetidos do nome, aceitar somente letras Unicode separadas por espaços e exigir de 2 a 12 letras, sem contar os espaços, com validação HTTP equivalente à regra de Domain.
- Tornar `SignUp` o único caminho público de criação de conta e remover o fallback de password aleatório do `UserModel`.
- **BREAKING** Remover `POST /api/users`; clientes devem usar `POST /api/authentication/sign-up` para criar uma conta.
- Preservar os demais endpoints, nomes de rota, resource types e documentos JSON:API de User e Authentication, salvo ajustes necessários ao lifecycle unificado.
- Definir as capacidades de Infrastructure `IdentityWritePort`, `CreatePort`, `SignInPort` e `SignOutPort`, cada uma com Adapter próprio e sem objetos Laravel nos contratos.
- Manter `IdentityRepository` para consultas, listagens, atualizações e exclusão ordinária da identidade; `CreatePort` fica restrita ao provisionamento composto do principal autenticável e sua credencial.
- Fazer exclusão de conta revogar seus Personal Access Tokens dentro da unidade atômica antes de remover a identidade.
- Remover as dependências e allowlists cross-context entre Authentication e User e atualizar providers, composition roots, testes, OpenSpec, Bruno e documentação.

## Capabilities

### New Capabilities

- `identity-context`: Define ownership arquitetural, lifecycle único de conta, responsabilidades de Repository e Ports e migração dos contextos User e Authentication para Identity.

### Modified Capabilities

- `authentication`: Torna `SignUp` o único cadastro público e move os fluxos de registro, login, token e logout para o contexto Identity com Ports explícitas.
- `user`: Remove a criação por `POST /api/users`, preserva consulta e manutenção da identidade e integra exclusão ao lifecycle completo da conta.
- `application-data-contracts`: Substitui User e Authentication por Identity na lista de bounded contexts e preserva os contratos de dados na nova propriedade.
- `api-consumer-support`: Atualiza a collection e a documentação consumidora para criar identidades somente por SignUp e não chamar o endpoint removido.

## Impact

- Namespaces, diretórios, providers, imports, bindings, routes, tratamento de exceções e testes de `app/User`, `app/Authentication`, `tests/User` e `tests/Authentication` serão migrados para Identity.
- `POST /api/users` deixará de existir; GET, PATCH e DELETE de User e os endpoints de Authentication permanecerão com os contratos HTTP atuais, exceto pelo cleanup integrado de tokens na exclusão.
- A tabela `users`, a tabela Sanctum e os resource types `users`, `sign-ups` e `access-tokens` serão preservados; não há renomeação destrutiva de tabela nesta mudança.
- A dependência `Authentication Infrastructure -> App\User` e sua allowlist arquitetural serão removidas.
- A collection Bruno, a referência derivada, `ARCHITECTURE.md`, `README.md` e a documentação Obsidian precisarão refletir Identity como owner do lifecycle.
