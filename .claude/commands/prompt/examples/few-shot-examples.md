# Few-Shot Examples por Tipo de Tarefa

Exemplos de transformação para guiar o agente. Use como referência quando a tarefa se encaixar no padrão.

---

## Tipo: Feature completa (todas as camadas)

**Entrada típica:** "Implementa a tela de X", "Cria a feature de Y"

**Padrão de saída:**
- `<goals>`: Implementar feature Y do zero — domain, data, infrastructure e presentation
- `<workflow>`: 1) Criar spec com `/sdd` → 2) domain → 3) infrastructure → 4) data → 5) presentation → 6) providers + location → 7) `flutter analyze && flutter test`
- `<output>`: Lista de arquivos criados/modificados com caminhos
- `<context-tools>`: `sdd`, `notifier`, `validator`, `new-feature`, `new-test`
- `<critical>`: Sem `ConsumerWidget`, sem `var`, sem widgets privados em arquivos de widget, `sdd` sempre obrigatória

---

## Tipo: Widget / Componente isolado

**Entrada típica:** "Cria um componente de X reutilizável", "Faz um campo de Y"

**Padrão de saída:**
- `<goals>`: Widget Flutter reutilizável seguindo as convenções do projeto
- `<requirements> ### UI/UX`: estados visuais, feedback, Material3 via `context.colors` e `context.typography`
- `<output>`: Arquivo do widget em `presentation/widgets/` ou na pasta da feature
- `<context-tools>`: `context7` (API Flutter/Material) se necessário
- `<critical>`: `StatelessWidget` puro (sem `Consumer`), sem lógica de negócio no widget, nome com sufixo `Widget`

---

## Tipo: Refatoração / Melhoria de código

**Entrada típica:** "Refatora X para usar Y", "Melhora o notifier Z"

**Padrão de saída:**
- `<goals>`: Refatorar mantendo comportamento, melhorar [legibilidade/conformidade com convenções]
- `<workflow>`: 1) Ler código atual → 2) Identificar pontos de melhoria → 3) Aplicar → 4) `flutter analyze && flutter test`
- `<output>`: Código refatorado (sem arquivos novos se possível)
- `<context-tools>`: `arch-review` para validar dependências entre camadas
- `<critical>`: Sem mudança de comportamento externo observável, sem adicionar dependências novas

---

## Tipo: Integração com API HTTP

**Entrada típica:** "Consome o endpoint X", "Adiciona chamada para a API de Y"

**Padrão de saída:**
- `<goals>`: Integrar endpoint X — request/response, datasource, extension de mapping para domain model
- `<requirements> ### Technical`: Dio via `IHttpClient`, `Either<FailureResponse, XxxResponse>`, `fromJson` apenas nas responses, `toJson` nos requests
- `<endpoints>`: URL, método, payload, status codes
- `<tests>`: Cenários de sucesso e falha no repositório (mock em `IHttpClient`)
- `<context-tools>`: `new-test` para padrões de teste de repositório
- `<critical>`: Único `try-catch` no Client, datasource só deserializa, `toModel()` apenas via extension em `data/extensions/`

---

## Tipo: Testes

**Entrada típica:** "Escreve testes para X", "Cobre o Notifier/Validator/Repository com testes"

**Padrão de saída:**
- `<goals>`: Cobrir [X] com testes unitários seguindo a estratégia de mock do projeto
- `<requirements> ### Technical`: Estratégia por camada — mock em `IHttpClient` para repositório, mock em `IXxxRepository` para Notifier, Dart puro para validators e responses
- `<workflow>`: 1) Identificar cenários → 2) Declarar mocks em `test/mocks/mocks.dart` → 3) Escrever caso feliz → 4) Escrever casos de erro → 5) `flutter test`
- `<output>`: Arquivos de teste em `test/src/` com path espelhando `lib/src/`
- `<context-tools>`: `new-test` para padrões e convenções de teste
- `<critical>`: Descrições de `test()` e `group()` em inglês, sem mock de datasource (coberto via repositório), sem `MockHttpClient` em testes de Notifier

---

## Tipo: Navegação

**Entrada típica:** "Adiciona navegação de X para Y", "Implementa deep link para Z"

**Padrão de saída:**
- `<goals>`: Configurar navegação de X para Y usando duck_router com Location
- `<requirements> ### Technical`: `duck_router`, `Location` em `main/locations/`, `context.navigate()` / `context.pop()` / `context.root()`
- `<workflow>`: 1) Criar `XxxLocation` em `main/locations/` → 2) Passar callbacks de navegação para screens via construtor → 3) Registrar na lista de locations se necessário
- `<context-tools>`: `deep-link` se envolver deep link, `context7` (API duck_router)
- `<critical>`: Navegação nunca dentro de Notifier, callbacks passados pelo location para a screen, sem import de `Location` dentro de `presentation/`

---

## Tipo: Validação de formulário

**Entrada típica:** "Adiciona validação no campo X", "Cria validators para o formulário Y"

**Padrão de saída:**
- `<goals>`: Implementar validators tipados para o formulário Y seguindo o padrão `ValidationBase<T>`
- `<requirements> ### Technical`: `sealed class ValidationBase<T>` + interface `Validation<T>` em `domain/validators/`; validators em `presentation/screens/feature/validators/`; `FormValidator` agregando todos os validators
- `<output>`: Arquivos de validator + FormValidator + atualização do provider em `main/providers/validators_provider.dart`
- `<context-tools>`: `validator` para o padrão de implementação
- `<critical>`: Validators são Dart puro (sem Flutter), instanciados via provider em `main/`, nunca diretamente no Notifier
