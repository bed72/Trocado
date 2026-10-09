# Catálogo editorial para aprovação

Status: catálogo completo apresentado ao usuário; adotado como base inicial após sua reiteração do pedido de implementação. Os limites e prioridades do design foram aprovados.

## Contrato editorial

- Cada linha é uma variante completa: título e descrição são selecionados juntos. A alternativa curta pertence à mesma variante, sem combinação aleatória.
- Todos os títulos têm até 32 caracteres Unicode. Descrições devem ter até 110 após interpolação. A implementação verificará os limites; não haverá truncamento.
- `{category}` usa os rótulos locais de Insights: Alimentação, Saúde, Moradia, Lazer, Compras, Serviços, Transporte, Educação e Assinaturas. `other` recebe o rótulo Outros e só participa da orientação de revisão, dos totais e da concentração de lançamento, nunca como líder de categoria.
- `{percent}` é um inteiro não negativo arredondado por half-up apenas para o texto. Concentrações variam até 100%; comparações de aumento podem exceder 100%.
- `{day}` é o último dia completo comum usado na comparação (7 a 30), nunca o dia corrente automaticamente.
- “Neste mês” significa do primeiro dia até a referência, inclusive. “Dois meses anteriores” significa ambos os meses fechados. Os intervalos completos são entregues também em `period`.
- A versão inicial proposta do catálogo é `v1`. A chave editorial distingue tipo, categoria quando aplicável, estado de onboarding e mês de referência; não contém percentual, valores ou dia final do intervalo.
- Cada conjunto tem quatro variantes em ordem estável. A rotação escolhe primeiro a variante; só depois verifica se a descrição regular cabe e, se necessário, usa sua alternativa curta. A alternativa mantém o título da linha.
- Em comparação, a alternativa curta preserva direção e intervalos equivalentes, sem reproduzir um percentual excepcionalmente longo. Trata-se de outro texto completo sobre o mesmo fato, não de um número truncado ou limitado artificialmente. Essa escolha editorial integra a aprovação solicitada.
- Saúde e todas as categorias que não sejam Alimentação usam o conjunto neutro. Concentração de lançamento e liderança recorrente também têm linguagem neutra em qualquer categoria.

## 1. `category_concentration`: Alimentação

Grupo: `observation`. Elegibilidade: base descritiva aprovada, líder única `food` e participação de pelo menos 30%.

| Variante | Título | Descrição | Alternativa curta |
| --- | --- | --- | --- |
| 1 | O prato levou a maior fatia! | Alimentação lidera com {percent}% do valor registrado neste mês. Veio com fome. | Alimentação lidera: {percent}% do valor registrado neste mês. |
| 2 | Alimentação na liderança | Neste mês, Alimentação tem a maior fatia: {percent}% do valor registrado. | Neste mês, Alimentação lidera com {percent}% do valor registrado. |
| 3 | A maior fatia está na mesa | Alimentação reúne {percent}% do valor registrado neste mês e lidera as categorias. | Alimentação: líder com {percent}% do valor registrado neste mês. |
| 4 | O prato ficou em primeiro | Com {percent}% do valor registrado neste mês, Alimentação lidera. A mesa está posta. | Alimentação lidera com {percent}% do valor registrado neste mês. |

## 2. `category_concentration`: conjunto neutro

Grupo: `observation`. Usado para todas as outras categorias líderes elegíveis, incluindo Saúde. Não pressupõe o conteúdo dos registros.

| Variante | Título | Descrição | Alternativa curta |
| --- | --- | --- | --- |
| 1 | Uma categoria em destaque | {category} lidera com {percent}% do valor registrado neste mês. | {category}: líder com {percent}% do valor registrado neste mês. |
| 2 | A maior participação | Neste mês, {category} tem a maior participação: {percent}% do valor registrado. | Neste mês, {category} lidera com {percent}% do valor registrado. |
| 3 | Liderança nos registros | {category} reúne {percent}% do valor registrado neste mês e lidera as categorias. | {category} lidera: {percent}% do valor registrado neste mês. |
| 4 | O destaque deste mês | Com {percent}% do valor registrado neste mês, {category} aparece na liderança. | {category} tem a maior fatia: {percent}% do valor registrado neste mês. |

## 3. `expense_concentration`

Grupo: `observation`. Um único lançamento com pelo menos 40% do total em base elegível, após deduplicação. Não inclui descrição, ID ou categoria da despesa no texto.

