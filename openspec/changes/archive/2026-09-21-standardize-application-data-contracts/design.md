## Context

Os bounded contexts `Authentication` e `User` seguem a separação `Domain/Application/Infrastructure/Presentation`, mas a Application ainda não possui uma convenção para estruturas compostas que não sejam Entities ou Value Objects. O caso mais evidente é `SignIn`: Port e Use Case repetem um array shape com quatro campos, o Adapter monta chaves textuais e a Response conhece essa estrutura indiretamente.

Ao mesmo tempo, a maioria dos contratos atuais já é expressiva com parâmetros explícitos e retornos naturais. O Repository de User retorna Entities, scalars e listas homogêneas; transformar cada assinatura em um objeto acrescentaria classes sem melhorar o contrato. A convenção precisa eliminar estruturas frágeis sem importar o padrão de DTO indiscriminado que motivou esta mudança.

## Goals / Non-Goals

**Goals:**

- Definir uma convenção única de `Input` e `Output` para a Application.
- Tornar retornos estruturados verificáveis pelo sistema de tipos nativo do PHP.
- Usar coesão e clareza como critérios principais, com limites numéricos apenas como heurística.
- Manter os objetos independentes de Laravel, Eloquent, Sanctum, HTTP e serialização.
- Preservar Entities, Value Objects e coleções homogêneas como retornos preferenciais de Repositories.
- Aplicar a convenção ao `SignIn`.

**Non-Goals:**

- Criar um objeto para toda chamada de método.
- Substituir Entities ou Value Objects por classes de dados.
- Introduzir CQRS, Commands de aplicação, buses, Mappers ou classes base.
- Alterar contratos HTTP, documentos JSON:API, banco de dados ou comportamento funcional.
- Reorganizar todos os Use Cases em subpastas por antecipação.
- Converter array shapes privados do Domain ou arrays exigidos por Laravel nas bordas.

## Decisions

### Cada bounded context possuirá seu próprio `Application/Data`

Classes de dados serão colocadas em `app/<Contexto>/Application/Data`. A classe pertence ao contexto que define o contrato; não haverá uma pasta global compartilhada nem dependência de Data entre contextos apenas por coincidência estrutural.

`Application/Data` começará plano em cada contexto. Subpastas por capacidade ou Use Case somente serão criadas quando existir um grupo real de classes relacionado e a pasta plana perder navegabilidade. Não serão criadas previamente divisões como `Inputs`, `Outputs`, `Ports` ou `Repositories`.

Alternativas rejeitadas: colocar os objetos junto da Presentation os acoplaria ao transporte; colocá-los no Domain atribuiria significado de domínio a carriers transitórios; uma pasta global apagaria a propriedade pelo bounded context.

### Entradas usarão o sufixo `Input`

Um `Input` agrupa dados coesos necessários para invocar uma operação da Application. Mais de três parâmetros relevantes será um gatilho para avaliar e, quando os valores formarem uma unidade coesa, adotar um `Input`. Assinaturas menores permanecerão explícitas por padrão, mas poderão usar `Input` quando opcionais, evolução conjunta ou ambiguidade tornarem o contrato mais claro dessa forma.

O limite não será aplicado mecanicamente. Muitos parâmetros sem coesão podem indicar responsabilidade excessiva e devem provocar revisão da operação, não apenas ser escondidos em uma classe. Métodos simples como `findByEmail(EmailValueObject $email)` não receberão wrappers.

Authentication e User continuarão com parâmetros explícitos nos contratos atuais porque possuem no máximo três parâmetros relevantes e não apresentam benefício suficiente para uma classe adicional.

Alternativas rejeitadas: adotar `Command`, que conflita com CQRS e Laravel Console Commands; `Payload`, que sugere transporte; `Parameters`, que descreve mecanismo; e `DTO`, que não revela o papel da classe.

### Saídas usarão obrigatoriamente o sufixo `Output`

Um `Output` representa uma saída estruturada da Application que não é naturalmente uma única Entity, Value Object, scalar ou coleção homogênea. O sufixo oficial será `Output`; `Result` não será usado para esse papel.

Contratos públicos da Application com três ou mais valores heterogêneos identificados por nome usarão `Output` em vez de array shape. Retornos com dois valores serão avaliados pela mesma coesão: usarão `Output` quando os nomes forem essenciais para interpretar os campos ou quando os valores evoluírem juntos. Arrays continuarão válidos para coleções e mapas homogêneos com PHPDoc genérico.

O primeiro objeto será `SignInOutput`, com os dados atualmente retornados por `SignInPort`. O Port, o Use Case e a Presentation poderão usar a mesma classe porque representam a mesma saída da operação. Caso um Port futuramente produza dados técnicos diferentes da saída exposta pelo Use Case, cada contrato terá seu próprio objeto e o Use Case fará o mapeamento.

