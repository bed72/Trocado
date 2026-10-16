## Why

O usuário quer testes de carga simples com Pest. O planejamento inicial de 51 tarefas cresceu para um harness de capacidade/benchmark que não corresponde à necessidade imediata. Após discutir as limitações do Stressless e a adaptação k6/JS, o usuário confirmou: “Também to achando. Só queria teste de carga”. Esta revisão substitui explicitamente aquele escopo.

## What Changes

- Executar carga HTTP manual pelos testes PHP do Pest e API pública `Pest\Stressless\stress()`, uma rota e uma credencial por execução.
- Cobrir as leituras de despesas, métricas, insights e sugestões; sugestões usam a query fixa `teste` nesta versão.
- Manter `test:load`, XML separado e cenários por contexto fora da descoberta Unit/Feature e do CI automático.
- Receber alvo local dedicado, token e limites em JSON privado externo. O operador prepara e confirma o alvo; a ferramenta não provisiona, migra, cria massa ou limpa banco/Redis/contas.
- Fazer preflight HTTP 200/JSON:API, medir total/RPS, fração de falhas, p50/p95 e reprovar falhas HTTP. p95 máximo é opcional e informado pelo operador.
- Usar apenas o k6 que o próprio plugin instala/executa, sem JS próprio, Node auxiliar, patches de vendor ou runtime adaptado.

Ficam fora desta versão: rotação de contas/tokens, cursores dinâmicos sob carga, 200 mil despesas obrigatórias, perfis de cota, p99, decomposição por status, agregação entre geradores, manifesto/lease de campanha, calibração automatizada, execução VPS/produção e diagnóstico de capacidade. Correção de ownership/paginação continua pertencendo aos testes funcionais.

## Capabilities

### New Capabilities

- `endpoint-load-testing`: carga HTTP local simples com Pest/Stressless.

### Modified Capabilities

- `test-suite-organization`: raiz Load opt-in por contexto/Presentation/Http.
- `test-execution-isolation`: carga manual separada do launcher/gate funcional existente.

## Impact

- Dependência dev Stressless já instalada; comando, testes e suporte exclusivos de Load. Não há mudanças em app, migrations, limiter, launcher funcional ou workflow CI.
- A adaptação experimental e o lifecycle de campanha do escopo anterior são retirados. O alvo Lerd criado é preservado e inventariado em tasks; sua preparação não é confundida com medição concluída.
- Checklist/evidências do escopo anterior ficam explicitamente históricos em tasks. Pendências excluídas do escopo não viram tarefas implementadas nem provas de desempenho.
