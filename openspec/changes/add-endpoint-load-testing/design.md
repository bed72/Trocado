## Context

PHP 8.5.11, Laravel 13.34.0, Pest 5.2.1, PHPUnit 13.3.4 e Stressless 5.0.2. O usuário simplificou o escopo para testes de carga simples pela API PHP do plugin. A intenção não é construir um gerador/harness de benchmark próprio.

## Goals / Non-Goals

**Goals:** escolher uma leitura, informar alvo/token, executar concorrência e duração limitadas, observar métricas do plugin e detectar falhas HTTP. Manter descoberta funcional/CI intacta.

**Non-Goals:** JS/Node próprios, adaptação nativa de k6, massa obrigatória 20 × 10 mil, rotação de contas, cursor dinâmico, p99, distribuição por status, calibração/relatórios de campanha, lease/ownership automático de banco ou alterações na cota de produção.

## Decisions

### D1 — Pest/Stressless público, sem adaptação

Os testes usam `stress(url)->headers(...)->concurrently(C)->for(S)->seconds()->run()`. Um processo k6, uma URL fixa e um token por execução. Sem API interna, vendor patch ou scripts JS próprios. O k6 interno do plugin continua sendo uma dependência transitiva de execução, não código a manter no projeto.

O runtime Lerd informa Linux aarch64, e o seletor do plugin escolhe AMD64. A análise inicial tratou isso como bloqueio, mas uma execução real posterior comprovou que o binário selecionado **executa neste ambiente**. Não se afirma execução nativa ARM64; o mecanismo de compatibilidade/emulação não foi inventariado. O download/extração inicial excedeu 128 MiB; o comando Load inicia Pest com `memory_limit=512M`. A prova oficial de 1 segundo/1 concorrente contra `/up` do alvo dedicado fez 14 requests, sucesso 100%, HTTPS habilitado. Essa sonda não comprova os endpoints autenticados nem a capacidade do produto.

### D2 — Entrada manual e organização

`composer test:load -- --list` lista as quatro entradas; `--list-tests` descobre via `phpunit.load.xml` sem ler configuração ou enviar HTTP. `--scenario=<id>` ou `--endpoint=<path>` seleciona exatamente um arquivo em `tests/Load/<Contexto>/Presentation/Http`. Sem seleção, opção desconhecida ou combinação divergente, falha antes de executar.

O comando funcional `composer test`, `tests/run.php`, `tests/Pest.php`, `phpunit.xml` e o CI não são alterados para acomodar Load. Não usar skip para esconder carga. O processo Load tem prazo de duração configurada + 75s para setup/encerramento; não há escalada automática.

### D3 — Configuração privada e preparação manual

`--config=<path>` ou `TROCADO_LOAD_CONFIG` aponta a JSON v1 privado (sem permissões de grupo/outros, regular, máximo 64 KiB), por caminho absoluto canônico fora do repositório. O argumento contém somente o caminho, nunca o token; o comando propaga esse caminho ao processo Pest, sem depender de variáveis do host serem repassadas pelo Lerd. Campos: `version: 1`, `dedicatedTarget: true`, `targetUrl`, `token`, `concurrency` (default 1, intervalo 1–20), `durationSeconds` (default 5, intervalo 1–30), `p95ThresholdMs` opcional positivo. Não receber tokens/URLs com segredos em argumentos. O alvo-base aceita HTTP/HTTPS local (`localhost`, loopback ou `.test`), sem user/pass/query/fragment/caminho de endpoint.

`dedicatedTarget` é confirmação explícita do operador, **não detecção automática do ambiente ou ownership do servidor**. O operador confere pelo Lerd a instância/DB/Redis e prepara uma conta ativa/verificada, PAT e massa adequados nesse alvo antes de executar. A ferramenta não abre conexão de banco nem provisiona/migra/apaga dados. Recurso pronto não é inferido do banco do Pest. Produção/VPS não fazem parte da versão local.

O alvo criado durante o trabalho anterior é um clone independente da revisão `628c93294ba8d82dc7d87e5cb7599768db543454`, sob `storage/app/private/trocado-load-8c7621d49e0af3b61d45a027` (ignorado, com vendor/.env/bootstrap/cache/storage próprios, sem symlinks para desenvolvimento). Lerd usa custom-FPM próprio, domínio HTTPS próprio e bancos/prefixos exclusivos. O clone não é a massa de carga e os serviços/VM físicos continuam compartilhados. Nenhum seeder pessoal é usado.

### D4 — Preflight e métricas simples

Antes da carga, enviar um GET com a mesma URL/credencial, sem redirect, com timeout de 5s, exigir HTTP 200 e documento JSON:API com `data` e sem `errors`. Esse request fica fora das estatísticas do Stressless. Não é uma prova integrada de ownership/paginação; os testes funcionais continuam responsáveis por isso.

Os quatro cenários medem a URL padrão; sugestões usa `?query=teste`. A leitura começa no estado existente e pode aquecer cache/registro Core: não alegar medição de cache frio. Tokens não são rotacionados; login não ocorre por request. Durante a carga o plugin comprova falhas HTTP, não checks de negócio por resposta. Resposta inválida 200 surgida após o preflight não é automaticamente detectada nesta versão.

Imprimir somente nome técnico do cenário, concorrência/duração, requests/RPS, fração de falhas, p50/p95 (ms). Reprovar zero requests ou fração de falhas diferente de zero. p95 máximo só é exigido quando fornecido pelo operador; sem ele o resultado é uma medição, não aprovação de regressão/SLA. Não fabricar p99 ou classes de status ausentes. Saídas do processo são filtradas pelo token antes de encaminhar ao terminal.

### D5 — Limiter e lifecycle

Conservar o limiter de produto (60/minuto por conta). A carga pode atingir a proteção e reprovar; latência de respostas limitadas não é capacidade da operação. Não retirar middleware ou ampliar cota implicitamente. Se esse limite impedir o objetivo, apresentar o resultado e obter escopo próprio para um perfil de capacidade.

Preparação e remoção de conta/token/dados são manuais no alvo dedicado. O runner não implementa manifesto, lease, limpeza de Redis, criação/drop de bancos ou revogação de tokens do operador. O plugin gerencia seus temporários; configuração secreta permanece privada e não é publicada nos resultados.

## Risks / Trade-offs

- A API simples não valida negócio em cada request e não produz todas as métricas do escopo antigo. Essa redução foi explicitamente escolhida e não é apresentada como cobertura equivalente.
- Limiter/cache/massa influenciam os resultados; registrar a preparação e não inferir número de usuários humanos/capacidade VPS.
- O plugin usa k6 AMD64 neste runtime ARM64 compatível; resultados pertencem a essa topologia e não são referência de gerador nativo.

## Migration Plan

1. Retirar spike/adaptação JS/Node e lifecycle de campanha; preservar histórico em tasks.
2. Implementar testes PHP, configuração privada mínima, seleção e relatório das métricas suportadas.
3. Verificar limites/descoberta/segredos, Pint, testes focados e OpenSpec.
4. Documentar execução e inventário do alvo. Só declarar endpoints autenticados medidos após uma execução real deles.

## Open Questions

As sondas autenticadas foram executadas com uma conta de teste sem despesas e PAT de uma hora, preparado manualmente no alvo dedicado. Para medir consultas representativas, o operador ainda precisa preparar massa adequada e renovar a credencial quando expirar. Isso não equivale a benchmark realizado; resultados e recursos mantidos estão em tasks.
