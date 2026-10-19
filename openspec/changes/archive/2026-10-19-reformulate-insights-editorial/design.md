## Context

A primeira implementação desta change entregou v5-short-editorial. Sua aprovação e os gates estão preservados em tasks e editorial-catalog.md. A avaliação de uma resposta real pelo usuário substituiu essa direção: datas com “Outro ato” não informam nada útil. A revisão atual toma os dois exemplos monetários aprovados como padrão para todos os Insights.

## Goals / Non-Goals

**Goals:** valor real e significado em uma leitura; referências naturais como “em outubro” e “no mesmo intervalo de setembro”; todos os tipos redesenhados; precisão, concisão, segurança e estabilidade.

**Non-Goals:** novas regras analíticas, percentuais, humor obrigatório, promessa de economia/controle, ampliar respostas quantitativas de Metrics, alterar SQL/limiares/UUIDs, inserir dicas em todos os cards, abreviar montantes ou implementar Flutter. Orçamento atual: 80 combinados, título até 24, por escolha explícita do usuário.

## Decisions

### D1. Valor calculado, não apenas direção

Comparações publicam a diferença absoluta entre as duas janelas já elegíveis. Categoria e Outros usam o numerador da razão existente; maior lançamento usa seu próprio numerador. Liderança recorrente precisa transportar **o valor da categoria no mês selecionado**, não a soma de três meses. Acrescentar esse fato tipado ao candidato e preenchê-lo a partir do resumo reconciliado existente, sem query/Repository novo. Domain exige valor positivo para esse fato exclusivo de liderança; identidade e elegibilidade não o incluem.

### D2. Referência natural, com detalhe em period

Meses financeiros usam nomes completos no texto principal, sem dia/ano ou intervalos numéricos obrigatórios. `period` segue fornecendo datas/anos exatos e janelas de comparação; liderança mantém ali o span de três períodos. Comparação vigente diz “mesmo intervalo”, histórica identifica o mês selecionado contra o antecedente, sem chamar meses de durações diferentes de dias equivalentes. Valores vigentes são os registrados até a referência, não previsão de fechamento.

Onboarding histórico, cujo period é null, conserva mês e ano. Não há fatos financeiros elegíveis nesses cards, portanto não inventar valor para atender ao padrão. Se houver base insuficiente mesmo com vários registros, não afirmar necessariamente que há poucos lançamentos.

### D3. Catálogo direto, sem enfeites

Catálogo completo da revisão atual em `editorial-catalog-v6.md`. Quatro variantes completas por conjunto preservam rotação, mas variam redação útil, não frase solta. O conjunto não diferencia humor por categoria: todos os assuntos usam linguagem factual respeitosa. Queda não significa economia; aumento não significa fracasso; investimento não significa retorno; ausência não significa ausência de gasto.

### D4. Precisão e alternativas

Formatar centavos canônicos por operações de string: `35000` → `R$ 350`, `35001` → `R$ 350,01`, `180000` → `R$ 1.800`. Omitir apenas `,00`; jamais arredondar, usar float ou abreviar para mil/mi. Alternativas pertencem à variante escolhida e podem reorganizar o par inteiro; não mudar variante pelo tamanho do montante. Alternativas mais compactas podem deixar o período financeiro apenas no campo público estruturado. Preservam sempre valor integral, assunto e interpretação. Quando nem isso cabe em 80/24, falha explícita sem coleção parcial ou onboarding fabricado.

A descrição do maior lançamento permanece não confiável: rótulos neutros reconhecidos são usados literalmente, sem interpretar marcação/placeholders. Conteúdo desconhecido, ofensivo ou com quantificação fornecida pelo usuário usa categoria/data. Valores publicados provêm exclusivamente dos fatos tipados.

### D5. Seleção e identidade

Preservar supressão semântica por informação/assunto/período e deduplicação textual após composição. Resolver somente o lote final em Core. Valores novos e versão v6 não participam da chave de UUID nem da chave da variante, exceto a versão editorial já usada na rotação. Alterar valor atualiza imediatamente o montante textual sem alterar variante ou UUID por si só. Nenhum estado de visualização.

### D6. Escopo e evidências

Domain/Application puros, sem imports novos entre contextos ou escrita financeira. Repository e thresholds intocados; nenhuma migration. As tarefas 1–5 registram a implementação anterior, não aprovação permanente de v5. O grupo 6 contém o trabalho atual e deve ter sua própria evidência. Atualizar somente assertions pertinentes de Bruno e docs existentes; main specs serão sincronizadas somente por autorização posterior.

## Risks / Trade-offs

- Montante arbitrariamente grande versus 80 grafemas: alternativas curtas conservam valores acima de PHP_INT_MAX; casos sem representação integral viável falham explicitamente. Não esconder esse limite com número arredondado ou frase vazia.
- Mês vigente parcial sem imprimir cutoff: `period` é a fonte exata; texto descreve registros existentes, nunca total previsto do mês fechado.
- Variação de palavra não garante insight novo: rotação não cria nova informação nem exige ineditismo permanente.
- Texto benigno não reconhecido: fallback conservador categoria/data continua deliberado, não classificador geral.
- Revisão de layout e execução do Bruno real continuam externas; testes não equivalem a essas homologações.

## Migration Plan

Atualizar artefatos/catálogo, implementar fatos e composição, ajustar testes, executar isolados/focados/Pint/quality gate e registrar evidências atuais. Publicação futura apenas após autorização, mantendo envelope e UUIDs. Sem migration/backfill/limpeza de dados.

Rollback por release recupera v5 e suas assertions sem tocar fatos/identidades, mas reintroduz a direção editorial rejeitada; requer aceitar esse efeito. Não publicar automaticamente nem arquivar/sincronizar esta change.

## Open Questions

Direção e implementação autorizadas pelo usuário. Catálogo completo v6 apresentado e aprovado explicitamente com “Aprovar e aplicar”; orçamento resolvido por “80 no total (Recomendado)”, mantendo título até 24. O exemplo aprovado tem 72 grafemas, logo não cabia em 70. Layout Flutter não é bloqueante para implementar backend, nem será declarado validado.
