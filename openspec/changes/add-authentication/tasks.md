## Lote 1: Fundação Laravel Auth e Sanctum

**Objetivo:** Disponibilizar persistência e integração autenticável suportadas pelo Laravel, sem expor endpoints de Authentication.
**Dependências:** nenhuma.
**Orçamento:** máximo de 20 arquivos únicos.
**Estado do lote:** AWAITING_REVIEW
**Escopo previsto:** Dependência Sanctum, migrations, configuração de auth e sessão, integração de `UserModel`, persistência do password hash e verificações focadas de User e arquitetura.

- [x] 1.1 Instalar `laravel/sanctum:^4.3` pelo fluxo oficial compatível com Laravel 13 e revisar os arquivos publicados antes de mantê-los.
- [x] 1.2 Publicar e adaptar a migration oficial de `personal_access_tokens` sem criar tabela própria de sessões ou tokens.
- [x] 1.3 Criar migration para adicionar `password` não exposto à tabela `users`, com backfill irrecuperável para Users preexistentes e rollback explícito.
- [x] 1.4 Configurar expiração Sanctum de 120 minutos, guard/provider Eloquent e sessão web por valores de ambiente, sem segredos no código.
- [x] 1.5 Tornar `UserModel` um `Authenticatable` com `HasApiTokens`, password oculto e casts necessários, sem alterar `UserEntity`.
- [x] 1.6 Adaptar a criação persistente de User para receber password hash somente na borda necessária, sem expô-lo nos contratos de leitura ou Responses.
- [x] 1.7 Executar migrations no Lerd e confirmar schema, índices, hashes e rollback sem criar `authentication_credentials` ou `authentication_sessions`.
- [x] 1.8 Atualizar e executar testes de User e arquitetura para provar que Domain/Application continuam independentes e somente Infrastructure integra Laravel/Sanctum.
- [x] 1.9 Executar o quality gate do lote, incluindo testes focados, Pint e contagem dos arquivos alterados.

## Lote 2: SignUp API completo

**Objetivo:** Entregar cadastro atômico pela API JSON:API sem autenticação implícita.
**Dependências:** Lote 1 aprovado.
**Orçamento:** máximo de 20 arquivos únicos.
**Estado do lote:** PENDING
**Escopo previsto:** Política de senha, orquestração atômica, tradução de conflito, Request, Controller, Response, rota API e testes do contrato de cadastro.

- [ ] 2.1 Implementar a política de senha de 8 caracteres a 72 bytes com preservação exata e confirmação no Request.
- [ ] 2.2 Implementar `SignUp` atômico sobre `users`, com hash Laravel, canonicalização de e-mail pelo contexto User e sem token ou sessão implícitos.
- [ ] 2.3 Traduzir e-mail existente, inclusive conflito concorrente da constraint, para a mesma resposta `409` sem anexar senha ao User existente.
- [ ] 2.4 Implementar Request, Controller e Response de `SignUp` em `POST /api/authentication/sign-up`, com `201`, `Location` e relacionamento User.
- [ ] 2.5 Mapear validação e conflito para erros JSON:API `422` e `409` com `source.pointer` quando aplicável.
- [ ] 2.6 Adicionar testes de limites, espaços, multibyte, confirmação, hash persistido, atomicidade, concorrência relevante, envelope, headers e ausência de segredos.
- [ ] 2.7 Executar o quality gate do lote, incluindo testes focados, arquitetura, validação OpenSpec, Pint e contagem dos arquivos alterados.

## Lote 3: Sessão API com Personal Access Tokens

**Objetivo:** Entregar `SignIn` e `SignOut` de API com Bearer tokens Sanctum, falhas não enumeráveis e controles operacionais.
**Dependências:** Lote 1 aprovado.
**Orçamento:** máximo de 20 arquivos únicos.
**Estado do lote:** PENDING
**Escopo previsto:** Casos de uso de entrada e saída, respostas e rotas API, proteção `auth:sanctum`, rate limiter, expiração, pruning e testes do ciclo de vida do token.