| Variante | Título | Descrição | Alternativa curta |
| --- | --- | --- | --- |
| 1 | Um registro em destaque | Um único lançamento reúne {percent}% do valor registrado neste mês. | Um lançamento: {percent}% do valor registrado neste mês. |
| 2 | A maior parcela individual | O maior lançamento representa {percent}% do valor registrado neste mês. | Maior lançamento: {percent}% do valor registrado neste mês. |
| 3 | Uma parcela dos registros | Neste mês, {percent}% do valor registrado está em um único lançamento. | Neste mês, um lançamento reúne {percent}% do valor registrado. |
| 4 | Destaque entre lançamentos | Um lançamento concentra {percent}% do valor registrado neste mês. | Um lançamento tem {percent}% do valor registrado neste mês. |

## 4. `registered_amount_increase`

Grupo: `comparison`. Cada janela possui a base mínima; diferença de pelo menos R$ 50 e 20%, com pelo menos sete dias completos comuns.

| Variante | Título | Descrição | Alternativa curta |
| --- | --- | --- | --- |
| 1 | Mais valor registrado | De 1 a {day}, você registrou {percent}% mais valor que nos mesmos dias do mês passado. | De 1 a {day}, houve mais valor registrado que nos mesmos dias do mês passado. |
| 2 | O total registrado subiu | O valor registrado de 1 a {day} subiu {percent}% frente aos mesmos dias do mês passado. | O valor registrado de 1 a {day} subiu frente aos mesmos dias do mês passado. |
| 3 | Um total maior no intervalo | Até dia {day}, o valor registrado ficou {percent}% maior que no mesmo intervalo do mês passado. | Até dia {day}, o valor registrado foi maior que no mesmo intervalo do mês passado. |
| 4 | Comparando os registros | De 1 a {day}, o valor registrado aumentou {percent}% ante os mesmos dias do mês passado. | De 1 a {day}, o valor registrado aumentou ante os mesmos dias do mês passado. |

## 5. `registered_amount_decrease`

Grupo: `comparison`. Mesmas condições da comparação de aumento. Não afirma economia, mérito ou melhoria de hábitos.

| Variante | Título | Descrição | Alternativa curta |
| --- | --- | --- | --- |
| 1 | Menos valor registrado | De 1 a {day}, você registrou {percent}% menos valor que nos mesmos dias do mês passado. | De 1 a {day}, houve menos valor registrado que nos mesmos dias do mês passado. |
| 2 | O total registrado caiu | O valor registrado de 1 a {day} caiu {percent}% frente aos mesmos dias do mês passado. | O valor registrado de 1 a {day} caiu frente aos mesmos dias do mês passado. |
| 3 | Um total menor no intervalo | Até dia {day}, o valor registrado ficou {percent}% menor que no mesmo intervalo do mês passado. | Até dia {day}, o valor registrado foi menor que no mesmo intervalo do mês passado. |
| 4 | Os registros em comparação | De 1 a {day}, o valor registrado diminuiu {percent}% ante os mesmos dias do mês passado. | De 1 a {day}, o valor registrado diminuiu ante os mesmos dias do mês passado. |

## 6. `category_lead_streak`

Grupo: `comparison`. Mesma líder única elegível no mês corrente e nos dois anteriores completos. O texto distingue o mês ainda em andamento, sem afirmar que os registros são completos.

| Variante | Título | Descrição | Alternativa curta |
| --- | --- | --- | --- |
| 1 | Uma liderança recorrente | {category} segue líder nos registros deste mês, após liderar os dois meses anteriores. | {category} liderou os dois meses anteriores e segue líder nos registros deste mês. |
| 2 | O destaque continua | Nos registros, {category} liderou os dois meses anteriores e lidera este mês até agora. | {category} lidera os registros deste mês após liderar os dois meses anteriores. |
| 3 | Liderança em três períodos | {category} liderou os dois meses anteriores e segue à frente nos registros deste mês. | {category} segue à frente neste mês após liderar os registros dos dois anteriores. |
| 4 | A categoria segue à frente | Até agora, {category} lidera os registros deste mês, como nos dois meses anteriores. | {category} lidera este mês até agora, como nos registros dos dois meses anteriores. |

## 7. `first_expense`

Grupo: `onboarding`, `period: null`. Única mensagem quando não existe despesa histórica até a referência. Registros apenas futuros não contam como histórico disponível.

