## Why

O catálogo v5 implementado trocou números úteis por intervalos e frases decorativas. Após observar a resposta real, o usuário rejeitou esse resultado e aprovou a direção “Total registrado subiu: R$ 350 a mais que no mesmo intervalo de setembro” e “Moradia: R$ 1.800 em outubro; lidera pelo terceiro mês”. Insights precisa informar valor real e seu significado, sem obrigar o consumidor a interpretar uma lista de datas.

## What Changes

- Redesenhar todos os conjuntos como **fato monetário exato + interpretação direta**: diferença absoluta nas comparações, valor da categoria na concentração/liderança, valor do lançamento no maior registro e valor de Outros na revisão.
- Retirar humor obrigatório, metáforas de palco/pódio e elogios genéricos. Manter acolhimento sem fatos inventados nos estados sem análise.
- Permitir dinheiro calculado, sem percentuais/proporções publicadas. Texto de usuário não é fonte autorizada de valor monetário.
- Transferir intervalos exatos, dias e anos financeiros para `period`, mantendo apenas referência temporal natural necessária no texto; onboarding histórico com period null continua identificado por mês/ano.
- Adotar limite combinado de 80 grafemas, título até 24, alternativas completas, rotação, deduplicação, regras analíticas e UUIDs. O usuário escolheu explicitamente “80 no total (Recomendado)” para preservar o exemplo aprovado de 72. Valores que não couberem integralmente devem falhar explicitamente, nunca ser abreviados/arredondados ou substituídos por texto vago.
- **BREAKING editorial:** esta revisão substitui a proibição de dinheiro e a obrigação de sarcasmo/contexto temporal integral da revisão v5. O envelope HTTP não muda.

## Capabilities

### New Capabilities

Nenhuma.

### Modified Capabilities

- `insights`: valor real com interpretação útil e referência temporal natural.
- `test-behavioral-evidence`: catálogo monetário exato sem literal incidental, sem exigir datawall ou dinheiro proibido.

## Impact

- Insights Domain/Application: catálogo v6, composição BRL sem float e transporte do valor da categoria selecionada na liderança recorrente, usando a mesma projeção existente.
- Nenhuma consulta nova, mudança SQL, migration, pacote, contexto, IA, cache, fila, alteração Flutter ou mudança de limiar/identidade.
- Atualizar testes existentes, Bruno e documentação. Preservar as evidências históricas da revisão 1 em tasks e seu catálogo, agora superado.
- Autorização atual: “Isso ta perfeito […] Redesenha todos os insights para seguir esse padrao”, em continuação à proposta explícita de ajustar spec e implementar. Não autoriza deploy, sync ou archive.
