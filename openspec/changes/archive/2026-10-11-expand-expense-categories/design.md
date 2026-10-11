## Context

O catálogo fechado possui dez identificadores em `Core/Domain/Enums/ExpenseCategoryEnum.php`. Expense e Metrics reutilizam esse enum; os Requests, a Entity e a validação de Metrics já consultam o catálogo, enquanto o schema do classificador é derivado de `cases()`. As instruções do agente e os rótulos editoriais de Insights enumeram somente as categorias atuais.

O schema PostgreSQL consultado possui `expenses.category` como `varchar(32)`, sem constraint de valores permitidos. As specs de Expense e Metrics enumeram explicitamente os dez identificadores e precisam de deltas completos. A change ativa `add-monthly-insights-filters` contém evolução editorial ainda pendente, com títulos de 24 caracteres e descrições de 80; seu catálogo aprovado referencia somente as categorias atuais.

O usuário autorizou inicialmente criar a spec das sete categorias sugeridas mais Viagens. Em 11/10/2026, autorizou implementar a etapa de catálogo e classificação (2.1–2.3), incluindo suas verificações focadas, e confirmou a proposta de investimentos, identificadores e critérios de finalidade. As demais etapas e o arquivamento continuam pendentes.

Na sequência, autorizou “Expense e Metrics”: verificar criação, edição e filtros, atualizar expectativas fixas e provar persistência, totais, percentuais e ordenação (3.1–3.3 e 4.1–4.2). A integração editorial de Insights e o fechamento da entrega continuam pendentes.

Depois autorizou “Insights e fechamento” e confirmou os oito rótulos e o escopo de integração sobre o runtime vigente, com revisão adicional do catálogo mensal futuro 24/80. A implementação e verificação dos rótulos desta expansão estão concluídas; a captura operacional de tráfego externo e o fechamento para arquivamento continuam pendentes.

No fechamento, solicitou arquivamento, commit de todas as alterações e push, confirmando a execução das consultas HTTP reais. A captura `ctx=fpm` e o timing/`optimize_route` foram verificados e registrados em `tasks.md`, concluindo as pendências operacionais com limitações de amostra explícitas.

## Goals / Non-Goals

**Goals:** catálogo de dezoito identificadores; critérios de classificação úteis e não sobrepostos por mera forma de pagamento; CRUD/filtros compatíveis; totais e análises completos; rótulos editoriais aprováveis e compactos; preservação de registros existentes e rastreabilidade de verificação.

**Non-Goals:** carteira de investimentos, rendimentos/resgates, saldo patrimonial, controle de contratos/juros/amortização, geração de parcelas, subcategorias, planejamento de viagens, filtros novos, recategorização retroativa, mudanças em autenticação ou arquitetura, novas dependências e migrations.

## Decisions

### 1. Expansão aditiva do catálogo compartilhado

Adicionar os oito cases abaixo ao enum puro de Core. Preservar cases/valores existentes, inclusive `Other`. Não introduzir um cadastro de categorias, um enum por consumidor ou rótulos de UI no Domain compartilhado. Os rótulos pertencem à composição editorial de Insights; a API continua transportando os identificadores.

| Case | Identificador | Rótulo editorial | Escopo de classificação |
| --- | --- | --- | --- |
| Financing | `financing` | Financiamentos | Prestações de financiamento e empréstimo, inclusive consignado |
| Investments | `investments` | Investimentos | Aportes em renda fixa, ações, fundos e previdência privada |
| Taxes | `taxes` | Impostos e taxas | IPTU, IPVA, imposto de renda e taxas administrativas/documentais |
| Insurance | `insurance` | Seguros | Prêmios de seguro de vida, residencial e automóvel |
| PersonalCare | `personal_care` | Cuidados pessoais | Cabeleireiro, barbearia, manicure e cosméticos |
| Pets | `pets` | Pets | Ração, atendimento veterinário, medicamentos e banho/tosa de animais |
| GiftsAndDonations | `gifts_and_donations` | Presentes e doações | Presentes e doações/ajuda financeira sem expectativa de restituição |
| Travel | `travel` | Viagens | Passagens, hospedagem e pacotes com finalidade explícita de viagem |

Todos os identificadores cabem em 32 caracteres e todos os rótulos cabem em 24. Isso não garante que o texto interpolado completo caiba: essa prova pertence à revisão editorial e aos testes posteriores.

Alternativas descartadas: unir financiamento e investimento em uma categoria financeira genérica, pois oculta destinos diferentes; criar subcategorias e cadastro dinâmico, pois ampliaria o escopo e o contrato.

### 2. Semântica do classificador com finalidade explícita

Atualizar as instruções do agente, mantendo schema derivado do enum e conversão defensiva no Adapter. Preservar descrição como dado não confiável, fallback `other`, tentativas limitadas e proteção contra edição concorrente. Não prometer precisão determinística do provedor real a partir de testes com IA fake.

Regras de desempate:

- Forma de pagamento não define categoria: roupa parcelada é `shopping`; prestação explicitamente vinculada a empréstimo ou financiamento é `financing`, inclusive imóvel/veículo.
- Aporte é `investments`; taxa bancária, juros/multa e prestação não são aportes. `taxes` cobre tributos e taxas administrativas/documentais, não toda cobrança chamada taxa. Fora de evidência suficiente, conservar o fallback ou as categorias existentes conforme o significado.
- Prêmio de seguro é `insurance`; consulta/tratamento e plano de saúde permanecem `health`.
- Finalidade específica prevalece sobre o item genérico quando explícita: veterinário é `pets`, cosmético é `personal_care`, produto comprado como presente é `gifts_and_donations`.
- Passagem de férias, hospedagem ou pacote explícito de viagem é `travel`; ônibus cotidiano, combustível e aplicativo de transporte sem finalidade de viagem identificada permanecem `transport`. Refeições, lazer e compras não migram para `travel` apenas porque podem ocorrer durante uma viagem; não existe vínculo de viagem inferido.

