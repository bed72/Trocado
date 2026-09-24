# Trocado - POC Laravel 13

API JSON:API para registrar gastos de uma pessoa. `Identity` cuida da conta, credenciais e tokens Sanctum; `Expense` cuida das despesas. Veja [ARCHITECTURE.md](ARCHITECTURE.md) para as fronteiras das camadas.

## Padrão de desenvolvimento

`ARCHITECTURE.md` é a referência para decisões estruturais. Features pertencem ao próprio bounded context em `app/<Contexto>/{Domain,Application,Infrastructure,Presentation}`. Domain usa PHP puro; Application depende de Domain e de seus contratos; Laravel é usado diretamente em Infrastructure e Presentation.

Agentes devem começar por [AGENTS.md](AGENTS.md), [ARCHITECTURE.md](ARCHITECTURE.md) e pelas skills locais em [`.opencode/skills/`](.opencode/skills/). O Laravel Boost já está instalado para desenvolvimento assistido; consulte seu Search Docs antes de assumir APIs do Laravel ou de packages Laravel instalados. Não instale Laravel AI SDK sem uma feature de IA do produto.

Os bounded contexts atuais são `Identity` e `Expense`. `Identity` concentra o lifecycle da conta sem levar Laravel, Eloquent ou Sanctum para Domain e Application. Novas classes devem seguir os nomes, dependências e fronteiras definidos em `ARCHITECTURE.md`.

