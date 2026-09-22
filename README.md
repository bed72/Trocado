# Trocado - POC Laravel 13

API JSON:API com `Identity` como owner de identidade, credenciais e tokens Sanctum, e `Budget` como owner de Budgets e recorrências. Veja [ARCHITECTURE.md](ARCHITECTURE.md) para as fronteiras das camadas.

## Padrão de desenvolvimento

`ARCHITECTURE.md` é a referência para decisões estruturais. Features pertencem ao próprio bounded context em `app/<Contexto>/{Domain,Application,Infrastructure,Presentation}`. Domain usa PHP puro; Application depende de Domain e de seus contratos; Laravel é usado diretamente em Infrastructure e Presentation.

Agentes devem começar por [AGENTS.md](AGENTS.md), [ARCHITECTURE.md](ARCHITECTURE.md) e pelas skills locais em [`.opencode/skills/`](.opencode/skills/). O Laravel Boost já está instalado para desenvolvimento assistido; consulte seu Search Docs antes de assumir APIs do Laravel ou de packages Laravel instalados. Não instale Laravel AI SDK sem uma feature de IA do produto.

Os bounded contexts atuais são `Identity` e `Budget`. `Identity` concentra o lifecycle da conta sem levar Laravel, Eloquent ou Sanctum para Domain e Application. Novas classes devem seguir os nomes, dependências e fronteiras definidos em `ARCHITECTURE.md`.

## Executar localmente

Requer PHP 8.3+ com SQLite e Composer. Na raiz do projeto:

```sh
composer install
cp .env.example .env
php artisan key:generate
touch database/database.sqlite
php artisan migrate
php artisan serve
```

O `.env.example` usa SQLite. Configure `APP_URL` se iniciar o servidor em outra URL. O bootstrap foi validado com PHP 8.5.10, Composer 2.10.3 e Laravel Framework 13.32.0.

## Autenticação

As rotas de User, Budget e recorrência exigem um Personal Access Token do Sanctum. `SignUp` e `SignIn` são públicos; `SignOut` exige o Bearer token atual. `POST /api/authentication/sign-up` é o único cadastro público de conta.

`POST /api/users` foi removido em uma mudança breaking e responde `405`; consumidores que criavam User diretamente devem migrar para SignUp. `GET`, `PATCH` e `DELETE /api/users` permanecem protegidos e preservam seus contratos JSON:API.

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

## Chamadas de Budget

`amount` é **inteiro em centavos**. As escritas usam o documento JSON:API com `data.type = budgets`; `PATCH` exige `data.id` igual ao identificador da URL. Use `Accept: application/vnd.api+json` e, nas escritas, `Content-Type: application/vnd.api+json`.

```sh
curl -i -X POST http://127.0.0.1:8000/api/budgets \
  -H "Authorization: Bearer $TOKEN" \
  -H 'Accept: application/vnd.api+json' -H 'Content-Type: application/vnd.api+json' \
  -d '{"data":{"type":"budgets","attributes":{"amount":12500,"start_date":"2026-09-01","end_date":"2026-09-30"}}}'

curl -i -H "Authorization: Bearer $TOKEN" -H 'Accept: application/vnd.api+json' http://127.0.0.1:8000/api/budgets
curl -i -H "Authorization: Bearer $TOKEN" -H 'Accept: application/vnd.api+json' http://127.0.0.1:8000/api/budgets/1

curl -i -X PATCH http://127.0.0.1:8000/api/budgets/1 \
  -H "Authorization: Bearer $TOKEN" \
  -H 'Accept: application/vnd.api+json' -H 'Content-Type: application/vnd.api+json' \
  -d '{"data":{"type":"budgets","id":"1","attributes":{"amount":19000}}}'

curl -i -X DELETE -H "Authorization: Bearer $TOKEN" -H 'Accept: application/vnd.api+json' http://127.0.0.1:8000/api/budgets/1
```

Criação retorna `201` e `Location`; listagem, busca e atualização retornam `200`; exclusão retorna `204`; recurso ausente retorna `404` com `errors` JSON:API. Substitua `1` pelo `id` retornado na criação.