Categoria explícita do cliente permanece soberana, mesmo quando a descrição sugerir outra. Não normalizar valores antigos para novos nem reprocessar o histórico.

### 3. Investimentos como saídas registradas, sem nova política analítica

A proposta mantém a política atual: todos os lançamentos elegíveis entram em Metrics e Insights, inclusive `investments` e `financing`. Não excluir categorias do denominador ou modificar critérios de concentração/liderança, comparação, isolamento e ordenação. A aplicação não possui dados para inferir retorno, lucro, consumo ou patrimônio; as mensagens devem falar em valores registrados e participação.

Essa decisão foi confirmada pelo usuário em 11/10/2026 por “Confirmar proposta”. Excluir aportes das análises demandaria alterar requisitos, denominadores e cenários, não apenas o enum.

### 4. Integração de Insights sem conflito de deltas editoriais

Adicionar em `insights` um requisito dedicado aos rótulos e à semântica das categorias expandidas. Não substituir o requisito editorial que `add-monthly-insights-filters` já modifica, evitando duas versões concorrentes do mesmo bloco.

Antes de implementar a integração editorial, revisar a versão efetiva dos templates e coordenar com a change ativa. Se ela ainda estiver pendente, ampliar sua revisão de catálogo e evidências de 24/80 com os oito rótulos, sem marcar tarefas dela como concluídas por esta spec. Se já estiver arquivada, usar o contrato sincronizado. Alternativas compactas devem preservar rótulo integral, fatos e período; nunca truncar ou elevar limites para acomodar a expansão. Não adicionar imports entre contextos nem ampliar allowlists de arquitetura por conveniência.

### 5. Evidência focada e expectativas independentes

Na implementação futura, usar testes existentes e cenários parametrizados focados: lista explícita dos dezoito identificadores, criação/edição/filtro das oito novas categorias, schema e instruções do agente, aplicação de sugestões válidas via fake, persistência e métricas PostgreSQL, rótulos e interpolação de Insights. Uma lista esperada derivada do próprio enum não prova que o catálogo requerido existe.

Verificar regressões de categoria inválida, `other`, categoria explícita e tentativa atrasada sem reescrever testes de orquestração que já cobrem comportamento inalterado. Testes com fake demonstram integração/schema e aplicação de respostas, não qualidade de classificação do modelo real. Leitura das instruções precisa ter evidência própria para cada ambiguidade documentada.

## Risks / Trade-offs

- [Enum ampliado sem rótulos] → entrega coordenada de enum, agente e composição; prova de Insights com cada nova categoria elegível, pois rótulo ausente hoje causa exceção.
- [Sobreposição de viagem/transporte, compra/presente e parcela/financiamento] → finalidade explícita, critérios documentados, categoria manual preservada e fallback sem inferência arbitrária.
- [Rótulos completos estouram templates 24/80] → revisar todos os conjuntos afetados, modos, variantes e alternativas compactas aplicáveis; comprimento isolado do rótulo não é evidência suficiente.
- [Cliente com lista fechada antiga] → comunicar os oito valores e atualizar exemplos existentes; a expansão é aditiva no servidor, mas exige atualização de consumidores fechados.
- [Misturar aporte com consumo] → não chamar aporte de prejuízo/consumo/rendimento; manter interpretação de saídas registradas e explicitar a decisão antes de implementação.
- [Mudanças concorrentes em Insights] → coordenar versão efetiva e evidências com `add-monthly-insights-filters`, sem sobrescrever seu requisito editorial ou suas evidências históricas.

## Migration Plan

1. Após autorização de implementação, atualizar catálogo, instruções e rótulos em uma entrega compatível; atualizar evidências e documentação existente pertinente.
2. Confirmar novamente que o schema efetivo aceita os identificadores. Não criar migration para um catálogo que o banco não restringe; se houver divergência real, revisar o design antes de alterar schema.
3. Executar verificações focadas e Pint; verificar os fluxos HTTP afetados com captura de queries conforme as regras do projeto. Registrar limitações e evidências.
4. Coordenar clientes com enum fechado e reiniciar workers de classificação no deploy conforme o processo operacional existente, para não manter instruções/schema antigos em processos residentes.
5. Não modificar registros históricos. Nenhum backfill ou reprocessamento de classificação é previsto.

Rollback: depois de persistir novas categorias, reverter para o enum antigo pode invalidar leitura e métricas. Corrigir agente/templates mantendo os dezoito valores aceitos é a reversão compatível; remoção ou conversão de categorias exige decisão específica e plano de dados, sem conversão silenciosa para `other`.

## Open Questions

- **Política confirmada:** investimentos entram nos totais e Insights como saídas registradas, conforme confirmação explícita em 11/10/2026.
- **Coordenação editorial realizada:** runtime transitório `v3-monthly-periods`, limites 32/110. O usuário confirmou a integração dos oito rótulos nesta versão e a revisão complementar do catálogo aprovado futuro 24/80, registrada no adendo de `add-monthly-insights-filters/editorial-catalog.md`. Tasks editoriais 4.1–4.3 e pré-requisitos de dados daquela change continuam pendentes, com aprovação/evidências históricas preservadas; esta expansão não antecipa seu apply.
