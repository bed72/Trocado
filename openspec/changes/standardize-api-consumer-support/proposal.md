## Why

A collection Bruno já exercita os principais fluxos da API, mas repete configuração por request, mistura escopos de variáveis e ainda não oferece uma referência publicável nem uma verificação automatizada para o aplicativo consumidor. Como outro app passará a integrar com a API, precisamos transformar a collection existente em uma superfície operacional consistente, segura e verificável sem substituir OpenSpec ou os testes Laravel.

## What Changes

- Centralizar na collection somente os headers comuns a toda a API, preservando headers específicos nos requests em que são semanticamente necessários.
- Separar configuração por ambiente, dados estáveis da collection, valores efêmeros de execução e segredos, impedindo que credenciais reais sejam versionadas.
- Integrar os cenários Bruno de Authentication ao fluxo `SignUp` → `SignIn` → request autenticado → `SignOut` → rejeição do token revogado, mantendo password e token apenas durante a execução.
- Documentar na collection e nas pastas as convenções JSON:API, valores monetários, autenticação, ordem dos cenários, efeitos destrutivos e cleanup; reservar documentação por request para comportamento não evidente no próprio request.
- Definir uma suíte smoke Bruno serial, selecionável por tags e executável por CLI em CI contra aplicação e banco descartáveis, sem substituir a suíte Pest/PHPUnit.
- Gerar uma referência HTML compartilhável a partir da collection para o app consumidor, sem incorporar segredos ou transformar o artefato gerado em uma fonte de verdade independente.
- Manter OpenAPI, geração de SDK, mocks e publicação pública da documentação fora desta mudança.

## Capabilities

### New Capabilities

- `api-consumer-support`: Define a collection Bruno como referência operacional executável para consumidores da API, incluindo configuração compartilhada, escopos de variáveis, autenticação segura, documentação, smoke tests em CI e geração HTML.

### Modified Capabilities

Nenhuma. Os contratos funcionais de User, Budget Recurrence e da mudança ativa de Authentication permanecem responsáveis por seus próprios comportamentos; esta capability organiza como esses contratos são exercitados e apresentados aos consumidores.

## Impact

- `bruno/bruno.json`, ambientes, configuração da collection, pastas e requests `.bru` serão reorganizados sem alterar os endpoints HTTP existentes.
- Os cenários Bruno previstos em `add-authentication` serão consumidos por esta capability sem proteger genericamente as rotas atuais de User e Budget.
- A automação de CI receberá uma etapa smoke serial e um ambiente efêmero próprio; nenhuma execução será direcionada a produção nem a um banco compartilhado.
- A documentação HTML será derivada da collection e tratada como artefato regenerável. OpenSpec continuará sendo a fonte dos requisitos e Pest/PHPUnit continuará sendo a verificação interna da aplicação.
- A implementação poderá exigir Bruno CLI ou uma action oficial com versão fixada; qualquer nova dependência no projeto deverá ser aprovada antes de ser adicionada.
