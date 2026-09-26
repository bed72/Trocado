# Trocado

API JSON:API em Laravel 13 para gerenciar despesas pessoais. `Identity` cuida de contas, aprovação de acesso, credenciais e tokens Sanctum; `Expense` cuida das despesas e da classificação assíncrona. Veja [ARCHITECTURE.md](ARCHITECTURE.md) para as fronteiras das camadas.

## Padrão de desenvolvimento

`ARCHITECTURE.md` é a referência para decisões estruturais. Features pertencem ao próprio bounded context em `app/<Contexto>/{Domain,Application,Infrastructure,Presentation}`. Domain usa PHP puro; Application depende de Domain e de seus contratos; Laravel é usado diretamente em Infrastructure e Presentation.

Agentes devem começar por [AGENTS.md](AGENTS.md), [ARCHITECTURE.md](ARCHITECTURE.md) e pelas skills locais em [`.opencode/skills/`](.opencode/skills/). Laravel Boost auxilia o desenvolvimento; o Laravel AI SDK é usado na classificação de despesas.

Os bounded contexts atuais são `Identity` e `Expense`. `Identity` concentra o lifecycle da conta sem levar Laravel, Eloquent ou Sanctum para Domain e Application. Novas classes devem seguir os nomes, dependências e fronteiras definidos em `ARCHITECTURE.md`.

O cache da listagem de Expense é implementado em Infrastructure por decorator de `ExpenseRepository`, com TTL de 60 segundos e invalidação por conta após escritas confirmadas. UseCases não conhecem cache, Redis, chaves ou tags.

## Executar localmente

Requer PHP 8.3+ com `pdo_pgsql`, Composer e PostgreSQL. O cache e as filas usam Redis; para compilar os assets, use Node 22 e npm. Com Lerd, na raiz do projeto:

```sh
composer install
lerd link
lerd db set postgres
lerd env setup
lerd artisan migrate
```

`lerd db set postgres` provisiona `trocado` e `trocado_testing`; `lerd env setup` configura a conexão local em `.env`. O projeto não usa PostgreSQL Row Level Security nem role de runtime específica para isso. Rode migrations com a conexão normal do ambiente.

Para executar sem Lerd, copie `.env.example` para `.env`, configure `DB_HOST`, `DB_PORT`, `DB_DATABASE`, `DB_USERNAME` e `DB_PASSWORD` localmente, crie os bancos PostgreSQL `trocado` e `trocado_testing`, gere a chave com `php artisan key:generate` e rode `php artisan migrate`. Configure `APP_URL` para a URL usada pelo servidor. Não inclua credenciais em arquivos versionados.

Os testes usam exclusivamente `trocado_testing` em PostgreSQL. Migre esse banco antes dos testes (`APP_ENV=testing php artisan migrate --no-interaction` no ambiente PHP) e então rode `lerd test` ou `php artisan test`. A suíte recusa conexões SQLite, `DB_URL` e bancos diferentes; não aponte os testes para `trocado`. Dados existentes no SQLite não são copiados.

## Produção

O Dokploy publica `docker-compose.yml`: o serviço `migrate` aplica as migrations antes de iniciar `web`, os workers `queue` e `expense-classification`, e `scheduler`. A imagem é construída com PHP 8.5 e os assets com Node 22. PostgreSQL e Redis são serviços separados, acessados pelos hosts internos do Dokploy; suas portas não precisam ser publicadas na internet.

Configure os valores de produção na aba **Environment** do Compose, sem versionar `.env` nem credenciais: `APP_ENV=production`, `APP_DEBUG=false`, uma `APP_KEY` própria, `APP_URL` com HTTPS, `DB_*`, `REDIS_*`, `QUEUE_CONNECTION=redis`, `CACHE_STORE=redis` e `CACHE_LIMITER_STORE=redis`. Para usar a classificação automática, configure `EXPENSE_CLASSIFICATION_API_KEY` ou a credencial do provedor de IA selecionado. Confira o resultado do deploy nos logs do Dokploy e pelo endpoint `/up`; esse endpoint confirma o boot da aplicação, não substitui a verificação do banco, Redis e workers.

## CI e deploy