| Variante | Título | Descrição | Alternativa curta |
| --- | --- | --- | --- |
| 1 | Vamos começar? | Cadastre sua primeira despesa para começar a conhecer seus registros. Sem prova surpresa. | Cadastre sua primeira despesa para começar a conhecer seus registros. |
| 2 | O primeiro registro conta | Comece com uma despesa. Os insights chegam quando houver registros suficientes. | Registre uma despesa. Os insights chegam com registros suficientes. |
| 3 | Uma despesa para começar | Seu histórico começa com um registro. Cadastre uma despesa para dar o primeiro passo. | Cadastre uma despesa para começar seu histórico. |
| 4 | Bora abrir o histórico? | Registre sua primeira despesa. Por enquanto, a página está esperando sua estreia. | Registre sua primeira despesa para abrir seu histórico. |

## 8. `insufficient_history`: registros no mês corrente

Grupo: `onboarding`, `period: null`. Há histórico e registros correntes, mas nenhuma observação financeira elegível. A redação não promete que apenas cadastrar mais registros basta: a elegibilidade também depende de distribuição e valores.

| Variante | Título | Descrição | Alternativa curta |
| --- | --- | --- | --- |
| 1 | Ainda sem observações | Há registros neste mês, mas ainda não há uma observação financeira elegível. | Seus registros deste mês ainda não permitem uma observação financeira. |
| 2 | Cada registro traz contexto | Continue registrando suas despesas. Por enquanto, os registros não sustentam uma observação financeira. | Por enquanto, seus registros não sustentam uma observação financeira. |
| 3 | O histórico está em construção | Os registros deste mês ainda não oferecem evidência para os insights financeiros. | Ainda não há evidência para insights financeiros nos registros deste mês. |
| 4 | Sem apressar conclusões | Há registros neste mês. Vamos esperar evidência suficiente antes de apresentar uma observação financeira. | Há registros neste mês, mas ainda falta evidência para uma observação financeira. |

## 9. `insufficient_history`: sem registros no mês corrente

Grupo: `onboarding`, `period: null`. Existe histórico até a referência, inclusive fora da janela analítica, mas nenhum registro no mês corrente. Não sugere primeira despesa nem celebra ausência de registros.

| Variante | Título | Descrição | Alternativa curta |
| --- | --- | --- | --- |
| 1 | Seu histórico segue aqui | Você tem histórico, mas não há despesas registradas neste mês. Registre as que ocorrerem. | Você tem histórico, mas ainda não há despesas registradas neste mês. |
| 2 | Um mês sem registros | Não há registros neste mês. Seu histórico anterior continua disponível. | Neste mês não há registros; seu histórico anterior continua disponível. |
| 3 | Novos registros, novo contexto | Seu histórico já começou. Ainda não há registros neste mês para novas observações. | Seu histórico já começou, mas este mês ainda está sem registros. |
| 4 | Vamos atualizar o histórico? | Há registros anteriores, mas nenhum neste mês. Cadastre suas despesas quando ocorrerem. | Há registros anteriores, mas nenhum neste mês. |

## 10. `category_review`

Grupo: `onboarding`, `period: null`. Base descritiva elegível e pelo menos 50% do valor em `other`. Pode coexistir com fatos não redundantes. Não interpreta Outros como erro ou classificação pendente.

| Variante | Título | Descrição | Alternativa curta |
| --- | --- | --- | --- |
| 1 | Uma olhada nas categorias? | Outros reúne {percent}% do valor registrado neste mês. Vale revisar se as categorias fazem sentido. | Outros reúne {percent}% do valor registrado neste mês. Que tal revisar as categorias? |
| 2 | Outros está em destaque | Neste mês, {percent}% do valor registrado está em Outros. Revise as categorias se fizer sentido. | Neste mês, Outros reúne {percent}% do valor registrado. Revise se fizer sentido. |
| 3 | Mais contexto nas categorias | Outros tem {percent}% do valor registrado neste mês. Uma revisão pode dar mais contexto aos registros. | Outros tem {percent}% do valor registrado neste mês. Uma revisão pode dar mais contexto. |
| 4 | As categorias fazem sentido? | {percent}% do valor registrado neste mês está em Outros. Confira se essa escolha ainda faz sentido. | Outros: {percent}% do valor registrado neste mês. Confira se a escolha faz sentido. |

## Aprovação pendente

Revisar os dez conjuntos (40 variantes), seus rótulos e alternativas curtas. Após aprovação: concluir a tarefa 1.2, revalidar a mudança estritamente e iniciar a implementação autorizada. Não marcar revisão Flutter ou verificações de runtime como concluídas com base nesta proposta editorial.
