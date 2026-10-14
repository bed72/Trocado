# Catálogo editorial mensal — revisão 1

## Estado e limites

Catálogo completo da task 1.1. **Revisão 1 aprovada explicitamente pelo usuário**, incluindo todos os textos, variantes, fallbacks e limites: **24 caracteres no título e 80 na descrição**, após interpolação e normalização, contando caracteres Unicode, não bytes. Espaços, pontuação e sinais também contam. Este documento não comprova implementação, testes ou revisão visual Flutter.

Cada linha numerada é um par completo. Expansões temporais e de identificação abaixo são fechadas e determinísticas; não se combinam títulos e descrições aleatoriamente. Existem quatro variantes em cada conjunto temporal/estado, inclusive nas alternativas compactas. A versão editorial de runtime será definida no apply, substituindo a versão anterior.

## Vocabulário e fatos

| Símbolo | Conteúdo |
| --- | --- |
| `{P}` | Mês selecionado, abreviado e com ano: `set/2026`. |
| `{A}` / `{B}` | Mês anterior / segundo anterior, sempre com ano: `dez/2025`, `nov/2025`. |
| `{d}` | Dia inclusivo do limite descritivo vigente, de 1 a 31. |
| `{n}` | Último dia completo comum da comparação vigente; ambos os intervalos começam no dia 1. |
| `{K}` | Rótulo oficial da categoria, sem apelidos nem inferência de conteúdo. |
| `{p}` | Percentual inteiro calculado por half-up para exibição; sem separador de milhares ou abreviação. |
| `{S}` | `+` no aumento e `−` na redução; o sinal não integra `{p}`. |
| `{V}` | Valor exato do maior lançamento em BRL: `R$ 1.200,00`. |
| `{D}` | Diferença absoluta exata entre totais em BRL; o sinal vem de `{S}`. |
| `{I}` | Descrição normalizada integral ou identificação factual `{K} · {data}`. |
| `{data}` | Data de ocorrência `dd/mm`; seu ano é o de `{P}`, presente no título. |

Meses: `jan`, `fev`, `mar`, `abr`, `mai`, `jun`, `jul`, `ago`, `set`, `out`, `nov`, `dez`. Ano civil sempre com quatro posições, inclusive `0001`. Categorias: Alimentação, Saúde, Moradia, Lazer, Compras, Serviços, Transporte, Educação, Assinaturas, Outros. Concentração por categoria e liderança excluem Outros; concentração de lançamento aceita Outros.

Percentual não é calculado a partir do texto nem do valor monetário arredondado. Comparação usa o total anterior como denominador. Os textos descrevem registros do aplicativo, sem afirmar cobertura de todos os gastos, economia, excesso ou melhora de hábitos.

## 1. Concentração por categoria — `category_concentration`

Título em todas as variantes: **`{K}`**. O mês/ano permanece na descrição, inclusive para Assinaturas, evitando exceder 24 ao anexar o período ao título.

| Variante | Vigente: descrição | Encerrado: descrição |
| --- | --- | --- |
| 1 | `{p}% do total registrado em {P} até dia {d}.` | `{p}% do total registrado em {P}, mês completo.` |
| 2 | `Em {P} até dia {d}, representa {p}% do total registrado.` | `Em {P}, representa {p}% do total registrado no mês.` |
| 3 | `Soma {p}% do total registrado em {P} até dia {d}.` | `Soma {p}% do total registrado em {P}, mês completo.` |
| 4 | `Participação de {p}% no total registrado em {P} até dia {d}.` | `Participação de {p}% no total registrado em {P}, mês completo.` |

Participação é limitada a 100%; esses pares dispensam alternativa de magnitude. Cada descrição refere-se à categoria identificada no título.

## 2. Maior lançamento — `expense_concentration`

Título vigente: **`Maior · {P} até {d}`**. Título encerrado: **`Maior despesa · {P}`**. `Até {d}` significa do dia 1 ao dia indicado, inclusive, naquele mês/ano; não significa o mês inteiro.

| Variante | Descrição com valor | Descrição sem valor |
| --- | --- | --- |
| 1 | `{I}: {p}% do total registrado · {V}.` | `{I}: {p}% do total registrado.` |
| 2 | `{I} representa {p}% do total registrado · {V}.` | `{I} representa {p}% do total registrado.` |
| 3 | `{I} responde por {p}% do total registrado · {V}.` | `{I} responde por {p}% do total registrado.` |
| 4 | `{I} soma {p}% do total registrado · {V}.` | `{I} soma {p}% do total registrado.` |