Alternativas rejeitadas: `Result`, por decisão de linguagem do projeto; `Response`, reservado à Presentation HTTP; e aliases de array shape, que centralizam documentação mas preservam chaves frágeis em runtime.

### Inputs e Outputs serão carriers imutáveis e framework-agnostic

As classes serão `final readonly`, constructor-only e fortemente tipadas, preferencialmente com propriedades promovidas públicas para evitar getters cerimoniais. Não terão setters, mutação, comportamento de domínio, serialização, formatação HTTP, acesso ao container ou dependência de Laravel.

PHPDoc será usado somente para informações que o tipo nativo não expressa, como generics de coleções. Senhas, tokens e outros campos sensíveis continuarão sujeitos às mesmas restrições de logging e exposição; imutabilidade não os torna seguros para serialização.

Uma classe que passa a validar invariantes, comparar semanticamente valores ou oferecer operações próprias do conceito deverá ser reavaliada como Value Object de Domain. Uma classe com identidade e ciclo de vida continuará sendo Entity. Objetos Eloquent, Requests, Responses e objetos de SDK permanecem nas bordas e serão mapeados antes de alcançar um contrato da Application.

Alternativa rejeitada: criar interfaces ou classes base para Data. Elas acrescentariam abstração sem polimorfismo necessário.

### Repositories não retornarão Outputs de Use Case por conveniência

Repositories continuarão retornando agregados, Value Objects, scalars e coleções homogêneas quando esses tipos representarem naturalmente a consulta ou persistência. Um Repository poderá retornar um objeto específico em `Application/Data` quando uma consulta produzir uma projeção composta legítima, mas o nome e a estrutura pertencerão à consulta, não serão reutilizados de um Use Case apenas porque os campos coincidem.

Authentication continuará usando Ports para a capacidade de autenticar e emitir tokens. Ports podem receber Inputs e retornar Outputs da Application sem inversão indevida: os Adapters de Infrastructure dependem desses contratos inward-facing e convertem objetos de Laravel ou SDK para os tipos da Application.

Alternativa rejeitada: criar taxonomias separadas como `UseCaseOutput`, `PortOutput` e `RepositoryOutput`. A separação será feita pelo significado e pela propriedade do contrato, não por hierarquias paralelas.

### A adoção será seletiva nos contratos existentes

Authentication migrará o array shape de `SignIn` para `SignInOutput` e manterá os parâmetros explícitos de SignIn e SignUp. User será revisado e permanecerá sem Input ou Output enquanto seus contratos atuais continuarem adequadamente representados por até três parâmetros, Entities, Value Objects, scalars e listas.

Essa assimetria é intencional: cobrir todos os bounded contexts significa aplicar o mesmo critério, não fabricar ao menos uma classe em cada contexto.

## Risks / Trade-offs

- [A pasta `Application/Data` virar um depósito genérico] -> Exigir propriedade pelo bounded context, nomes orientados à operação e criação somente quando o contrato melhorar.
- [Os limites numéricos virarem regra religiosa] -> Registrar números como gatilhos de avaliação e manter coesão, ambiguidade e evolução como critérios decisivos.
- [Um Input esconder um Use Case amplo demais] -> Revisar responsabilidade e coesão antes de criar a classe.
- [Outputs duplicarem Entities ou Value Objects] -> Preferir tipos de Domain quando eles já representarem integralmente o retorno.
- [Objetos sensíveis serem serializados por conveniência] -> Proibir métodos genéricos de serialização e manter transformação somente na Presentation.
- [Renomear parâmetros quebrar named arguments] -> Atualizar todos os chamadores e testes juntamente com cada assinatura migrada.
- [A mudança interna causar regressão HTTP] -> Preservar e verificar os documentos JSON:API e status existentes, especialmente no SignIn.

## Migration Plan

1. Registrar `Application/Data`, `Input` e `Output` em `ARCHITECTURE.md` e nas guidelines aplicáveis.
2. Criar `Authentication/Application/Data/SignInOutput` e migrar Port, Adapter, Use Case e Response sem mudar o contrato HTTP.
3. Revisar User e os demais contratos de Authentication para confirmar, com evidência, que não exigem classes adicionais pela convenção.
4. Adicionar verificações arquiteturais para imutabilidade, localização e ausência de dependências proibidas, além dos testes comportamentais afetados.

Rollback reverte as assinaturas migradas e a documentação da convenção. Não há migration de banco, dados persistidos ou mudança de API externa a desfazer.

## Open Questions

Nenhuma questão bloqueia a implementação. O sufixo de saída foi decidido como `Output`, e subpastas internas de `Application/Data` serão consideradas somente quando volume real justificar a mudança.
