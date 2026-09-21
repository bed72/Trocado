## 1. Fundação Laravel Auth e Sanctum

- [x] 1.1 Instalar `laravel/sanctum:^4.3` pelo fluxo oficial compatível com Laravel 13 e revisar os arquivos publicados antes de mantê-los.
- [x] 1.2 Publicar e adaptar a migration oficial de `personal_access_tokens` sem criar tabela própria de tokens.
- [x] 1.3 Criar migration para adicionar `password` não exposto à tabela `users`, com backfill irrecuperável para Users preexistentes e rollback explícito.
- [x] 1.4 Configurar expiração Sanctum de 120 minutos e provider Eloquent por valores de ambiente, sem segredos no código.
- [x] 1.5 Tornar `UserModel` um `Authenticatable` com `HasApiTokens`, password oculto e casts necessários, sem alterar `UserEntity`.
- [x] 1.6 Adaptar a criação persistente de User para receber password hash somente na borda necessária, sem expô-lo nos contratos de leitura ou Responses.
- [x] 1.7 Executar migrations no Lerd e confirmar schema, índices, hashes e rollback sem criar tabela própria de credenciais ou tokens.
- [x] 1.8 Atualizar e executar testes de User e arquitetura para provar que Domain/Application continuam independentes e somente Infrastructure integra Laravel/Sanctum.
- [x] 1.9 Executar o quality gate da fundação, incluindo testes focados e Pint.
- [x] 1.10 Remover de `.env.example` `SESSION_SECURE_COOKIE`, `SESSION_HTTP_ONLY`, `SESSION_SAME_SITE` e `SANCTUM_STATEFUL_DOMAINS`, manter `SANCTUM_EXPIRATION` e não habilitar `statefulApi()`.

## 2. SignUp API completo

- [x] 2.1 Implementar a política de senha de 6 a 12 caracteres, com ao menos uma letra maiúscula e um número, preservação exata e confirmação no Request.
- [x] 2.2 Implementar `SignUp` atômico sobre `users`, com hash Laravel, canonicalização de e-mail pelo contexto User e sem token implícito.
- [x] 2.3 Traduzir e-mail existente, inclusive conflito concorrente da constraint, para a mesma resposta `409` sem anexar senha ao User existente.
- [x] 2.4 Implementar Request, Controller e Response de `SignUp` em `POST /api/authentication/sign-up`, com `201`, `Location` e relacionamento User.
- [x] 2.5 Mapear validação e conflito para erros JSON:API `422` e `409` com `source.pointer` quando aplicável.
- [x] 2.6 Adicionar testes de limites, espaços, multibyte, confirmação, hash persistido, atomicidade, concorrência relevante, envelope, headers e ausência de segredos.
- [x] 2.7 Executar o quality gate da API de cadastro, incluindo testes focados, arquitetura, validação OpenSpec e Pint.

## 3. Autenticação API com Personal Access Tokens

- [x] 3.1 Implementar `SignIn` de API com verificação pelo provider/hasher Laravel e emissão por `createToken`, sem gerador, digest, Model ou Repository próprios.
- [x] 3.2 Configurar token Sanctum com expiração de 120 minutos e resposta imediata contendo o plain-text token somente uma vez.
- [x] 3.3 Implementar `SignOut` de API removendo somente `currentAccessToken()` sob `auth:sanctum`.
- [x] 3.4 Garantir falha pública idêntica para e-mail inválido, User inexistente, User de backfill e senha incorreta.
- [x] 3.5 Implementar Controller, Requests, `AccessTokenResponse` e rotas de API para `SignIn` e `SignOut`, com `200`, `204`, `no-store` e `no-cache`.
- [x] 3.6 Mapear credenciais inválidas e falta de autenticação para erro JSON:API `401`.
- [x] 3.7 Agendar `sanctum:prune-expired` e garantir que tokens expirados não autentiquem antes ou depois da limpeza física.
- [x] 3.8 Adicionar testes de múltiplos tokens, expiração, Bearer válido, token revogado, revogação seletiva, envelopes, headers e ausência de segredos.
- [x] 3.9 Executar o quality gate da autenticação API, incluindo testes focados, arquitetura, validação OpenSpec e Pint.

## 4. Fechamento operacional

- [x] 4.1 Verificar que logs, exceptions, dumps, Responses e serialização do Model não contêm password, hash ou token puro indevido.
- [x] 4.2 Atualizar o allowlist arquitetural somente para integrações entre Authentication Infrastructure e User necessárias ao uso de Auth/Sanctum.
- [x] 4.3 Adicionar collection Bruno de `SignUp`, `SignIn`, `SignOut`, falhas e token revogado usando variável de runtime para o Bearer token.
- [x] 4.4 Executar testes focados de User, Authentication, Sanctum, API, provider e arquitetura.
- [x] 4.5 Executar a suíte completa e confirmar que rotas atuais de User e Budget continuam sem autorização genérica.
- [x] 4.6 Executar `vendor/bin/pint --dirty --format agent` e revisar o diff para segredos, infraestrutura própria duplicada e escopo indevido.
- [x] 4.7 Validar a mudança OpenSpec em modo strict e aplicar o quality gate final antes de preparar o arquivamento.
- [x] 4.8 Habilitar e testar a proteção contra lazy loading fora de produção no provider de Authentication.
- [x] 4.9 Mover a revogação do token atual da Presentation para `SignOutUseCase → SignOutPort → SignOutAdapter` e documentar a decisão.
