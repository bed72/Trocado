## 1. Convenção arquitetural

- [x] 1.1 Atualizar `ARCHITECTURE.md` para definir `Application/Data`, os sufixos `Input` e `Output`, as heurísticas de criação e a distinção para Entity, Value Object, Repository, Port e Response.
- [x] 1.2 Atualizar as guidelines de Application, Domain e naming com as regras normativas, incluindo a proibição de usar `Result` como sufixo de saída da Application.

## 2. Output de Authentication

- [x] 2.1 Criar `SignInOutput` em `Authentication/Application/Data` como classe `final readonly`, constructor-only e fortemente tipada para os quatro campos atualmente documentados no array shape.
- [x] 2.2 Alterar `SignInPort`, `SignInAdapter` e `SignInUseCase` para retornar `SignInOutput`, removendo o array shape duplicado e impedindo que objetos do Sanctum escapem da Infrastructure.
- [x] 2.3 Alterar `AccessTokenResponse` para consumir propriedades de `SignInOutput` e preservar integralmente o documento JSON:API, headers e tratamento de dados sensíveis existentes.
- [x] 2.4 Atualizar os testes unitários e de API de SignIn para verificar o contrato tipado e a ausência de regressão na resposta HTTP.

## 3. Inputs de Budget

- [x] 3.1 Criar `CreateBudgetInput` e `UpdateBudgetInput` em `Budget/Application/Data` como classes `final readonly`, constructor-only e fortemente tipadas.
- [x] 3.2 Migrar `CreateBudgetUseCase` e seus chamadores para `CreateBudgetInput`, preservando invariantes, atomicidade, recorrência e retorno em `BudgetEntity`.
- [x] 3.3 Migrar `UpdateBudgetUseCase` e seus chamadores para `UpdateBudgetInput`, preservando a semântica dos campos opcionais, overlap checks, atomicidade e retorno em `BudgetEntity`.
- [x] 3.4 Atualizar os testes unitários e de API de Create e Update Budget para as novas assinaturas e confirmar que os contratos JSON:API permanecem inalterados.

## 4. Cobertura transversal dos contextos

- [x] 4.1 Revisar os contratos restantes de Authentication e confirmar que SignIn e SignUp mantêm parâmetros explícitos enquanto os retornos naturais permanecem scalars ou void onde adequado.
- [x] 4.2 Revisar os Use Cases e Repositories de User e confirmar que as assinaturas atuais permanecem adequadamente representadas por parâmetros explícitos, `UserEntity`, `EmailValueObject`, scalars e listas tipadas, sem criar Data cerimonial.
- [x] 4.3 Revisar os contratos restantes de Budget e confirmar que Entities, scalars, callbacks de Port e coleções homogêneas não sejam convertidos em Inputs ou Outputs sem ganho contratual.
- [x] 4.4 Estender `ContextBoundariesTest` para cobrir classes em `Application/Data`, verificando localização, imutabilidade, sufixos permitidos e ausência de dependências de Infrastructure, Presentation ou Laravel.

## 5. Verificação final

- [x] 5.1 Executar os testes focados de Authentication, Budget e arquitetura, corrigindo incompatibilidades de tipos e named arguments introduzidas pelas novas assinaturas.
- [x] 5.2 Executar a suíte completa para confirmar que User e os demais fluxos dos três bounded contexts continuam sem regressões.
- [x] 5.3 Executar Laravel Pint nos arquivos PHP alterados e confirmar que não restam array shapes estruturais no contrato público de SignIn nem classes `Result` usadas como saída da Application.
- [x] 5.4 Validar a mudança OpenSpec estritamente e revisar o diff final contra todos os requirements e cenários de `application-data-contracts`.
