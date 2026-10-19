# Catálogo editorial — revisão 1 proposta

> Histórico: revisão v5 superada pelo feedback posterior do usuário. O catálogo atual proposto está em `editorial-catalog-v6.md`; a aprovação abaixo registra somente a etapa anterior.

**Estado: revisão 1 aprovada pelo usuário em 19/10/2026**, resposta explícita “Aprovar revisão 1” à pergunta sobre o catálogo completo e suas alternativas. Não confundir esta aprovação com testes de runtime ou layout. Versão: `v5-short-editorial`.

Este é o catálogo completo proposto, não apenas exemplos. Cada linha define um par indivisível. Não combinar títulos, descrições ou sufixos de linhas distintas. A variante é escolhida antes da alternativa de identificação. Nenhuma alternativa publica magnitude financeira.

## Convenções e alternativas

- `{category}` conserva o rótulo integral atual, inclusive “Presentes e doações”.
- `{month}`, `{previous_month}` e `{first_month}` usam `mmm/AAAA`, com ano de quatro posições inclusive `0001`. Nunca omitir o ano na virada de calendário.
- `{day}` é o último dia efetivo do fato, sem zero à esquerda. Na comparação corrente, é o último dia completo comum, não o dia da consulta.
- `{identity}` tenta a descrição integral normalizada e editorialmente segura. Se insegura ou se o par exceder o orçamento, usa **o mesmo template e variante**, substituindo somente por `{category} · DD/MM`, a partir do mesmo lançamento. Não corta a descrição nem remove contexto. Sem alternativa válida, falha explicitamente.
- Descrições não são uma fonte confiável de humor: não admitir ofensa, instrução, alegação financeira, dinheiro, percentual ou proporção, inclusive por extenso. Na dúvida, usar categoria/data; nunca registrar o conteúdo em logs. A estratégia técnica de segurança deve ser conservadora, sem declarar uma blacklist garantia semântica universal.
- `até {day}` limita o mês imediatamente anterior à expressão. Em liderança, os dois primeiros meses estão completos e somente o último pode ser parcial. Nos comparativos, os dois intervalos estão escritos integralmente.
- Todos os pares são de uma linha; orçamento `grafemas(title + " " + description) <= 70`, título `<= 24`. Não há emoji obrigatório; esta revisão não usa emojis. O compositor ainda deve contar corretamente emojis e acentos compostos em texto utilizável.
- Categorias de abordagem acolhedora nesta revisão: Saúde, Moradia, Financiamentos, Investimentos, Impostos e taxas, Seguros e Cuidados pessoais. Para os demais assuntos, humor leve de palco/pódio, sem atribuir hábito, causa ou condição financeira.

## 1. Categoria em destaque — habitual

Fato autorizador: líder única elegível no mês selecionado. Metáfora de destaque, não de excesso, frequência ou consumo. Sem afirmação de renda, dieta, delivery, destino de viagem ou gastos externos.

| Variante | Título | Descrição corrente | Descrição encerrada |
| --- | --- | --- | --- |
| 1 | `{category}` | `No palco dos registros: {month} até {day}.` | `No palco dos registros: {month}.` |
| 2 | `{category}` | `Holofote nos registros: {month} até {day}.` | `Holofote nos registros: {month}.` |
| 3 | `{category}` | `Protagonista dos registros: {month} até {day}.` | `Protagonista dos registros: {month}.` |
| 4 | `{category}` | `Levou a cena nos registros: {month} até {day}.` | `Levou a cena nos registros: {month}.` |

## 2. Categoria em destaque — acolhedora

Mesmo fato e elegibilidade do conjunto 1. Reconhecimento limitado ao ato comprovado de registrar a categoria, nunca ao resultado financeiro. Usa o rótulo integral sem ironizar assunto potencialmente delicado.

| Variante | Título | Descrição corrente | Descrição encerrada |
| --- | --- | --- | --- |
| 1 | `{category}` | `Você registrou. Em foco: {month} até {day}.` | `Você registrou. Em foco: {month}.` |
| 2 | `{category}` | `Registro feito, destaque: {month} até {day}.` | `Registro feito, destaque: {month}.` |
| 3 | `{category}` | `Seu registro em destaque: {month} até {day}.` | `Seu registro em destaque: {month}.` |
| 4 | `{category}` | `Valeu por registrar. Em foco: {month} até {day}.` | `Valeu por registrar. Em foco: {month}.` |

## 3. Maior lançamento — habitual

