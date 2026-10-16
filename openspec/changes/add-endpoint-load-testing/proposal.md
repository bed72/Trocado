## Why

O Trocado precisa detectar regressões de desempenho e investigar gargalos nas leituras de despesas e projeções com dados e carga conhecidos. A suíte funcional atual não mede capacidade HTTP; usar o servidor de desenvolvimento ou interpretar resultados locais como capacidade da VPS produziria conclusões inadequadas.

## What Changes

- Introduzir execução manual e separada de testes HTTP de carga com Pest e `pestphp/pest-plugin-stressless`, usando seu motor k6, inicialmente para quatro leituras: despesas, métricas, insights e sugestões.
- Separar regressão calibrada de investigação progressiva de capacidade. Primeiro medir uma referência reproduzível, depois aprovar limites por endpoint/perfil/ambiente.
- Preparar um alvo HTTP dedicado no Lerd com PostgreSQL, contas, tokens e namespaces de recursos exclusivos; o banco do processo Pest não será presumido como banco do servidor HTTP.
- Preparar 20 contas ativas/verificadas com PATs reais e 10 mil despesas por conta (200 mil), datas e distribuição documentadas, sem reutilizar as contas pessoais ou seeds de desenvolvimento.
- Iniciar com aquecimento separado e níveis de concorrência total 1, 5, 10 e 20, por 30 segundos cada, observando recuperação entre níveis. Concorrência não equivale a requests/segundo nem a usuários ativos do produto.
- Distinguir cenário com cota ampliada somente no alvo dedicado de capacidade e cenário que comprova os 60 requests/minuto por usuário originais. Autenticação, autorização e filtro de proprietário permanecem ativos.
- Tornar a URL-alvo configurável para homologação em VPS, com gerador preferencialmente externo e referências de desempenho separadas. Produção e CI automático ficam fora da primeira entrega; homologação remota exige autorização específica antes de provisionar/executar.
- Registrar relatórios sanitizados, falhas/429, latências, vazão, configuração efetiva, versões e limitações, sem tokens ou dados financeiros. Cobrir cache frio/quente, primeira resolução e hits do registro de identidades.
- Conferir compatibilidade e limites reais do Stressless antes de implementar cenários que ele não exponha, especialmente múltiplos tokens, cursor dinâmico, p99 e classificação por status. Não fazer fork/vendor patch nem substituir o motor silenciosamente.

## Capabilities

### New Capabilities

- `endpoint-load-testing`: objetivos, catálogo de cenários, alvo HTTP, isolamento, dados, perfis, calibração, métricas, relatórios, execução e operação local/remota.

### Modified Capabilities

- `test-suite-organization`: classificar carga HTTP externa em uma raiz opt-in própria, por contexto e responsabilidade, sem classificá-la como Unit ou misturá-la à descoberta Feature.
- `test-execution-isolation`: distinguir o comando manual de carga do gate funcional completo e exigir preflight do servidor-alvo além do processo gerador.
- `authenticated-api-rate-limiting`: permitir cota ampliada explicitamente apenas em alvo dedicado não produtivo de capacidade, preservando default de 60, contagem compartilhada e cenário da proteção original.

## Impact

- Na futura implementação: dependências de desenvolvimento e lockfile, entrada manual de carga, testes/suporte dedicados, configuração isolada do alvo Lerd e eventual configuração da cota autenticada nas bordas.
- A organização proposta `tests/Load/<Contexto>/Presentation/Http/` é uma extensão restrita da arquitetura de testes, acompanhada dos deltas e da futura atualização de `ARCHITECTURE.md`; não cria contexto de produto.
- Reutilizar PostgreSQL, Redis, Sanctum e registro Core existentes. Preparação/cleanup pertencem ao tooling de testes, sem novos endpoints de negócio, tabelas de produto, Ports de carga ou dependência de k6 em Domain/Application.
- A seed de desenvolvimento em edição (`ExpenseSeeder`, 10 mil por usuário) não constitui a massa isolada de carga e não será executada contra o banco operacional pelo harness.
- Autorização na elaboração: criar e validar os artefatos desta spec, com dependência dev aprovada para implementação futura. Em 2026-10-16, o usuário autorizou iniciar o apply local pelo STEP 01 (compatibilidade e sondas controladas); progresso e bloqueios estão em `tasks.md`. Esse apply não autoriza por inferência etapas posteriores, publicação ou operações VPS.