- [ ] 3.1 Implementar `SignIn` de API com verificação pelo provider/hasher Laravel e emissão por `createToken`, sem gerador, digest, Model ou Repository próprios.
- [ ] 3.2 Configurar token Sanctum com expiração de 120 minutos e resposta imediata contendo o plain-text token somente uma vez.
- [ ] 3.3 Implementar `SignOut` de API removendo somente `currentAccessToken()` sob `auth:sanctum`.
- [ ] 3.4 Garantir falha pública idêntica para e-mail inválido, User inexistente, User de backfill e senha incorreta.
- [ ] 3.5 Implementar Controller, Requests, `AccessTokenResponse` e rotas de API para `SignIn` e `SignOut`, com `200`, `204`, `no-store` e `no-cache`.
- [ ] 3.6 Mapear credenciais inválidas, falta de autenticação e throttling para JSON:API `401` e `429`.
- [ ] 3.7 Configurar rate limiter compartilhável de cinco tentativas por minuto por IP e digest do e-mail normalizado, sem e-mail em claro na chave.
- [ ] 3.8 Agendar `sanctum:prune-expired` e garantir que tokens expirados não autentiquem antes ou depois da limpeza física.
- [ ] 3.9 Adicionar testes de múltiplos tokens, expiração, Bearer válido, token revogado, revogação seletiva, envelopes, headers e ausência de segredos.
- [ ] 3.10 Executar o quality gate do lote, incluindo testes focados, arquitetura, validação OpenSpec, Pint e contagem dos arquivos alterados.

## Lote 4: Autenticação web e fechamento operacional

**Objetivo:** Entregar os três fluxos web por sessão Laravel e concluir a verificação integrada da capability.
**Dependências:** Lotes 1, 2 e 3 aprovados.
**Orçamento:** máximo de 20 arquivos únicos.
**Estado do lote:** PENDING
**Escopo previsto:** Endpoints web, redirects, sessão, CSRF, cookies, reutilização do limiter, segurança contra vazamento, allowlist arquitetural, Bruno e verificação final.

- [ ] 4.1 Implementar `SignUp`, `SignIn` e `SignOut` web com guard `web`, redirects, regeneração de sessão, logout, invalidação da sessão e regeneração CSRF.
- [ ] 4.2 Registrar as três rotas web com os nomes definidos na spec, mantendo-as no grupo `web` sem proteger User ou Budget genericamente.
- [ ] 4.3 Manter cookie de sessão Laravel criptografado, `HttpOnly`, `SameSite=Lax` e `Secure` em produção, sem Personal Access Token no transporte web.
- [ ] 4.4 Reutilizar no `SignIn` web o limiter do lote 3 e preservar a mesma falha pública de credenciais inválidas.
- [ ] 4.5 Testar redirects, CSRF, session fixation, invalidação no `SignOut` e autenticação posterior por `auth:sanctum`.
- [ ] 4.6 Verificar que logs, exceptions, dumps, Responses e serialização do Model não contêm password, hash ou token puro indevido.
- [ ] 4.7 Atualizar o allowlist arquitetural somente para integrações entre Authentication Infrastructure e User necessárias ao uso de Auth/Sanctum.
- [ ] 4.8 Adicionar collection Bruno de `SignUp`, `SignIn`, `SignOut`, falhas e token revogado usando variável de runtime para o Bearer token.
- [ ] 4.9 Executar testes focados de User, Authentication, Sanctum, API, web, provider e arquitetura.
- [ ] 4.10 Executar a suíte completa e confirmar que rotas atuais de User e Budget continuam sem autorização genérica.
- [ ] 4.11 Executar `vendor/bin/pint --dirty --format agent` e revisar o diff para segredos, infraestrutura própria duplicada e escopo indevido.
- [ ] 4.12 Validar a mudança OpenSpec em modo strict e aplicar o quality gate final antes de preparar o arquivamento.