Fato autorizador: maior lançamento com concentração elegível, sem afirmar anormalidade ou excesso. Identificação regular/alternativa usa somente o lançamento selecionado. Caso sua categoria seja acolhedora, usar o conjunto 4 mesmo se a descrição pareça bem-humorada.

| Variante | Título corrente | Título encerrado | Descrição (regular e alternativa) |
| --- | --- | --- | --- |
| 1 | `Maior · {month} até {day}` | `Maior · {month}` | `{identity} em cena.` |
| 2 | `Maior · {month} até {day}` | `Maior · {month}` | `{identity} no palco.` |
| 3 | `Maior · {month} até {day}` | `Maior · {month}` | `{identity} com holofote.` |
| 4 | `Maior · {month} até {day}` | `Maior · {month}` | `{identity} protagonista.` |

## 4. Maior lançamento — acolhedor

Mesmo fato do conjunto 3. Não elogia o valor, não interpreta investimentos como retorno nem financiamentos como dificuldade.

| Variante | Título corrente | Título encerrado | Descrição (regular e alternativa) |
| --- | --- | --- | --- |
| 1 | `Maior · {month} até {day}` | `Maior · {month}` | `{identity}: registro feito.` |
| 2 | `Maior · {month} até {day}` | `Maior · {month}` | `{identity}: você registrou.` |
| 3 | `Maior · {month} até {day}` | `Maior · {month}` | `{identity}: em destaque.` |
| 4 | `Maior · {month} até {day}` | `Maior · {month}` | `{identity}: em foco.` |

## 5. Comparação de totais registrados

Fato autorizador: diferença material e bases elegíveis nos dois períodos. O título é `Total registrado subiu` para aumento e `Total registrado caiu` para redução. Os dois títulos têm quatro variantes completas por modo, compartilhando as descrições abaixo. Comentam mudança de cena, não mérito, economia, fracasso ou previsão. Os meses encerrados são comparados por inteiro; não se sugere média diária.

| Variante | Descrição corrente | Descrição encerrada |
| --- | --- | --- |
| 1 | `{month} 1–{day} vs. {previous_month} 1–{day}. Olha aí.` | `{month} vs. {previous_month}. Olha aí.` |
| 2 | `{month} 1–{day} vs. {previous_month} 1–{day}. Nova cena.` | `{month} vs. {previous_month}. Nova cena.` |
| 3 | `{month} 1–{day} vs. {previous_month} 1–{day}. Mudou o tom.` | `{month} vs. {previous_month}. Mudou o tom.` |
| 4 | `{month} 1–{day} vs. {previous_month} 1–{day}. Outro ato.` | `{month} vs. {previous_month}. Outro ato.` |

## 6. Liderança recorrente — habitual

Fato autorizador: mesma líder única nos três períodos elegíveis. A recorrência distingue esta observação de concentração mensal. Suprime concentração/maior lançamento redundantes, sem ocultar comparações distintas do total.

| Variante | Título | Descrição corrente | Descrição encerrada |
| --- | --- | --- | --- |
| 1 | `{category}` | `Pódio cativo: {first_month}–{month} até {day}.` | `Pódio cativo: {first_month}–{month}.` |
| 2 | `{category}` | `Trio no topo: {first_month}–{month} até {day}.` | `Trio no topo: {first_month}–{month}.` |
| 3 | `{category}` | `Líder de novo: {first_month}–{month} até {day}.` | `Líder de novo: {first_month}–{month}.` |
| 4 | `{category}` | `Pódio em série: {first_month}–{month} até {day}.` | `Pódio em série: {first_month}–{month}.` |

## 7. Liderança recorrente — acolhedora

Mesmo fato do conjunto 6. A categoria lidera somente nos registros; não implica continuidade de hábitos ou ocorrência em todos os dias.

| Variante | Título | Descrição corrente | Descrição encerrada |
| --- | --- | --- | --- |
| 1 | `{category}` | `Líder registrada: {first_month}–{month} até {day}.` | `Líder registrada: {first_month}–{month}.` |
| 2 | `{category}` | `Topo registrado: {first_month}–{month} até {day}.` | `Topo registrado: {first_month}–{month}.` |
| 3 | `{category}` | `Líder nos dados: {first_month}–{month} até {day}.` | `Líder nos dados: {first_month}–{month}.` |
| 4 | `{category}` | `Liderança registrada: {first_month}–{month} até {day}.` | `Liderança registrada: {first_month}–{month}.` |