Para os próximos usos de cache, a decisão registrada em [ARCHITECTURE.md](ARCHITECTURE.md#cache-e-consistência) é usar Redis como store padrão compartilhado. A proposta de cache da listagem de Expense, com TTL de 60 segundos e invalidação por conta após escritas confirmadas, está em [`cache-owned-expense-pages`](openspec/changes/cache-owned-expense-pages/); a implementação ainda está pendente.

## Executar localmente

Requer PHP 8.3+ com `pdo_pgsql`, Composer e PostgreSQL. Com Lerd, na raiz do projeto:

```sh
composer install
lerd link
lerd db set postgres
lerd env setup
# Execute database/roles/expense_runtime.sql em ambos os bancos como mantenedor.
# Defina a senha da role com \\password trocado_runtime no psql.
lerd artisan migrate
# Execute database/roles/grant_expense_runtime.sql em ambos os bancos.
```

`lerd db set postgres` provisiona `trocado` e `trocado_testing`; `lerd env setup` configura a conexão local em `.env`. Antes das migrations, execute `database/roles/expense_runtime.sql` com a credencial de manutenção em cada banco (no Lerd: `podman exec -i lerd-postgres psql -U postgres -d <banco> -v ON_ERROR_STOP=1 < database/roles/expense_runtime.sql`), defina uma senha exclusiva com `\password trocado_runtime` no psql e rode as migrations ainda com a credencial de manutenção. Depois das migrations, execute `database/roles/grant_expense_runtime.sql` em cada banco e configure `DB_USERNAME=trocado_runtime` e sua senha somente no ambiente da API; não rode migrations com essa conexão. Mantenha a credencial de manutenção fora do processo HTTP, em um ambiente/execução CLI separado. Execute os dois scripts novamente após recriar qualquer banco, inclusive `_testing`. Não execute `lerd env setup` depois da troca sem conferir a role resultante.

O provisionamento exige dois logins PostgreSQL distintos. Confirme `current_user`, `rolsuper = false`, `rolbypassrls = false`, ausência de ownership de `expenses`, de `TRUNCATE` e de `CREATE` no schema para a conexão HTTP. O acesso administrativo a despesas e backups usa a conexão de manutenção explicitamente; consultas da API sem contexto RLS não veem despesas. Nos testes que migram o schema, use a conexão de manutenção para migrations e limpeza e a role de runtime para requisições; nunca faça isso contra `trocado`.

Para executar sem Lerd, copie `.env.example` para `.env`, configure `DB_HOST`, `DB_PORT`, `DB_DATABASE`, `DB_USERNAME` e `DB_PASSWORD` localmente, crie os bancos PostgreSQL `trocado` e `trocado_testing`, gere a chave com `php artisan key:generate` e aplique o mesmo provisionamento antes de rodar `php artisan migrate` com a conexão de manutenção. Configure `APP_URL` para a URL usada pelo servidor. Não inclua credenciais em arquivos versionados.

Os testes usam exclusivamente `trocado_testing` em PostgreSQL: crie um `.env.testing` local, não versionado, com `DB_USERNAME` e `DB_PASSWORD` da role `trocado_runtime` e `DB_MAINTENANCE_USERNAME` e `DB_MAINTENANCE_PASSWORD` da role de manutenção. Migre `trocado_testing` com a credencial de manutenção antes dos testes (`APP_ENV=testing DB_USERNAME=<mantenedor> DB_PASSWORD=<senha> php artisan migrate --no-interaction` no ambiente PHP), execute `grant_expense_runtime.sql` nesse banco e então rode `lerd test` (ou `php artisan test`). Os testes limpam apenas `_testing` com a conexão de manutenção; a API e as operações sob teste usam exclusivamente a conexão de runtime. A suíte recusa conexões SQLite, `DB_URL`, bancos diferentes e role de runtime privilegiada; não aponte os testes para `trocado`. Dados existentes no SQLite não são copiados. O bootstrap foi validado com PHP 8.5.10, Composer 2.10.3 e Laravel Framework 13.32.0.

## Autenticação

As rotas de User e Expense exigem um Personal Access Token do Sanctum. `SignUp` e `SignIn` são públicos; `SignOut` exige o Bearer token atual. `POST /api/authentication/sign-up` é o único cadastro público de conta.

`POST /api/users` e a listagem global `GET /api/users` não existem e respondem `404`; consumidores que criavam User diretamente devem migrar para SignUp. `GET`, `PATCH` e `DELETE /api/users/{user}` permanecem protegidos e preservam seus contratos JSON:API.

Nomes têm o whitespace externo e repetido normalizado, aceitam somente letras Unicode separadas por espaços e devem conter de 2 a 12 letras, sem contar os espaços. SignUp e atualização aplicam a mesma validação protegida por `NameValueObject` no Domain.

```sh
RUN_ID=$(date +%s)
EMAIL="maria.${RUN_ID}@example.com"
PASSWORD="B${RUN_ID}x"

curl -i -X POST http://127.0.0.1:8000/api/authentication/sign-up \
  -H 'Accept: application/vnd.api+json' -H 'Content-Type: application/vnd.api+json' \
  -d "{\"data\":{\"type\":\"sign-ups\",\"attributes\":{\"name\":\"Maria Silva\",\"email\":\"${EMAIL}\",\"password\":\"${PASSWORD}\",\"password_confirmation\":\"${PASSWORD}\"}}}"

curl -i -X POST http://127.0.0.1:8000/api/authentication/sign-in \
  -H 'Accept: application/vnd.api+json' -H 'Content-Type: application/vnd.api+json' \
  -d "{\"data\":{\"type\":\"access-tokens\",\"attributes\":{\"email\":\"${EMAIL}\",\"password\":\"${PASSWORD}\"}}}"
```

Mantenha `EMAIL`, `PASSWORD` e o valor retornado em `data.attributes.token` como variáveis somente durante a sessão de desenvolvimento. O token puro não pode ser recuperado do banco.

## Registrar uma despesa

`amount` é **inteiro em centavos**. Envie um documento JSON:API com `data.type = expenses`, `Accept: application/vnd.api+json` e `Content-Type: application/vnd.api+json`.

```sh
curl -i -X POST http://127.0.0.1:8000/api/expenses \
  -H "Authorization: Bearer $TOKEN" \
  -H 'Accept: application/vnd.api+json' -H 'Content-Type: application/vnd.api+json' \
  -d '{"data":{"type":"expenses","attributes":{"amount":12500,"category":"other","occurred_on":"2026-09-24"}}}'
```

Criação retorna `201` com o recurso criado; erros de validação retornam `422` em JSON:API.
