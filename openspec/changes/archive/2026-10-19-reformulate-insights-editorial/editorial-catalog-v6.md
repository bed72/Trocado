# Catálogo v6 — valor real e interpretação direta

**Revisão 2 aprovada**, resposta explícita “Aprovar e aplicar” após apresentação do catálogo completo. Substitui a revisão 1/v5 após o feedback sobre a resposta real. Versão de runtime: `v6-monetary-editorial`. O usuário escolheu “80 no total (Recomendado)”, mantendo título até 24, porque o exemplo aprovado soma 72 grafemas.

## Regras comuns

- `{amount}` é o valor BRL exato calculado: diferença absoluta na comparação, valor da categoria na concentração/liderança, valor do lançamento no maior registro e valor de Outros na revisão. Ex.: R$ 350; R$ 350,01; R$ 1.800. Omitir somente `,00`, sem float, arredondar ou abreviar mil/mi.
- `{month}` e `{previous_month}` são nomes naturais: outubro, setembro. O texto financeiro não precisa repetir ano/dias/intervalos que estão em `period`. Nos estados históricos com period null, `{month}` é “setembro de 2026” e `{short_month}` é “set/2026”; no vigente, “outubro” e “outubro”, respectivamente.
- Cada linha é um par completo. Alternativas seguem a mesma variante, não embaralham frases e não retiram valor/interpretação. Ordem: principal, compacta; comparações ainda oferecem mínima. Título até 24, par com um espaço até 80 grafemas. Se nenhuma couber integralmente, falha explícita.
- Não há percentuais, proporções, palco, pódio, frases decorativas, humor obrigatório ou elogio genérico. Não há promessa de economia/retorno nem juízo sobre a condição financeira.

## 1. Total registrado subiu / caiu — comparação corrente

Título: **Total registrado subiu** ou **Total registrado caiu**. Em cada linha, aumento usa `a mais`/`acima`/`+`, redução usa `a menos`/`abaixo`/`−`. O valor é diferença das mesmas janelas elegíveis, não o total do mês. Referência exata fica em period.

| Variante | Descrição principal | Compacta | Mínima |
| --- | --- | --- | --- |
| 1 | `{amount} a mais que no mesmo intervalo de {previous_month}.` | `{amount} a mais nos mesmos dias do mês anterior.` | `{amount} a mais.` |
| 2 | `{amount} acima do mesmo intervalo de {previous_month}.` | `{amount} acima do mesmo intervalo anterior.` | `A mais: {amount}.` |
| 3 | `Mesmo intervalo de {previous_month}: {amount} a mais.` | `Mesmo intervalo anterior: {amount} a mais.` | `{amount}; variação para mais.` |
| 4 | `Frente ao mesmo intervalo de {previous_month}: +{amount}.` | `Contra o mesmo intervalo anterior: +{amount}.` | `Variação: +{amount}.` |

Na redução, a mínima 3 é `{amount}; variação para menos.`. Não usar sinal negativo junto com “a menos”.

## 2. Total registrado subiu / caiu — meses encerrados

Mesmos títulos e substituições da seção 1; compara totais mensais completos, sem “mesmos dias”. As mínimas são as da seção 1.

| Variante | Descrição principal | Compacta |
| --- | --- | --- |
| 1 | `{amount} a mais em {month} que em {previous_month}.` | `{amount} a mais no mês selecionado.` |
| 2 | `{amount} acima de {previous_month}, em {month}.` | `{amount} acima do mês anterior.` |
| 3 | `Em {month}, {amount} a mais que em {previous_month}.` | `Contra o mês anterior: {amount} a mais.` |
| 4 | `{month} contra {previous_month}: +{amount}.` | `Variação mensal: +{amount}.` |

## 3. Concentração da categoria — ambos os modos

Título: `{category}`, rótulo integral. Publica o total dessa categoria no selecionado e sua liderança, não frequência, excesso ou capacidade financeira.

| Variante | Descrição principal | Compacta |
| --- | --- | --- |
| 1 | `{amount} em {month}; lidera nos registros.` | `{amount}; categoria líder.` |
| 2 | `Maior categoria em {month}: {amount}.` | `Categoria líder: {amount}.` |
| 3 | `{amount} registrados em {month}; categoria líder.` | `{amount}; maior categoria.` |
| 4 | `Em {month}, {amount}; maior total por categoria.` | `Maior total por categoria: {amount}.` |

## 4. Liderança recorrente — ambos os modos

Título: `{category}`, rótulo integral. Valor somente no mês selecionado. “Terceiro mês” é a recorrência comprovada nas três janelas, sem sugerir três fechamentos no vigente nem afirmar que a sequência começou exatamente ali.

