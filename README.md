# Trocado

API JSON:API em Laravel 13 para gerenciar despesas pessoais. `Identity` cuida de contas, aprovação de acesso, credenciais e tokens Sanctum; `Expense` cuida das despesas e da classificação assíncrona. Veja [ARCHITECTURE.md](ARCHITECTURE.md) para as fronteiras das camadas.

## Padrão de desenvolvimento

`ARCHITECTURE.md` é a referência para decisões estruturais. Features pertencem ao próprio bounded context em `app/<Contexto>/{Domain,Application,Infrastructure,Presentation}`. Domain usa PHP puro; Application depende de Domain e de seus contratos; Laravel é usado diretamente em Infrastructure e Presentation.

Agentes devem começar por [AGENTS.md](AGENTS.md), [ARCHITECTURE.md](ARCHITECTURE.md) e pelas skills locais em [`.opencode/skills/`](.opencode/skills/). Laravel Boost auxilia o desenvolvimento; o Laravel AI SDK é usado na classificação de despesas.

Os bounded contexts atuais são `Core`, `Identity`, `Expense`, `Notifications`, `Insights` e `Metrics`. `Identity` concentra o lifecycle da conta sem levar Laravel, Eloquent ou Sanctum para Domain e Application. Novas classes devem seguir os nomes, dependências e fronteiras definidos em `ARCHITECTURE.md`.

O cache da listagem de Expense é implementado em Infrastructure por decorator de `ExpenseRepository`, com TTL de 60 segundos e invalidação por conta após escritas confirmadas. UseCases não conhecem cache, Redis, chaves ou tags.

## Executar localmente

Requer PHP 8.5 com `pdo_pgsql`, Composer e PostgreSQL. O cache e as filas usam Redis; para compilar os assets, use Node 22 e npm. Com Lerd, na raiz do projeto:

```sh
composer install
lerd link
lerd db set postgres
lerd env setup
lerd artisan migrate
```

`lerd db set postgres` provisiona `trocado` e `trocado_testing`; `lerd env setup` configura a conexão local em `.env`. No Lerd, defina `TRUSTED_PROXIES=*` no `.env` local para reconhecer o HTTPS do proxy. O projeto não usa PostgreSQL Row Level Security nem role de runtime específica para isso. Rode migrations com a conexão normal do ambiente.

Para executar sem Lerd, copie `.env.example` para `.env`, configure `DB_HOST`, `DB_PORT`, `DB_DATABASE`, `DB_USERNAME` e `DB_PASSWORD` localmente, crie os bancos PostgreSQL `trocado` e `trocado_testing`, gere a chave com `php artisan key:generate` e rode `php artisan migrate`. Configure `APP_URL` para a URL usada pelo servidor. Não inclua credenciais em arquivos versionados.

### Organização dos testes

A suíte usa **Pest 5 sobre PHPUnit 13**, organizada por contexto, camada e responsabilidade:

| Localização | Responsabilidade |
| --- | --- |
| `tests/Unit/<Contexto>/Domain/` | Invariantes e cálculos puros. |
| `tests/Unit/<Contexto>/Application/` | Orquestração de UseCases com contratos injetados. |
| `tests/Unit/<Contexto>/Infrastructure/` | Adapters sem bootstrap, com dependências simuladas. |
| `tests/Unit/Architecture/` | Fronteiras, pureza e contratos arquiteturais de `app/`. |
| `tests/Feature/<Contexto>/Infrastructure/` | Persistência PostgreSQL, adapters, providers, notifications e workers. |
| `tests/Feature/<Contexto>/Presentation/Http/` | Requests, responses, middleware e contratos HTTP/JSON:API. |
| `tests/Feature/<Contexto>/Journeys/` | Fluxos deliberadamente integrados com objetivo explícito. |
| `tests/Support/<Contexto>/` | Fixtures, builders, fakes, stubs, spies e helpers reutilizáveis. |