### Identificação e orçamento, por variante

1. Normalizar whitespace da descrição para uma linha e remover espaços nas extremidades. `null` e resultado vazio não são utilizáveis. Marcação permanece texto literal, sem interpretar HTML/Markdown ou instruções.
2. Tentar a descrição integral como `{I}`, com valor. Se não couber, tentar a mesma descrição integral sem valor. **Identificação tem prioridade sobre o valor complementar.**
3. Se a descrição não couber sem valor, ou estiver ausente, usar `{K} · {data}` como `{I}`, primeiro com valor e depois sem valor.
4. Não cortar a descrição, categoria, data, percentual ou número. Não inventar um nome. Não expor ID da despesa nem registrar descrição em logs.

Os títulos são os mesmos nas quatro famílias de identificação/valor, para ambos os modos. Assim, cada família tem quatro pares completos e preserva a rotação. A categoria/data sem valor é a alternativa compacta final; participação é limitada a 100%, logo cabe com todos os rótulos atuais.

## 3. Comparação de totais — aumento e redução

Tipos `registered_amount_increase` e `registered_amount_decrease`. Título em todas as variantes: **`Total · {P}`**. Cada tabela se expande em dois conjuntos de direção, com `{S}` fixado pelo fato. Não usar “economizou”, “gastou demais”, “melhorou” ou “mesmos dias” nos meses encerrados.

### Percentual regular

| Variante | Vigente: descrição | Encerrado: descrição |
| --- | --- | --- |
| 1 | `{S}{p}% no total registrado: dias 1–{n} vs. 1–{n} de {A}.` | `{S}{p}% no total registrado do mês vs. {A} completo.` |
| 2 | `Total registrado: {S}{p}% nos dias 1–{n} vs. 1–{n} de {A}.` | `Total registrado do mês: {S}{p}% vs. {A} completo.` |
| 3 | `Variação de {S}{p}%: total registrado de 1–{n} vs. 1–{n} de {A}.` | `Variação de {S}{p}% no total registrado: mês completo vs. {A}.` |
| 4 | `Nos dias 1–{n}, total registrado {S}{p}% vs. 1–{n} de {A}.` | `Mês completo: total registrado {S}{p}% vs. {A} completo.` |

### Percentual compacto

Se o percentual regular da variante não couber, usar o par compacto **da mesma variante**, com o mesmo título. O texto conserva magnitude, total registrado e ambos os períodos.

| Variante | Vigente: descrição | Encerrado: descrição |
| --- | --- | --- |
| 1 | `{S}{p}% no total registrado; 1–{n} vs. 1–{n} de {A}.` | `{S}{p}% no total registrado; mês completo vs. {A}.` |
| 2 | `Total registrado {S}{p}%; 1–{n} vs. 1–{n} de {A}.` | `Total registrado {S}{p}%; mês completo vs. {A}.` |
| 3 | `1–{n}: {S}{p}% no total registrado vs. 1–{n} de {A}.` | `Mês completo: {S}{p}% no total registrado vs. {A}.` |
| 4 | `Total registrado: {S}{p}%; 1–{n} vs. 1–{n} de {A}.` | `Total registrado: {S}{p}%; mês completo vs. {A}.` |

### Diferença monetária exata

Se nem o percentual compacto couber, usar a diferença monetária exata da mesma variante. `{S}{D}` gera, por exemplo, `+R$ 100,00` ou `−R$ 150,00`. Nunca substituir magnitude por apenas “mais”/“menos”, nem abreviar em “mil”, “mi” ou notação científica.

| Variante | Vigente: descrição | Encerrado: descrição |
| --- | --- | --- |
| 1 | `{S}{D} no total registrado; 1–{n} vs. 1–{n} de {A}.` | `{S}{D} no total registrado; mês completo vs. {A}.` |
| 2 | `Total registrado {S}{D}; 1–{n} vs. 1–{n} de {A}.` | `Total registrado {S}{D}; mês completo vs. {A}.` |
| 3 | `1–{n}: {S}{D} no total registrado vs. 1–{n} de {A}.` | `Mês completo: {S}{D} no total registrado vs. {A}.` |
| 4 | `Total registrado: {S}{D}; 1–{n} vs. 1–{n} de {A}.` | `Total registrado: {S}{D}; mês completo vs. {A}.` |