## 8. Outros em destaque

Fato autorizador: base elegível e limiar existente de participação de Outros, que continua interno. Não afirma que categorias estão erradas ou pendentes. Não obriga conselho.

| Variante | Título | Descrição corrente | Descrição encerrada |
| --- | --- | --- | --- |
| 1 | `Outros em cena` | `Destaque nos registros: {month} até {day}.` | `Destaque nos registros: {month}.` |
| 2 | `Outros no palco` | `Nos registros de {month} até {day}.` | `Nos registros de {month}.` |
| 3 | `Outros com holofote` | `Destaque registrado: {month} até {day}.` | `Destaque registrado: {month}.` |
| 4 | `Outros protagonista` | `Nos registros de {month} até {day}.` | `Nos registros de {month}.` |

## 9. Primeira despesa — somente vigente

Fato autorizador: não existe histórico até a referência. Convite, não conquista por ausência. Período público continua null.

| Variante | Título | Descrição |
| --- | --- | --- |
| 1 | `Vamos começar?` | `Sem registros até {day}/{month}. Cadastre o primeiro.` |
| 2 | `Um começo possível` | `Sem registros até {day}/{month}. Que tal começar?` |
| 3 | `Primeiro passo` | `Sem registros até {day}/{month}. Pode começar por um.` |
| 4 | `No seu ritmo` | `Sem registros até {day}/{month}. Comece quando quiser.` |

## 10. Registros insuficientes no mês

Fato autorizador: existem registros selecionados, mas não sustentam observação financeira elegível. Não promete que mais um lançamento garantirá um Insight. Acolhe o ato de registrar, sem elogiar redução ou deduzir uso diário do app.

| Variante | Título | Descrição corrente | Descrição encerrada |
| --- | --- | --- | --- |
| 1 | `Seu registro conta` | `Pouca base em {month} até {day}. Sem pressa.` | `Pouca base em {month}. Sem pressa.` |
| 2 | `Um passo de cada vez` | `Pouca base em {month} até {day}. Tudo bem.` | `Pouca base em {month}. Tudo bem.` |
| 3 | `No seu ritmo` | `Pouca base em {month} até {day}. Pode seguir.` | `Pouca base em {month}. Pode seguir.` |
| 4 | `Valeu por registrar` | `Pouca base em {month} até {day}. Vamos aos poucos.` | `Pouca base em {month}. Vamos aos poucos.` |

## 11. Mês sem registros, sem inferir ausência na conta

Fato autorizador: ausência no mês selecionado; no vigente existe histórico anterior, e no histórico a existência posterior não altera esse estado. Não convida a cadastrar a primeira despesa nem sugere economia. Período público continua null.

| Variante | Título | Descrição corrente | Descrição encerrada |
| --- | --- | --- | --- |
| 1 | `No seu ritmo` | `{month} sem registros até {day}. Tudo bem.` | `{month} sem registros. Tudo bem.` |
| 2 | `Sem cobrança` | `{month} sem registros até {day}. Sem pressa.` | `{month} sem registros. Sem pressa.` |
| 3 | `Tudo a seu tempo` | `{month} sem registros até {day}. Seguimos por aqui.` | `{month} sem registros. Seguimos por aqui.` |
| 4 | `Pode ir com calma` | `{month} sem registros até {day}. Quando quiser.` | `{month} sem registros. Quando quiser.` |

## Revisão semântica e limites de aprovação

Todos os pares acima foram preparados com fato autorizador explícito. Humor restringe-se a protagonismo/recorrência/mudança registrada. Nenhum texto usa dinheiro, percentual, proporção disfarçada, diagnóstico, julgamento, cota de elogio ou conselho obrigatório. As exceções acolhedoras são deliberadas, não falta de variante.

Contraexemplos rejeitados, inclusive quando aparecem em descrição de usuário: “3 dias sem delivery”, “Você guardou dinheiro”, “metade”, “dobrou”, “um em cada dois”, valores por extenso e ofensas. A ausência de registros não prova o que ocorreu fora do aplicativo. Aumento/redução não prova vitória/fracasso. Metáforas de liderança nunca são usadas em empate.

**Aprovação registrada:** o usuário aprovou todos os conjuntos, inclusive o tom compacto das comparações, os conjuntos acolhedores e o reconhecimento do registro. Testes de tamanho/regex não substituem essa decisão. Layout Flutter não foi validado. Implementação, evidências automatizadas e publicação não são declaradas concluídas por este documento.