Esse é o padrão para testes novos e arquivos reorganizados; caminhos anteriores ainda existentes podem ser selecionados diretamente. Cada arquivo deve ter uma responsabilidade principal e funcionar sozinho, sem depender da descoberta de outro teste. As convenções completas ficam em [ARCHITECTURE.md](ARCHITECTURE.md#arquitetura-dos-testes).

Use fixtures com estados explícitos e mocks PHPUnit com expectativas locais. Fakes nativos de Laravel/AI SDK continuam apropriados. Prepare identidade diretamente quando cadastro/login não forem o alvo; jornadas HTTP não ativam/verificam contas nem configuram fakes silenciosamente. Builders não reparam entradas negativas nem calculam o esperado pela rotina testada.

### Testes e preflight PostgreSQL

Use `lerd composer test -- <caminho/opções Pest>` (sem Lerd: `composer test -- <caminho/opções Pest>`). O launcher cria um banco exclusivo `trocado_testing_<runId>`, registra ownership, confere configuração e `current_database()` e aplica somente migrations pendentes antes dos testes. Ao terminar, remove somente o banco que criou e confirmou como seu; não altera `.env` nem migra o banco operacional. O role PostgreSQL de teste precisa poder criar/remover bancos; ausência de permissão ou serviço produz erro explícito. Configuração em cache deve ser limpa previamente com `lerd artisan config:clear`.

```sh
lerd composer test -- tests/Unit --compact
lerd composer test -- tests/Unit/Architecture --compact
lerd composer test -- tests/Feature/Metrics --compact
lerd composer test -- tests/Feature/Metrics/Infrastructure/Repositories/Persistence/EloquentExpenseMetricsRepositoryTest.php --compact
lerd composer test -- tests/Feature/Identity/Presentation/Http/SignInHttpTest.php --filter="nome do cenário" --compact
lerd composer test -- --compact
lerd composer test -- --group=integration --compact
lerd composer test -- --group=redis --compact
lerd composer test -- --group=concurrency --compact
lerd composer test -- tests/Feature/Core/Infrastructure/Isolation/SimultaneousInvocationsTest.php --compact
lerd composer test -- --parallel --processes=2 --compact --fail-on-skipped --fail-on-incomplete --fail-on-risky
```

Unit puro e listagem (`--list-tests`) não provisionam banco nem executam migrations. Invocações diretas de Pest/PHPUnit/Artisan que tentem executar Feature sem o manifesto do launcher falham antes da limpeza/fixtures e indicam o comando correto. O guard recusa SQLite, `DB_URL`, nome não registrado e destino efetivo/ownership divergentes; não basta conter `testing` no nome. Não use `migrate:fresh`.

O paralelo usa Pest/ParaTest nativos; informe `--processes=2` ou mais (default do launcher: 2). O preflight registra os tokens, prepara incrementalmente `<base>_test_<token>` e valida ownership antes de liberar cada processo. Opções de recriação/drop e desativação dos tokens são recusadas: o launcher controla esse lifecycle. ParaTest aceita um único caminho por invocação; selecione uma pasta, `--testsuite` ou `--group` para conjuntos maiores. Os caminhos de `tests/Feature/{Core,Identity,Expense,Insights,Metrics}` selecionam os contextos.

Cada cenário Feature recebe namespace Redis e filas com runId/token/identidade de cenário e arquivos temporários exclusivos. Cache/limiter comuns continuam array; a integração real seleciona Redis explicitamente. Teardown remove somente as chaves do namespace registrado, sem FLUSHALL/FLUSHDB, limpa `failed_jobs`, `jobs`, tokens, despesas e contas, preserva migrations/sequências e reverte transações abertas. Novas tabelas mutáveis precisam ser classificadas em `TestDatabaseCleanup`; tabela desconhecida interrompe fixtures. O ciclo da aplicação restaura bindings/listeners/fakes/guards, e o suporte restaura relógios/timezone/canais/query logs.

Integrações exigem PostgreSQL com permissão de criar bancos, Redis acessível pelas configurações locais e extensões `pdo_pgsql`, `redis`, `pcntl` e `posix`. Filas exclusivas permitem manter workers locais ativos; e-mail usa transport array e IA fake. O protocolo de concorrência abre conexão PostgreSQL nova, transmite ready/go/done/erro, observa locks reais e aguarda/encerra filhos com prazo limitado. O gate completo acima inclui todos os grupos, inclusive a prova sincronizada de duas invocações paralelas simultâneas; falta de serviço/capacidade e skips não contam como aprovação. As provas de cleanup cobrem falha controlada e término limitado de filhos; SIGKILL do launcher não tem recuperação automática de recursos.

### Verificação de mudanças na suíte

Execute os arquivos alterados isoladamente e depois as suítes afetadas. Após mudanças PHP, execute Pint e repita os testes afetados pelo formatter. Para alterações de suporte compartilhado e fechamento da reorganização, execute o gate completo, sem excluir integrações:

```sh
lerd composer test -- --compact --fail-on-skipped --fail-on-incomplete --fail-on-risky
lerd composer test -- --order-by=random --random-order-seed=20261009 --compact --fail-on-skipped --fail-on-incomplete --fail-on-risky
lerd composer test -- --order-by=random --random-order-seed=20261010 --compact --fail-on-skipped --fail-on-incomplete --fail-on-risky
lerd composer test -- --parallel --processes=2 --compact --fail-on-skipped --fail-on-incomplete --fail-on-risky
```

Registre comandos, seeds, número de processos, resultados, duração e limitações. Ao mover ou consolidar testes, mantenha a correspondência de cada cenário antigo com seu destino ou consolidação justificada. Uma execução verde não prova cenários ausentes: mock não comprova rollback/constraint, chamada manual de job não comprova worker real e repetição sequencial não comprova corrida. Testes editoriais não dependem de IDs incidentais, e observabilidade usa assertions estruturais de JSON. Não ajuste sequência, assertion ou timeout apenas para esconder falha.

Na reclassificação das leituras analíticas como Repositories, os cenários dos dois arquivos abaixo foram preservados integralmente, sem consolidação ou remoção. Cada cenário permanece no arquivo de destino com o mesmo objetivo e assertions comportamentais; mudaram os contratos, as implementações e os bindings referenciados. Ambos os arquivos de destino são executáveis isoladamente pelo launcher.

| Arquivo anterior (todos os cenários) | Destino |
| --- | --- |
| `tests/Feature/Insights/ExpenseAnalysisAdapterTest.php` | `tests/Feature/Insights/Infrastructure/Repositories/Persistence/EloquentExpenseAnalysisRepositoryTest.php` |
| `tests/Feature/Metrics/Infrastructure/Adapters/ExpenseMetricsAdapterTest.php` | `tests/Feature/Metrics/Infrastructure/Repositories/Persistence/EloquentExpenseMetricsRepositoryTest.php` |

### Dados demonstrativos

Execute `lerd artisan db:seed` e informe a senha quando solicitada no terminal; a entrada fica oculta e é usada para os dois usuários demonstrativos. Os seeders garantem Gabriel Ramos (`developer.bed@gmail.com`) e Kelly Codolino (`kelly.cordolino@gmail.com`) como contas ativas e verificadas. Gabriel recebe despesas do mês atual até a data da execução e dos cinco meses anteriores; Kelly não recebe despesas. Despesas existentes são preservadas, e executar novamente não duplica os registros demonstrativos identificados por `[Demo]`.

## Produção

O Dokploy publica `docker-compose.yml`: o serviço `migrate` aplica as migrations antes de iniciar `web`, os workers `queue` e `expense-classification`, e `scheduler`. A imagem usa PHP 8.5 com Apache, atrás do Traefik; os assets são compilados com Node 22. A extensão PHP Redis é instalada a partir do arquivo da versão 6.3.0, com tentativas de download, sem consultar o catálogo do PECL. PostgreSQL e Redis são serviços separados, acessados pelos hosts internos do Dokploy; suas portas não precisam ser publicadas na internet.

Configure os valores de produção na aba **Environment** do Compose, sem versionar `.env` nem credenciais: `APP_ENV=production`, `APP_DEBUG=false`, uma `APP_KEY` própria, `APP_URL` com HTTPS, `DB_*`, `REDIS_*`, `QUEUE_CONNECTION=redis`, `CACHE_STORE=redis` e `CACHE_LIMITER_STORE=redis`. Para usar a classificação automática, configure `EXPENSE_CLASSIFICATION_API_KEY` ou a credencial do provedor de IA selecionado. Confira o resultado do deploy nos logs do Dokploy e pelo endpoint `/up`; esse endpoint confirma o boot da aplicação, não substitui a verificação do banco, Redis e workers.

Defina `TRUSTED_PROXIES` com o IP interno do Traefik na rede `dokploy-network`, em vez do fallback `*`: consulte o IP atual com `docker inspect -f '{{json .NetworkSettings.Networks}}' dokploy-traefik` e confirme nos logs de `web` que ele aparece como origem de uma requisição externa. Ao recriar o Traefik, confira novamente o IP. O proxy termina o HTTPS e encaminha a requisição ao Apache por HTTP; `APP_URL` com HTTPS e o proxy confiável permitem validar os links assinados de confirmação de e-mail. Após mudar essas configurações, solicite um novo link para testar.

Para envio via Resend, configure `MAIL_MAILER=resend`, `RESEND_API_KEY`, `MAIL_FROM_NAME` e `MAIL_FROM_ADDRESS` na aba **Environment**. O domínio de `MAIL_FROM_ADDRESS` precisa estar verificado na conta Resend da chave usada; não precisa ser o mesmo domínio da API. O worker `queue` processa as notificações. No Apache, `ServerTokens Prod` e `ServerSignature Off` omitem a versão nos cabeçalhos/erros, e `expose_php=Off` remove o cabeçalho de versão do PHP; o servidor ainda pode se identificar como Apache. `mod_deflate` comprime HTML, CSS, JavaScript e respostas JSON/JSON:API quando o cliente aceita gzip. No Lerd local, o servidor é Nginx; nesta máquina, o override deste site usa `server_tokens off` e gzip para tipos textuais. Esse override não é distribuído pelo repositório.

## CI e deploy

O workflow `.github/workflows/ci.yml` roda em pull requests e pushes para `main`: instala as dependências, verifica a formatação com Pint, prepara PostgreSQL exclusivo pelo preflight, executa os testes e compila os assets. **Um push nunca inicia o deploy.** Para publicar, execute manualmente **Actions → Deploy to Dokploy → Run workflow** na branch `main`; esse workflow repete as verificações e só solicita o deploy depois que elas passarem.

Para usar o deploy manual, configure a variável `DOKPLOY_COMPOSE_ID` com o ID do serviço Compose do Trocado (**não** seu App Name) e `DOKPLOY_API_KEY` como secret no ambiente GitHub `production`. Gere a chave de API no perfil do Dokploy, sem colocá-la no repositório. Desative o Autodeploy e quaisquer webhooks diretos do Dokploy para que um push não publique independentemente da Action. A Action solicita o deploy pela API do Dokploy; uma resposta bem-sucedida indica que o pedido foi aceito, não que a aplicação já esteja saudável. Confira o resultado em Deployments e Logs no Dokploy.

## Identificadores e consumo da API

User, Expense, registros push, PATs e recursos de Insights/Metrics/sugestões usam **strings UUIDv7 canônicas**: 36 caracteres com hífens, versão 7, variante RFC 9562 e letras minúsculas, por exemplo `019a6b60-0000-7000-8000-000000000001`. Caixa equivalente é aceita; inteiro, hash, nil, whitespace e outras versões são rejeitados. Preserve IDs como strings em JSON, rotas, variáveis e armazenamento; não use `parseInt`, conversão numérica ou alteração de bits. UUID não autentica, não escolhe owner e não determina a data financeira. Categorias, centavos, datas, contagens, segredos e IDs técnicos Laravel/SDKs mantêm seus formatos.

Insights, Metrics e sugestões têm UUID estável por owner/identidade lógica. Core persiste somente associação técnica (UUID, owner, namespace, versão, fingerprint e criação), sem fatos ou textos; cada consulta recalcula as informações financeiras. SignOut/troca de PAT não apagam as associações; exclusão da conta remove-as por cascade. Valores ou variantes editoriais não mudam a identidade por si só; período/modo/assunto distintos podem mudá-la. No vigente de Insights, avançar o limite parcial pode mudar o ID; onboarding conserva período interno mesmo expondo `period: null`. Resumo Metrics zero continua sendo um recurso com UUID; sugestões vazias não alocam identidade. Não há endpoint individual do registro Core.

O PAT tem UUID próprio em `access-tokens.id`, e a relação `user` contém o UUID da conta. O Bearer completo continua sendo segredo Sanctum (`id|segredo`), emitido uma vez e com `no-store`; UUID isolado não é credencial. Extensão conserva o ID do PAT. Links assinados são verificados antes de canonicalizar caixa.

### Bruno e variáveis privadas

Use a coleção `bruno/` com uma conta controlada ativa/verificada. Preencha os segredos no armazenamento privado do Bruno (`authEmail`, `authPassword`, `accessToken`, `verificationUrl`, `notificationToken`). Execute Sign In primeiro para capturar `accessToken` e `userId`; Create Expense captura `expenseId` e Create Notification captura `notificationId`. IDs capturados por scripts são variáveis de execução; não salve credenciais, relatórios com corpos/headers ou environments preenchidos no Git. `userId`, `expenseId`, `notificationId` e `notificationInstallationId` são strings. Os exemplos UUID fixos são somente contratuais: forneça uma instalação UUIDv7 gerada legitimamente e persistida pelo cliente.

Para CLI, use arquivo privado fora da coleção com permissão `0600`, `bru run <casos> --env-file <arquivo>` e não exponha segredos via `--env-var`/argumentos. Limite a execução a casos selecionados (Delete User remove a conta); retire PAT/dados criados, invalide o cache somente desse owner e remova arquivos privados ao terminar. Não rode a coleção inteira contra produção. Assertions de estabilidade usam baselines somente em memória da execução; reinicie a execução ao trocar conta ou cenário. Parsing/round trip não equivalem a abertura GUI; execução CLI não comprova homologação Flutter/FCM.

A conversão local do STEP 12 invalidou IDs, PATs, links assinados e cursores anteriores; não existe alias inteiro ou backfill. O bootstrap UUID não é uma migração de dados de produção. Rollback local exige release compatível e nova autorização para recriar apenas o desenvolvimento confirmado, sem promessa de preservação. A collation própria pode sobreviver ao drop de tabelas; qualquer tratamento exige conferir dependências e o alvo, sem CASCADE indiscriminado.

## Autenticação

As rotas de User e Expense exigem um Personal Access Token do Sanctum. `SignUp` e `SignIn` são públicos; `SignOut` exige o Bearer token atual. `POST /api/authentication/sign-up` é o único cadastro público de conta.

Cada cadastro começa com `users.status = pending` e `email_verified_at = null`. O SignUp solicita por fila o envio de um link assinado e temporário; a aceitação do cadastro não comprova a entrega do e-mail. A confirmação por `GET /api/email-verification/{id}/{hash}` é pública, retorna `204` e marca o e-mail como verificado, sem ativar a conta nem emitir token. Um link expirado ou inválido retorna `403`; o reenvio pode ser solicitado em `POST /api/authentication/email-verification/resend`.

Para liberar a conta, altere o status para `active` diretamente no PostgreSQL após conferir o UUID retornado por SignUp: `UPDATE users SET status = 'active' WHERE id = '<UUIDv7 retornado>';`. Use `blocked` para suspender o acesso; o banco aceita somente `pending`, `active` e `blocked`. A migration também deixa as contas anteriores em `pending`. Contas pendentes/bloqueadas recebem `403` no SignIn, com seu estado na resposta JSON:API, e não recebem token; mesmo com status `active`, um e-mail não verificado recebe `403` e não recebe token. As rotas autenticadas verificam o status a cada requisição; mudar o status para `blocked` impede imediatamente o uso de tokens já emitidos. Reativar a conta permite usar novamente tokens ainda não expirados ou revogados. O status aparece em `GET /api/users/{user}` e não pode ser alterado pela API.

Status controla quem pode usar a API, mas não impede que terceiros alcancem endpoints públicos ou solicitem cadastro; para acesso exclusivo à VPS, restrinja a exposição da aplicação por VPN.

`POST /api/users` e a listagem global `GET /api/users` não existem e respondem `404`; consumidores que criavam User diretamente devem migrar para SignUp. `GET`, `PATCH` e `DELETE /api/users/{user}` permanecem protegidos e preservam seus contratos JSON:API.

Nomes têm o whitespace externo e repetido normalizado, aceitam somente letras Unicode separadas por espaços e devem conter de 2 a 32 letras, sem contar os espaços. SignUp e atualização aplicam a mesma validação protegida por `NameValueObject` no Domain.

```sh
RUN_ID=$(date +%s)
EMAIL="maria.${RUN_ID}@example.com"
PASSWORD="B${RUN_ID}x"

curl -i -X POST http://127.0.0.1:8000/api/authentication/sign-up \
  -H 'Accept: application/vnd.api+json' -H 'Content-Type: application/vnd.api+json' \
  -d "{\"data\":{\"type\":\"sign-ups\",\"attributes\":{\"name\":\"Maria Silva\",\"email\":\"${EMAIL}\",\"password\":\"${PASSWORD}\",\"password_confirmation\":\"${PASSWORD}\"}}}"

# Confirme o e-mail recebido e ative o ID retornado por SignUp antes de tentar SignIn.
# UPDATE users SET status = 'active' WHERE id = '<UUIDv7 retornado>';

curl -i -X POST http://127.0.0.1:8000/api/authentication/sign-in \
  -H 'Accept: application/vnd.api+json' -H 'Content-Type: application/vnd.api+json' \
  -d "{\"data\":{\"type\":\"access-tokens\",\"attributes\":{\"email\":\"${EMAIL}\",\"password\":\"${PASSWORD}\"}}}"
```

Mantenha `EMAIL`, `PASSWORD` e o valor retornado em `data.attributes.token` como variáveis somente durante a sessão de desenvolvimento. O token puro não pode ser recuperado do banco.

## Cadastrar instalações push

O cadastro aceita Android/iOS com Flutter Firebase oficial e **token de registro FCM**, `registration_kind = token`. O `installation_id` deve ser **UUIDv7**, gerado legitimamente e persistido pelo cliente por instalação, sem mudar em login/rotação; não é token FCM, FID, token APNs, ID físico ou PK do registro. UUIDv4/outra versão recebe `422` com pointer `/data/attributes/installation_id`, sem eco do destino. Não converta uma instalação v4 alterando bits. A versão do gerador e o payload real precisam ser comprovados na homologação. Nesta fatia, o cadastro não realiza envios Firebase.

O token é cifrado com `APP_KEY`; a unicidade usa um fingerprint SHA-256 separado, calculado sobre provedor, tipo e token exatos, com separadores NUL. Nenhuma chave adicional de notificações é necessária. A migration `recalculate_notification_fingerprints` recalcula os fingerprints antigos a partir do destino cifrado, preservando IDs, ciphertext, geração, sessões e timestamps. Ela falha atomicamente se algum destino não puder ser decifrado ou se houver conflito de unicidade.

As classes de produto usam `Notification`, e a tabela de destinos é `notifications`, renomeada de `push_registrations` por migration incremental com preservação dos registros. Ela não representa mensagens/read_at e não tem o schema do canal database Laravel. O contrato HTTP/JSON:API abaixo mantém o nome `push-registrations`.

A pasta Bruno `Notifications` contém Create/Delete Notification. Configure `notificationInstallationId`, `notificationPlatform` (`android`/`ios`) e `notificationToken` como segredo. O POST salva `notificationId` tanto em `201` quanto em `200`; repita para sincronizar ou troque o token mantendo o UUID para rotacionar. O DELETE usa esse ID. Os exemplos não contêm token real nem disparam Firebase.

`POST /api/push-registrations` exige Bearer Sanctum válido, conta ativa/verificada e usa a cota autenticada compartilhada de 60/min. O documento aceita somente:

```json
{
  "data": {
    "type": "push-registrations",
    "attributes": {
      "installation_id": "019a6b60-0000-7000-8000-000000000002",
      "platform": "android",
      "registration_kind": "token",
      "registration_identifier": "<token FCM obtido pelo cliente>"
    }
  }
}
```

Exemplo contratual, não captura real do cliente. Use `platform = ios` no iOS e envie token FCM, não token APNs direto. O destino aceita 1–4096 bytes ASCII sem whitespace/controle, preservando caixa e bytes exatos. Identificadores são opacos: validação lexical não comprova que Firebase reconhece o token.

Primeiro cadastro retorna `201`; repetição ou rotação na mesma instalação e conta retorna `200` com o mesmo ID. Duas instalações coexistem. Rotação substitui o destino e incrementa sua geração interna; o cliente deve serializar uploads e ressincronizar após login/início/retomada. Instalação de outra conta ou destino já vinculado a outra instalação responde `409`, sem transferência automática. Respostas JSON:API contêm somente ID, instalação, plataforma, provedor e última sincronização, com `Cache-Control: no-store` e sem token/fingerprint/sessão/geração.

`DELETE /api/push-registrations/{registration}` remove registro próprio com `204`, preservando autenticação e outras instalações. ID ausente/alheio/malformado retorna `404` uniforme. Não existe listagem ou endpoint HTTP de envio.

O vínculo pertence à sessão: SignOut confirmado e pruning removem seus registros por cascade; um novo login na mesma conta pode sincronizar a instalação com a nova sessão. Push não estende o login; a fatia futura de envio deverá descartar sessões vencidas mesmo antes de pruning. Na troca de conta, confirme SignOut anterior antes do novo cadastro; logout offline não comunica a revogação ao servidor imediatamente.

Na rotação de `APP_KEY`, preserve a leitura dos destinos existentes pelo mecanismo Laravel de chaves anteriores. O fingerprint SHA-256 não depende dessa chave. A conversão dos fingerprints antigos não possui rollback automático para HMAC, pois a chave anterior foi removida; a reversão requer restaurar os valores e configuração anteriores explicitamente. Não execute rollback destrutivo da migration para apenas desabilitar as rotas.

## Registrar uma despesa

`amount` é **inteiro em centavos**. Envie um documento JSON:API com `data.type = expenses`, `Accept: application/vnd.api+json` e `Content-Type: application/vnd.api+json`.

O catálogo fechado de `category` contém `food`, `health`, `housing`, `leisure`, `shopping`, `services`, `transport`, `education`, `subscriptions`, `financing`, `investments`, `taxes`, `insurance`, `personal_care`, `pets`, `gifts_and_donations`, `travel` e `other`. Os identificadores são iguais na criação, edição, filtros, persistência e agrupamento de Metrics; somente Insights usa rótulos editoriais traduzidos.

As novas categorias distinguem finalidade: `financing` cobre prestações de empréstimo/financiamento, não qualquer compra parcelada; `investments` cobre aportes; `taxes` cobre tributos e taxas administrativas/documentais; `insurance` cobre prêmios de seguro; `personal_care` cobre cuidados pessoais/cosméticos; `pets` cobre produtos e atendimento de animais; `gifts_and_donations` cobre presentes e ajuda sem restituição; `travel` cobre passagens, hospedagem e pacotes com finalidade explícita de viagem. Deslocamentos cotidianos permanecem `transport`. Categoria explícita, inclusive `other`, prevalece sobre sugestões da IA.

Investimentos e financiamentos participam dos totais, percentuais e Insights como valores registrados, sem inferência de consumo, prejuízo, rendimento ou patrimônio. A expansão não recategoriza registros históricos e não exige migration/backfill.

```sh
curl -i -X POST http://127.0.0.1:8000/api/expenses \
  -H "Authorization: Bearer $TOKEN" \
  -H 'Accept: application/vnd.api+json' -H 'Content-Type: application/vnd.api+json' \
  -d '{"data":{"type":"expenses","attributes":{"amount":12500,"category":"other","occurred_on":"2026-09-24"}}}'
```

Criação retorna `201` com o recurso criado; erros de validação retornam `422` em JSON:API. `DELETE /api/expenses/{expense}` remove a despesa definitivamente. A migration `remove_soft_deletes_from_expenses_table` apaga as despesas que já estavam excluídas logicamente e remove `expenses.deleted_at`; revertê-la não recupera esses registros.

## Consultar despesas com filtros e ordenação

`GET /api/expenses` combina critérios antes da paginação e retorna somente despesas da conta autenticada. Descrição continua opcional/nullable na criação, edição e banco.

| Parâmetro | Contrato |
| --- | --- |
| `filter[year]`, `filter[month]`, `filter[day]` | Ano completo, mês completo ou dia civil; mês exige ano, dia exige ambos. Sem filtro não há período corrente implícito |
| `filter[from]`, `filter[to]` | Datas canônicas `Y-m-d`, limites inclusivos e independentes; não combinar com ano/mês/dia |
| `filter[category]` | Categorias separadas por vírgulas, por OU; duplicatas válidas são normalizadas |
| `filter[amount_min]`, `filter[amount_max]` | Centavos inteiros de 0 a 9223372036854775807, limites inclusivos e independentes. Máximo zero retorna coleção vazia |
| `sort` | Até três campos distintos entre `occurred_on`, `amount`, `description`, por prioridade; prefixo `-` significa decrescente |
| `page[size]`, `page[cursor]` | Tamanho padrão 20, intervalo 1–100; cursor opaco dos links `next`/`prev` |

Filtros distintos combinam por E. Faixas invertidas, valores vazios, campos desconhecidos dentro de filter, categorias inválidas e campos de sort repetidos/fora da allowlist produzem `422` JSON:API. Sem sort, a ordem é `occurred_on DESC, id DESC`; ID decrescente desempata todas as ordenações.

Exemplo: `GET /api/expenses?filter[from]=2026-09-01&filter[to]=2026-09-30&filter[category]=food,transport&filter[amount_min]=1000&filter[amount_max]=30000&sort=-occurred_on,amount&page[size]=6`.

Categorias novas e antigas podem ser combinadas: `filter[category]=travel,investments,food,travel` equivale a `food,investments,travel`. Valores semelhantes como `investment` ou tokens desconhecidos como `travel,unknown` retornam `422`; nenhum token inválido é ignorado.

A ordenação alfabética ignora maiúsculas e acentos pela collation ICU `expense_description_ci_ai`. `Água`, `agua` e `ÁGUA` empatam; os próximos campos e ID resolvem o empate. Null equivale à string vazia somente na chave interna de ordenação: vem antes dos textos em ordem crescente e depois em decrescente; o valor público/persistido permanece null. A migration de collation não altera description ou dados existentes.

Use os links devolvidos pela API, que conservam filtros, sort e tamanho. Mudar os critérios, direção ou prioridade exige reiniciar sem cursor. O cursor v2 aceita critérios normalizados equivalentes e mudança de tamanho, mas não consultas incompatíveis; sua posição separa ID UUIDv7 de amount inteiro. Cursores v1/numéricos/legados são rejeitados com `422`, inclusive nos filtros antigos. Cursor e cache não substituem o filtro de proprietário; o cache usa `expense:pages:v3` e não reutiliza páginas numéricas anteriores.

O cache de páginas usa namespace versionado, critérios normalizados e TTL de 60 segundos; CRUD e classificação confirmados invalidam todas as variantes da conta. A coleção Bruno inclui exemplos desabilitados de cada critério; escolha componentes civis ou intervalo, sem ativar ambos. Copie um cursor devolvido para `expenseCursor` antes de ativar esse parâmetro.

## Consultar Insights por mês

`GET /api/insights` aceita somente `filter[year]` e `filter[month]`, ambos presentes ou ambos ausentes. A rota exige Bearer válido, conta ativa e e-mail verificado, e conserva throttle e extensão de sessão.

- Sem filtros, seleciona o mês vigente no timezone da aplicação.
- Vigente: do dia 1 até a data da consulta, inclusive; mesmo no último dia, o dia ainda está em andamento.
- Histórico: do dia 1 ao último dia do mês selecionado, inclusive. Fevereiro segue o calendário civil, incluindo o dia 29 nos anos bissextos.
- Comparações vigentes usam dias completos equivalentes; históricas comparam os totais de dois meses completos, mesmo com durações diferentes. Os limiares de elegibilidade continuam valendo.
- Ano aceita 1–4 dígitos, de 1 a 9999; mês aceita 1–2 dígitos, de 1 a 12. Zeros à esquerda são normalizados. O primeiro mês selecionável é março/0001, pois a análise precisa de dois antecedentes.
- Campos incompletos, mês futuro, valores vazios, sinais, whitespace, frações, expoentes, arrays, parâmetros desconhecidos e duplicados produzem `422` JSON:API com `source.parameter`, sem executar a leitura analítica. Nomes codificados equivalentes também contam como duplicados.
- Filtros no corpo GET não selecionam o mês; somente a query é usada. Meses vazios históricos retornam orientação contextual, sem serem apresentados como a primeira despesa da conta.

Exemplo de mês encerrado quando a data civil da consulta já é posterior a setembro/2026:

```text
GET /api/insights?filter[year]=2026&filter[month]=09
Accept: application/vnd.api+json
Authorization: Bearer <token>
```

Insights reconhece Financiamentos, Investimentos, Impostos e taxas, Seguros, Cuidados pessoais, Pets, Presentes e doações e Viagens, preservando as regras de elegibilidade e deduplicação. O runtime editorial vigente é `v4-monthly-editorial`, com limites de **24 caracteres Unicode no título e 80 na descrição**, após interpolação. Os textos identificam o mês/ano selecionado e distinguem vigente parcial de mês encerrado; as variantes podem manter o título e variar somente a descrição.

O maior lançamento usa sua descrição integral com whitespace normalizado para uma linha, como texto literal. Quando ausente, vazia ou longa demais, usa categoria e data; percentual e contexto são preservados, e o valor exato em BRL é complementar quando cabe. A ordem é descrição com/sem valor, depois categoria/data com/sem valor, sem truncamento ou exposição de ID da despesa. Comparações tentam percentual regular, percentual compacto e alternativa de diferença monetária exata da mesma variante; se nenhum par completo couber, a composição falha explicitamente. BRL é formatado diretamente de centavos exatos, sem float.

Onboarding mantém `period: null`. `first_expense` aparece somente no vigente sem histórico até a consulta; no histórico, meses vazios/insuficientes recebem `insufficient_history` contextualizado. Revisão de Outros exige a base descritiva de cinco despesas, três datas e R$ 100, com participação de pelo menos 50% sem arredondamento para elegibilidade. Os IDs incorporam o período interno mesmo quando ele é null na resposta; conta, tipo, assunto/estado ou período diferente distinguem a identidade. Valores, descrição e variante diária não a alteram por si só. No vigente, avançar o limite parcial muda o período efetivo e pode mudar o ID.

A coleção `bruno/Insights/` contém default (01), vigente explícito (02), histórico completo (03) e cinco rejeições (04–08). Configure `baseUrl` e `accessToken` no ambiente privado de uma conta ativa/verificada. Nos exemplos de sucesso, atualize a variável local `insightsQueryDate` na aba Vars pela data civil da aplicação em `app.timezone`; ela não é enviada à API. Para o vigente, preencha os dois filtros pelo mesmo ano/mês dessa referência. O histórico de setembro/2026 exige referência a partir de outubro/2026; o exemplo futuro exige atualização para o próximo mês antes de cada execução, incluindo a virada dezembro/janeiro. Não use implicitamente o timezone do dispositivo.

Edite filtros pela aba Params para manter a URL sincronizada, sem acrescentar outra ocorrência manualmente. As assertions verificam status/JSON:API, tipos/grupos, períodos e limites em pontos de código Unicode, aceitando as variantes válidas e nenhuma quantidade mínima de cartões. Falhas de leitura/composição respondem com erro explícito, sem coleção parcial ou onboarding fabricado. A validação do layout/acessibilidade Flutter é externa a este repositório.

### Entrega coordenada do catálogo

Consumidores com listas/enums fechados devem aceitar os dezoito identificadores antes da entrega. Atualize conjuntamente enum, instruções/schema do classificador e rótulos de Insights; reinicie os workers residentes de classificação conforme o processo de deploy para que carreguem o código novo. Depois de persistir novas categorias, um rollback deve manter os dezoito valores aceitos: reverter ao enum antigo pode invalidar leituras e métricas. Não converta os valores silenciosamente para `other`; correções de agente/templates podem preservar o catálogo e os dados.

## Eventos de observabilidade

Com `LOG_OBSERVABILITY_STREAM=php://stderr`, os eventos JSON aparecem nos logs do container que executou a operação. Alterações confirmadas de conta e autenticação emitem `user.registered`, `user.updated`, `user.deleted`, `identity.signed_in` e `identity.signed_out`; despesas emitem `expense.created`, `expense.updated`, `expense.deleted` e `expense.classified`. Leituras não emitem eventos de negócio. Eventos HTTP incluem somente `trace_id` UUIDv7 server-owned, igual ao header `X-Request-Id`, sem campo `request_id` duplicado. Workers não herdam correlação do request; IDs nativos de jobs permanecem nativos.

Nos workers, `queue.job_processed` e `queue.job_failed` identificam fila, conexão, job e tentativa. Falhas incluem apenas a classe da exceção, sem sua mensagem ou payload. Esses registros são eventos estruturados, não métricas agregadas ou um dashboard; descrições, valores de despesas, senhas e tokens não são enviados ao canal de observabilidade.
