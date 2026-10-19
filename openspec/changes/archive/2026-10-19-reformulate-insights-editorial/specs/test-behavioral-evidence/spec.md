## MODIFIED Requirements

### Requirement: BEH-13 Insights independente de variante incidental

Testes de integração MUST aceitar todas as variantes válidas sem depender de ID gerado, sequência, ordem anterior ou literal de uma só variante. Catálogo/composição MUST testar conjuntos completos, alternativas de par, 80/81 grafemas incluindo separador, título 24, acentos/emojis compostos, rótulos longos, períodos e estabilidade/ciclos. MUST comprovar valor BRL exato por strings, centavos não nulos, montantes acima de PHP_INT_MAX, ausência de percentuais/proporções e falha explícita sem remover/arredondar dinheiro quando nenhuma alternativa couber. MUST testar que liderança publica valor da categoria no selecionado, não soma de três meses, e maior lançamento publica seu próprio valor. MUST comprovar segurança do texto do usuário e deduplicação semântica/textual antes da identidade final. IDs MUST ser testados com conta/assunto/período explícitos, sem copiar algoritmo de identidade. Revisão humana MUST complementar assertions; regex/tamanho MUST NOT ser declarados prova suficiente de utilidade, fidelidade ou layout.

#### Scenario: Valor muda sem trocar identidade ou variante
- **WHEN** somente valores de uma projeção mudam mantendo identidade e elegibilidade
- **THEN** UUID e variante permanecem estáveis e o montante textual é atualizado

#### Scenario: Catálogo direto e temporal
- **WHEN** todas as variantes/modos e alternativas são exercitados
- **THEN** têm montante real e interpretação útil, sem percentuais nem frase decorativa
- **AND** não exigem dias/anos financeiros no texto quando period já os fornece

#### Scenario: Falhas e segurança
- **WHEN** dinheiro integral não cabe ou descrição de usuário é insegura
- **THEN** o primeiro caso falha explicitamente e o segundo usa identificação factual segura
- **AND** não inventa onboarding/valor, não produz parcial e não publica ofensa/percentual

#### Scenario: Liderança recorrente com contas diferentes
- **WHEN** liderança equivalente é analisada com UUIDs explícitos de contas diferentes
- **THEN** todas as variantes válidas passam os contratos de valor, significado e limites
- **AND** a integração não exige um literal exclusivo de uma variante ou uma frase sobre os dois meses anteriores

#### Scenario: Catálogo completo
- **WHEN** todos os conjuntos e alternativas percorrem ciclos com contas/datas explícitas
- **THEN** preservam fatos, montantes integrais, preenchimento de placeholders e limites Unicode
- **AND** montante que não cabe usa alternativa completa ou falha explícita, sem truncamento ou retirada do dinheiro

#### Scenario: Números mudam no mesmo dia
- **WHEN** só os valores mudam mantendo conta, assunto, períodos e significado elegível
- **THEN** conserva UUID/variante e atualiza o dinheiro pertinente na mesma redação
- **AND** expected usa valores independentes conhecidos, sem copiar o cálculo de produção
