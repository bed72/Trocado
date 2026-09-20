# Trocado — POC Laravel 13

CRUD de Budget com JSON:API Resources nativos do Laravel 13. Veja [ARCHITECTURE.md](ARCHITECTURE.md) para as fronteiras das camadas.

## Padrão de desenvolvimento

`ARCHITECTURE.md` é a referência para decisões estruturais. Features pertencem ao próprio bounded context em `app/<Contexto>/{Domain,Application,Infrastructure,Presentation}`. Domain usa PHP puro; Application depende de Domain e de seus contratos; Laravel é usado diretamente em Infrastructure e Presentation.

Agentes devem começar por [AGENTS.md](AGENTS.md) e pelas regras curtas em [`.ai/guidelines/`](.ai/guidelines/). O Laravel Boost já está instalado para desenvolvimento assistido; consulte seu Search Docs antes de assumir APIs do Laravel ou de packages Laravel instalados. Para atualizar as instruções geradas após mudar as guidelines, execute `php artisan boost:install --guidelines --no-interaction`. Não instale Laravel AI SDK sem uma feature de IA do produto.

O código Budget já existia antes desta convenção documental. Preserve-o ao trabalhar em outras áreas; novas classes devem seguir os nomes e as fronteiras de `ARCHITECTURE.md`.

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

## Chamadas manuais

`amount` é **inteiro em centavos**. As escritas usam o documento JSON:API com `data.type = budgets`; `PATCH` exige `data.id` igual ao identificador da URL. Use `Accept: application/vnd.api+json` e, nas escritas, `Content-Type: application/vnd.api+json`.

```sh
curl -i -X POST http://127.0.0.1:8000/api/budgets \
  -H 'Accept: application/vnd.api+json' -H 'Content-Type: application/vnd.api+json' \
  -d '{"data":{"type":"budgets","attributes":{"amount":12500,"start_date":"2026-09-01","end_date":"2026-09-30"}}}'

curl -i -H 'Accept: application/vnd.api+json' http://127.0.0.1:8000/api/budgets
curl -i -H 'Accept: application/vnd.api+json' http://127.0.0.1:8000/api/budgets/1

curl -i -X PATCH http://127.0.0.1:8000/api/budgets/1 \
  -H 'Accept: application/vnd.api+json' -H 'Content-Type: application/vnd.api+json' \
  -d '{"data":{"type":"budgets","id":"1","attributes":{"amount":19000}}}'

curl -i -X DELETE -H 'Accept: application/vnd.api+json' http://127.0.0.1:8000/api/budgets/1
```

Criação retorna `201` e `Location`; listagem, busca e atualização retornam `200`; exclusão retorna `204`; recurso ausente retorna `404` com `errors` JSON:API. Substitua `1` pelo `id` retornado na criação.