Em encerrados, “mês completo” qualifica o selecionado e a referência `{A}` designa o mês anterior inteiro, inclusive quando dura mais ou menos dias. Todos os pares trazem o ano de ambos os meses, sem depender do cabeçalho da dashboard. Se nenhuma alternativa da variante couber, falhar composição explicitamente pelo tratamento existente; não mudar de fato, emitir onboarding ou truncar. Não há garantia de acomodar números com quantidade ilimitada de dígitos.

## 4. Liderança recorrente — `category_lead_streak`

Título: **`{K}`**. “Líder”, “maior total” e “primeiro lugar” significam maior valor registrado entre categorias, com liderança única nos três períodos elegíveis. Não afirmam tendência futura. Os dois antecedentes sempre são completos.

| Variante | Vigente: descrição | Encerrado: descrição |
| --- | --- | --- |
| 1 | `Líder registrada em {B}, {A} e {P} até dia {d}.` | `Líder registrada de {B} a {P}, três meses completos.` |
| 2 | `Maior total registrado em {B}, {A} e {P} até dia {d}.` | `Maior total registrado de {B} a {P}, três meses completos.` |
| 3 | `Lidera os registros em {B}, {A} e {P} até dia {d}.` | `Liderou os registros de {B} a {P}, três meses completos.` |
| 4 | `Primeiro lugar nos registros: {B}, {A} e {P} até dia {d}.` | `Primeiro lugar nos registros de {B} a {P}, três meses completos.` |

O limite “até dia” aplica-se somente a `{P}`. Informar anos em todas as referências evita ambiguidade na virada do ano. Os pares cabem com todos os rótulos e anos suportados, sem alternativa adicional.

## 5. Revisão de categorias — `category_review`

Título: **`Outros · {P}`**. Mantém percentual factual e convite à revisão, sem afirmar que a categoria está errada ou revelar o que contém.

| Variante | Vigente: descrição | Encerrado: descrição |
| --- | --- | --- |
| 1 | `{p}% do total registrado até dia {d}. Revise as categorias.` | `{p}% do total registrado no mês. Revise as categorias.` |
| 2 | `Até dia {d}, {p}% do total registrado. Confira as categorias.` | `No mês completo, {p}% do total registrado. Confira as categorias.` |
| 3 | `Soma {p}% do total registrado até dia {d}. Vale revisar as categorias.` | `Soma {p}% do total registrado no mês. Vale revisar as categorias.` |
| 4 | `Até dia {d}: {p}% do total registrado. Reveja as categorias.` | `Mês completo: {p}% do total registrado. Reveja as categorias.` |

## 6. Primeira despesa — `first_expense`

Somente vigente, sem despesas históricas até a data da consulta. Título: **`Primeiro registro`**. O convite não promete que um único cadastro gerará observações financeiras.

| Variante | Descrição |
| --- | --- |
| 1 | `Sem despesas registradas até dia {d} de {P}. Cadastre a primeira.` |
| 2 | `Até dia {d} de {P}, não há despesas registradas. Registre a primeira.` |
| 3 | `Nenhuma despesa registrada até dia {d} de {P}. Adicione a primeira.` |
| 4 | `Registre sua primeira despesa: não há registros até dia {d} de {P}.` |

## 7. Registros insuficientes — `insufficient_history`

Conjunto com registros presentes e nenhuma observação financeira elegível. Não prometer que falta exatamente um registro, nem declarar volume pequeno se a base existe mas não produz fato elegível. Título: **`Análise · {P}`**.

| Variante | Vigente: descrição | Encerrado: descrição |
| --- | --- | --- |
| 1 | `Até dia {d}, os registros não sustentam uma observação financeira.` | `Os registros do mês não sustentam uma observação financeira.` |
| 2 | `Sem base para uma observação financeira nos registros até dia {d}.` | `Sem base para uma observação financeira nos registros do mês completo.` |
| 3 | `Registros até dia {d} insuficientes para uma observação financeira.` | `Registros do mês insuficientes para uma observação financeira.` |
| 4 | `Ainda sem observação financeira com os registros até dia {d}.` | `Sem observação financeira com os registros desse mês completo.` |

## 8. Mês sem registros — `insufficient_history`

