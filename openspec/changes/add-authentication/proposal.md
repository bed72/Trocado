## Why

A aplicação já possui identidades locais em `User`, mas ainda não consegue comprovar quem executa uma requisição nem associar uma senha e sessões revogáveis a essas identidades. Authentication precisa ser introduzido agora como uma capability separada para permitir `SignUp`, `SignIn` e `SignOut` sem incorporar credenciais, contratos Laravel ou detalhes de transporte ao contexto User.

## What Changes

- Introduzir o bounded context `Authentication` conforme as camadas, fronteiras e convenções de `ARCHITECTURE.md` e `.ai/guidelines/`.
- Manter nome, e-mail e identidade em User; Authentication armazenará apenas credenciais e sessões associadas ao `userId`.
- Integrar Authentication a User por um `UserIdentityPort` implementado na Infrastructure, sem importar `UserEntity` ou `EmailValueObject` na Application de Authentication.
- Implementar `SignUp` com nome, e-mail e senha, criando a identidade e a credencial de maneira atômica, sem iniciar sessão implicitamente.
- Implementar `SignIn` por e-mail e senha com erro genérico para e-mail inválido, identidade inexistente, credencial inexistente ou senha incorreta.
- Implementar uma única sessão server-side revogável identificada por token opaco de alta entropia, armazenando somente seu hash.
- Entregar o segredo da sessão por `Authorization: Bearer` na API JSON:API e por cookie protegido no fluxo web Blade, compartilhando expiração, reconhecimento e revogação.
- Implementar `SignOut` como revogação da sessão atual, independentemente do transporte utilizado.
- Produzir um principal autenticado mínimo baseado em `userId`, sem fazer `UserModel` implementar contratos de autenticação do Laravel.
- Aplicar rate limiting ao `SignIn`, emissão de uma sessão nova após autenticação, proteção CSRF no transporte por cookie e respostas que não permitam enumerar usuários.
- Expor Requests, Controllers, Responses e erros coerentes com o padrão JSON:API atual para os endpoints de API.
- Adicionar cobertura das invariantes, casos de uso, persistência, atomicidade, segurança dos tokens, transportes HTTP, bindings e fronteiras arquiteturais.
- Manter password reset, verificação de e-mail, login externo, MFA, gestão de dispositivos, refresh tokens e regras de autorização fora desta mudança.

## Capabilities

### New Capabilities

- `authentication`: Define credenciais locais, `SignUp`, `SignIn`, `SignOut`, sessões opacas server-side, autenticação por Bearer e cookie e integração desacoplada com a identidade de User.

### Modified Capabilities

Nenhuma capability existente. User continua sendo uma identidade independente de autenticação e sua persistência permanece sem senha, token, sessão ou contratos do framework.

## Impact

- Será criado `app/Authentication/{Domain,Application,Infrastructure,Presentation}` sem alterar a responsabilidade de `app/User`.
- A persistência receberá estruturas próprias para credenciais e sessões, referenciando `users.id` sem adicionar colunas de autenticação à tabela `users`.
- Authentication Infrastructure dependerá explicitamente de User Application somente por um Adapter de integração permitido pelo teste de fronteiras; Authentication Application permanecerá restrita aos próprios contratos e Domain.
- O composition root registrará o provider, as rotas, o mecanismo que resolve o principal autenticado e os erros JSON:API de Authentication.
- A API receberá endpoints públicos de `SignUp` e `SignIn`, além de `SignOut` autenticado; o fluxo web poderá transportar a mesma sessão por cookie protegido.
- Nenhuma biblioteca externa de autenticação será presumida. A implementação usará capacidades do Laravel ou uma dependência adicional somente se a fase de implementação demonstrar necessidade e houver aprovação explícita.
- As rotas atuais de User e Budget não receberão autorização genérica nesta mudança; autenticação e regras de acesso por contexto serão conectadas em specs próprias.
