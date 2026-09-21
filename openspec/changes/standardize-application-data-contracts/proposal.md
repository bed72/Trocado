## Why

Os contratos internos da Application podem depender de array shapes repetidos e chaves convencionais para representar retornos estruturados, como ocorre no fluxo de `SignIn`. Precisamos de uma convenção transversal que torne entradas e saídas compostas explícitas e type-safe sem transformar toda assinatura em um DTO cerimonial.

## What Changes

- Introduzir `Application/Data` como localização convencional para classes de dados pertencentes à Application de cada bounded context.
- Adotar o sufixo `Input` para agrupamentos coesos de dados de entrada e o sufixo `Output` para retornos estruturados; `Result` não será usado para esse papel.
- Usar mais de três parâmetros relevantes como gatilho de avaliação para um `Input`, subordinado à coesão, clareza e evolução conjunta dos dados.
- Preferir um `Output` quando um contrato da Application precisar retornar múltiplos valores heterogêneos identificados por nome, especialmente a partir de três valores, em vez de expor array shapes estruturais.
- Definir classes `Input` e `Output` como objetos `final`, imutáveis, constructor-only, fortemente tipados, sem setters, comportamento de domínio ou dependências de framework.
- Preservar retornos naturais de Repositories como Entities, Value Objects, scalars e coleções homogêneas, usando objetos específicos somente para consultas ou operações que realmente produzam uma estrutura composta.
- Aplicar a convenção aos bounded contexts existentes `Authentication`, `User` e `Budget`, sem conversão mecânica de contratos que já sejam claros.
- Padronizar o retorno estruturado de `SignInPort` e `SignInUseCase` como o primeiro caso concreto de `Output`.

## Capabilities

### New Capabilities

- `application-data-contracts`: Define como todos os bounded contexts existentes e futuros representam entradas coesas e saídas estruturadas nos contratos da Application usando `Input` e `Output` imutáveis.

### Modified Capabilities

Nenhuma. Os comportamentos funcionais e HTTP de Authentication, User e Budget permanecem inalterados; a mudança padroniza seus contratos internos da Application.

## Impact

- `app/Authentication/Application`, `app/User/Application` e `app/Budget/Application` passam a seguir a mesma convenção para novos contratos e para contratos existentes alterados por esta mudança.
- `SignInPort`, seu Adapter, `SignInUseCase` e a Response HTTP correspondente terão o array shape substituído por um `Output` da Application sem mudar o documento JSON:API observado pelo consumidor.
- `ARCHITECTURE.md` e as guidelines arquiteturais deverão registrar `Input`, `Output` e `Application/Data` como convenções do projeto.
- Não há mudança de banco, endpoint, payload, dependência externa ou framework.