Vigente: somente quando há histórico anterior; sem histórico usa primeira despesa. Encerrado: com ou sem histórico até o mês, sem usar fatos posteriores. Título: **`Registros · {P}`**. Não concluir que a conta inteira está vazia.

| Variante | Vigente: descrição | Encerrado: descrição |
| --- | --- | --- |
| 1 | `Nenhuma despesa registrada neste mês até dia {d}.` | `Nenhuma despesa registrada nesse mês completo.` |
| 2 | `O mês está sem despesas registradas até dia {d}.` | `O mês selecionado não tem despesas registradas.` |
| 3 | `Até dia {d}, não há despesas registradas neste mês.` | `Não há despesas registradas no mês selecionado.` |
| 4 | `Sem registros de despesas neste mês até dia {d}.` | `Sem registros de despesas nesse mês completo.` |

## Exemplos para aprovação

Referência ilustrativa: consulta em **12/10/2026**. Os fatos são exemplos editoriais, não dados criados nem evidência de execução da API. Cada cartão exige sua elegibilidade própria; a tabela não representa uma resposta conjunta nem supera deduplicação.

| Caso | Título | Descrição |
| --- | --- | --- |
| Categoria vigente | Alimentação | 40% do total registrado em out/2026 até dia 12. |
| Categoria encerrada | Alimentação | 38% do total registrado em set/2026, mês completo. |
| Categoria longa | Assinaturas | 38% do total registrado em set/9999, mês completo. |
| Descrição utilizável, vigente | Maior · out/2026 até 12 | Aluguel: 54% do total registrado · R$ 1.200,00. |
| Descrição utilizável, encerrado | Maior despesa · set/2026 | Aluguel: 54% do total registrado · R$ 1.200,00. |
| Descrição ausente | Maior despesa · set/2026 | Moradia · 05/09: 54% do total registrado · R$ 1.200,00. |
| Descrição longa e valor extenso que não cabe | Maior despesa · set/2026 | Assinaturas · 05/09 responde por 54% do total registrado. |
| Descrição ausente em Outros | Maior despesa · set/2026 | Outros · 05/09: 54% do total registrado · R$ 1.200,00. |
| Comparação vigente, R$ 500 vs. R$ 400 | Total · out/2026 | +25% no total registrado: dias 1–11 vs. 1–11 de set/2026. |
| Comparação encerrada, R$ 500 vs. R$ 400 | Total · set/2026 | +25% no total registrado do mês vs. ago/2026 completo. |
| Redução encerrada, R$ 350 vs. R$ 500 | Total · set/2026 | −30% no total registrado do mês vs. ago/2026 completo. |
| Comparação entre anos | Total · jan/2026 | +25% no total registrado do mês vs. dez/2025 completo. |
| Percentual extremo compacto | Total · jan/2026 | +12345678901234567890% no total registrado; mês completo vs. dez/2025. |
| Alternativa de magnitude exata | Total · jan/2026 | +R$ 92.233.720.368.547.758,08 no total registrado; mês completo vs. dez/2025. |
| Liderança vigente | Alimentação | Líder registrada em ago/2026, set/2026 e out/2026 até dia 12. |
| Liderança encerrada entre anos | Alimentação | Líder registrada de nov/2025 a jan/2026, três meses completos. |
| Revisão vigente | Outros · out/2026 | 60% do total registrado até dia 12. Revise as categorias. |
| Revisão encerrada | Outros · set/2026 | 60% do total registrado no mês. Revise as categorias. |
| Primeira despesa | Primeiro registro | Sem despesas registradas até dia 12 de out/2026. Cadastre a primeira. |
| Registros insuficientes vigentes | Análise · out/2026 | Até dia 12, os registros não sustentam uma observação financeira. |
| Registros insuficientes históricos | Análise · set/2026 | Os registros do mês não sustentam uma observação financeira. |
| Vigente vazio com histórico | Registros · out/2026 | Nenhuma despesa registrada neste mês até dia 12. |
| Histórico vazio, inclusive antes do primeiro registro | Registros · set/2026 | Nenhuma despesa registrada nesse mês completo. |

## Critérios de aceite editorial e evidência