O workflow `.github/workflows/ci.yml` roda em pull requests e pushes para `main`: instala as dependências, verifica a formatação com Pint, migra um PostgreSQL `trocado_testing` isolado, executa os testes e compila os assets. **Um push nunca inicia o deploy.** Para publicar, execute manualmente **Actions → Deploy to Dokploy → Run workflow** na branch `main`; esse workflow repete as verificações e só solicita o deploy depois que elas passarem.

Para usar o deploy manual, configure a variável `DOKPLOY_COMPOSE_ID` com o ID do serviço Compose do Trocado (**não** seu App Name) e `DOKPLOY_API_KEY` como secret no ambiente GitHub `production`. Gere a chave de API no perfil do Dokploy, sem colocá-la no repositório. Desative o Autodeploy e quaisquer webhooks diretos do Dokploy para que um push não publique independentemente da Action. A Action solicita o deploy pela API do Dokploy; uma resposta bem-sucedida indica que o pedido foi aceito, não que a aplicação já esteja saudável. Confira o resultado em Deployments e Logs no Dokploy.

## Autenticação

As rotas de User e Expense exigem um Personal Access Token do Sanctum. `SignUp` e `SignIn` são públicos; `SignOut` exige o Bearer token atual. `POST /api/authentication/sign-up` é o único cadastro público de conta.

Cada cadastro começa com `users.status = pending`. Para liberar a conta, altere o status para `active` diretamente no PostgreSQL após conferir o ID retornado por SignUp: `UPDATE users SET status = 'active' WHERE id = <ID>;`. Use `blocked` para suspender o acesso; o banco aceita somente `pending`, `active` e `blocked`. A migration também deixa as contas anteriores em `pending`. Cadastros pendentes/bloqueados recebem `403` no SignIn, com seu estado na resposta JSON:API, e não recebem token. As rotas autenticadas verificam o status a cada requisição; mudar o status para `blocked` impede imediatamente o uso de tokens já emitidos. Reativar a conta permite usar novamente tokens ainda não expirados ou revogados. O status aparece em `GET /api/users/{user}` e não pode ser alterado pela API.

Status controla quem pode usar a API, mas não impede que terceiros alcancem endpoints públicos ou solicitem cadastro; para acesso exclusivo à VPS, restrinja a exposição da aplicação por VPN.

`POST /api/users` e a listagem global `GET /api/users` não existem e respondem `404`; consumidores que criavam User diretamente devem migrar para SignUp. `GET`, `PATCH` e `DELETE /api/users/{user}` permanecem protegidos e preservam seus contratos JSON:API.

Nomes têm o whitespace externo e repetido normalizado, aceitam somente letras Unicode separadas por espaços e devem conter de 2 a 12 letras, sem contar os espaços. SignUp e atualização aplicam a mesma validação protegida por `NameValueObject` no Domain.

```sh
RUN_ID=$(date +%s)
EMAIL="maria.${RUN_ID}@example.com"
PASSWORD="B${RUN_ID}x"

curl -i -X POST http://127.0.0.1:8000/api/authentication/sign-up \
  -H 'Accept: application/vnd.api+json' -H 'Content-Type: application/vnd.api+json' \
  -d "{\"data\":{\"type\":\"sign-ups\",\"attributes\":{\"name\":\"Maria Silva\",\"email\":\"${EMAIL}\",\"password\":\"${PASSWORD}\",\"password_confirmation\":\"${PASSWORD}\"}}}"

# Ative o ID retornado por SignUp no PostgreSQL antes de tentar SignIn.
# UPDATE users SET status = 'active' WHERE id = <ID>;

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

## Eventos de observabilidade

Com `LOG_OBSERVABILITY_STREAM=php://stderr`, os eventos JSON aparecem nos logs do container que executou a operação. Alterações confirmadas de conta e autenticação emitem `user.registered`, `user.updated`, `user.deleted`, `identity.signed_in` e `identity.signed_out`; despesas emitem `expense.created`, `expense.updated`, `expense.deleted` e `expense.classified`. Leituras não emitem eventos de negócio. Eventos HTTP incluem o `request_id` devolvido em `X-Request-Id`.

Nos workers, `queue.job_processed` e `queue.job_failed` identificam fila, conexão, job e tentativa. Falhas incluem apenas a classe da exceção, sem sua mensagem ou payload. Esses registros são eventos estruturados, não métricas agregadas ou um dashboard; descrições, valores de despesas, senhas e tokens não são enviados ao canal de observabilidade.