| Variante | Descrição principal | Compacta |
| --- | --- | --- |
| 1 | `{amount} em {month}; lidera pelo terceiro mês.` | `{amount}; líder por 3 meses.` |
| 2 | `{amount} em {month}; terceiro mês na liderança.` | `3º mês na liderança: {amount}.` |
| 3 | `Terceiro mês como líder: {amount} em {month}.` | `{amount}; 3ª liderança seguida.` |
| 4 | `Em {month}, {amount}; terceira liderança seguida.` | `3 meses como líder: {amount}.` |

## 5. Maior lançamento — ambos os modos

Principal: título `{identity}`, descrição abaixo. A identificação tenta descrição integral neutra segura; se não reconhecida, usa categoria e DD/MM do mesmo registro. O par compacto tem título `{category}` e descrição própria completa, preservando maior lançamento/data/valor. O montante é o do lançamento, nunca soma da categoria.

| Variante | Descrição principal | Título compacto | Descrição compacta |
| --- | --- | --- | --- |
| 1 | `{amount} em {month}; maior lançamento.` | `{category}` | `Maior em {expense_date}: {amount}.` |
| 2 | `Maior lançamento em {month}: {amount}.` | `{category}` | `{expense_date}: {amount}; maior registro.` |
| 3 | `Em {month}, {amount}; maior lançamento.` | `{category}` | `{amount}; maior em {expense_date}.` |
| 4 | `{amount}; maior registro de {month}.` | `{category}` | `Maior: {amount} em {expense_date}.` |

Descrição de usuário com dinheiro/percentual/ofensa/instrução continua imprópria para identificação: todo valor publicado vem do fato tipado, não da descrição. Marcação reconhecida permanece literal, não é executada/renderizada pelo backend. Não publicar ID nem buscar detalhes por card.

## 6. Revisão de Outros — ambos os modos

Título: **Outros**. Exige a base e o limiar existentes. Identifica o valor real e oferece revisão sem presumir erro, pendência ou conteúdo da categoria.

| Variante | Descrição principal | Compacta |
| --- | --- | --- |
| 1 | `{amount} em {month}. Vale revisar as categorias.` | `{amount}. Vale revisar as categorias.` |
| 2 | `{amount} em {month}; confira as categorias.` | `{amount}; confira as categorias.` |
| 3 | `Em {month}, {amount}. Vale rever as categorias.` | `{amount}. Vale rever as categorias.` |
| 4 | `{amount} registrados em {month}. Reveja as categorias.` | `{amount}. Reveja as categorias.` |

## 7. Primeiro registro — somente vigente

Título: **Primeiro registro**. Sem valor ou referência temporal artificiais. Não existe histórico até a consulta; convite não é conquista por ausência.

| Variante | Descrição |
| --- | --- |
| 1 | `Cadastre sua primeira despesa para começar.` |
| 2 | `Comece registrando sua primeira despesa.` |
| 3 | `Registre uma despesa para iniciar seu histórico.` |
| 4 | `Seu histórico começa com a primeira despesa registrada.` |

## 8. Base insuficiente no selecionado — ambos os modos

Título: **Base insuficiente**. Existem registros, mas ainda não há observação financeira elegível. Não afirma que há poucos lançamentos se o problema for outro critério. Sem dinheiro/conquista inventados nem promessa de que mais um registro garantirá análise.

| Variante | Descrição principal | Compacta |
| --- | --- | --- |
| 1 | `Registros de {month} ainda não permitem análise.` | `{short_month}: registros insuficientes para análise.` |
| 2 | `Ainda não há base para analisar {month}.` | `{short_month}: ainda sem base para análise.` |
| 3 | `{month}: ainda falta base para análise.` | `{short_month}: falta base para análise.` |
| 4 | `A base de {month} ainda não permite análise.` | `{short_month}: base ainda insuficiente.` |

## 9. Mês sem registros — ambos os modos

Título: **Mês sem registros**. Descreve somente o selecionado, sem insinuar ausência em toda a conta ou economia. Histórico tem mês/ano pois period continua null. Se faltar espaço, a alternativa usa a mesma descrição e `{short_month}`.

| Variante | Descrição |
| --- | --- |
| 1 | `Sem despesas registradas em {month}.` |
| 2 | `Nenhum registro de despesa em {month}.` |
| 3 | `{month}: sem despesas registradas.` |
| 4 | `Não há registros de despesas em {month}.` |

## Revisão e limites

Os dois exemplos aprovados aparecem literalmente como primárias da comparação corrente e da liderança. A revisão completa conserva acolhimento por linguagem sem julgamento, não por elogios genéricos. Categorias sensíveis recebem as mesmas afirmações estritamente demonstráveis das demais.

Dinheiro muito grande pode exigir compacta/mínima sem mês no texto; period continua integral. Se valor exato + identificação/interpretação não couberem em 80/24, falha explicitamente. Não fabricar uma mensagem qualitativa para esconder o montante.

**Revisão humana aprovada.** Evidências de v5 não são evidências de v6. Não há homologação de layout Flutter nem publicação automática.