- Revisar as quatro linhas de cada conjunto, não somente os exemplos. Expansões: concentração de categoria × 2 modos; maior lançamento × 2 modos × 4 famílias de identificação/valor; comparação × 2 modos × 2 direções × 3 famílias de magnitude; liderança × 2 modos; revisão × 2 modos; primeira despesa × vigente; histórico insuficiente × 2 modos × 2 estados.
- Contar os pares interpolados, incluindo dia 31, participação 100%, rótulos oficiais, anos `0001`/`9999`, referências entre anos, descrições no limite e valores acima de `PHP_INT_MAX` em centavos. Valores arbitrariamente longos devem falhar explicitamente se nenhum par seguro existir.
- A variante diária é escolhida antes das alternativas. Valores novos podem mudar a alternativa necessária, mas não a variante por si só. Fallbacks mantêm quatro textos distintos, evitando um único texto compacto em todos os dias.
- Descrição de despesa não utilizável ou longa resulta em categoria/data. Descrição que cabe sem valor não é substituída por categoria/data para acomodar o valor.
- Revisão editorial e contagem de caracteres não provam BRL exato, normalização runtime, rotação, snapshot, isolamento ou contrato HTTP; essas provas continuam nas tasks 3–5 e 7.
- Aprovação registrada abaixo; a task 1.1 está concluída. Implementação runtime e suas verificações continuam nas tarefas posteriores.

### Aprovação editorial

Em 11/10/2026, após apresentação do documento completo, exemplos e ordem de fallbacks, o usuário respondeu **“Aprovar catálogo e 24/80”** à pergunta que explicitamente abrangia todos os textos, variantes e fallbacks da revisão 1. Entrega: **catálogo aprovado para implementação**. Esta aprovação fecha a etapa editorial solicitada; não antecipa a conclusão das tarefas de código, testes, Bruno ou Flutter.

### Contagem editorial realizada

Contagem isolada em Python 3, com os textos transcritos em memória, sem executar a aplicação nem criar script de projeto. Foram verificadas as 72 formas de descrição (18 famílias × 4 variantes) e as oito formas de título. Entradas: dia/intervalo 31, participação 100%, Assinaturas, `jan/9999` com antecedentes de 9998, identificação `Assinaturas · 31/01`, comparação compacta de 20 dígitos e diferença `R$ 92.233.720.368.547.758,08` (centavos acima de `PHP_INT_MAX`).

- Maior título: 24 caracteres (`Maior despesa · jan/9999`); título parcial: 23.
- Descrições não comparativas: máximo 74 (liderança encerrada); identificação factual sem valor: máximo 58.
- Comparação regular com percentual de três dígitos: máximo 65; compacta com percentual de 20 dígitos: máximo 70.
- Alternativa monetária com a diferença acima: máximo 77, nos dois modos.
- Todas essas interpolações ficaram dentro de 24/80. Descrição arbitrária e valores maiores continuam sujeitos à ordem de alternativas e falha explícita; esta contagem não substitui testes futuros de composição.

### Adendo de coordenação — categorias expandidas, 11/10/2026

A aprovação e contagem históricas da revisão 1 acima permanecem preservadas. Na etapa “Insights e fechamento” de `expand-expense-categories`, o usuário confirmou os rótulos Financiamentos, Investimentos, Impostos e taxas, Seguros, Cuidados pessoais, Pets, Presentes e doações e Viagens, além do escopo de revisar este catálogo futuro sem antecipar sua implementação runtime.

Revisão complementar isolada em Python 3, sem execução da aplicação: concentração por categoria, liderança e maior lançamento, quatro variantes, dois modos, oito rótulos e anos `0001`, `2026`, `9999`. Maior lançamento avaliado com descrição curta, whitespace, descrição Unicode de 64 caracteres e ausência de descrição; valores de `R$ 1.200,00`, centavos acima de `PHP_INT_MAX` e valor de 100 dígitos. Aplicada a ordem aprovada: descrição integral com/sem valor, depois categoria/data com/sem valor. Nenhum corte ou apelido introduzido.

Resultado: 2.688 pares selecionados, título máximo 24 e descrição máxima 80 caracteres Unicode. As famílias não afetadas por rótulo (comparações e onboarding) permanecem cobertas pela revisão 1, sem mudança de texto. Isso comprova compatibilidade editorial das oito categorias com as alternativas aprovadas, não a implementação runtime, projeção de descrição/data, BRL exato ou rotação da change mensal. Tasks 3.2–3.3, 4.* e demais pendências desta change continuam abertas; evidências executáveis de `expand-expense-categories` estão em seu `tasks.md`.
