## Context

A collection `bruno/` já contém cenários executáveis de User, Budget e Budget Recurrence, com testes de contrato e encadeamento por variáveis de runtime. Entretanto, cada request declara `auth: none` e headers JSON:API, o ambiente Local também contém IDs sentinela que não variam por ambiente, não existe automação de CI e a documentação para um app consumidor está dispersa entre README, OpenSpec e os próprios requests.

A mudança ativa `add-authentication` já define os endpoints, o token Bearer opaco e a obrigação de uma collection Bruno segura. Esta mudança não redefine Authentication: ela estabelece a experiência transversal de consumo da API e incorpora aqueles cenários quando os endpoints estiverem disponíveis.

OpenSpec continuará descrevendo requisitos e cenários duráveis; Pest/PHPUnit continuará verificando internamente a aplicação; Bruno será a referência operacional executável na borda HTTP. O app consumidor precisa de documentação navegável agora, mas não solicitou geração de cliente ou contrato OpenAPI.

## Goals / Non-Goals

**Goals:**

- Remover duplicação de configuração que é realmente comum a toda a collection.
- Tornar explícito onde cada categoria de variável e segredo deve viver.
- Disponibilizar um fluxo Authentication seguro e reproduzível para consumidores.
- Oferecer documentação curta junto dos requests e uma saída HTML compartilhável.
- Executar um subconjunto smoke em CI contra uma instância descartável da API.
- Preservar os testes e scripts Bruno durante a reorganização.

**Non-Goals:**

- Alterar endpoints, payloads, status ou regras de negócio existentes.
- Aplicar autenticação ou autorização genérica a User e Budget.
- Substituir OpenSpec, Pest/PHPUnit ou `ARCHITECTURE.md` pela documentação Bruno.
- Introduzir OpenAPI, geração de SDK, mock server ou publicação pública da documentação.
- Executar cenários destrutivos contra produção ou banco compartilhado.

## Decisions

### Somente `Accept` será herdado por toda a collection

Todos os endpoints da API negociam respostas JSON:API, então `Accept: application/vnd.api+json` será configurado uma vez no nível da collection. `Content-Type: application/vnd.api+json` permanecerá apenas nos requests que enviam documento JSON:API; requests sem body não anunciarão um media type de conteúdo desnecessário.

Authentication também permanecerá no nível do request nesta fase. Apenas `SignOut` e cenários que exigirem sessão enviarão Bearer. Uma configuração global enviaria o token aos endpoints públicos atuais de User e Budget e anteciparia uma decisão de autorização que suas specs ainda não tomaram.

Alternativa rejeitada: centralizar `Content-Type` e Bearer junto de `Accept`. Isso reduziria mais linhas, mas ampliaria headers e credenciais além dos requests que realmente os exigem.

### Variáveis serão classificadas pela duração e sensibilidade

O ambiente conterá somente valores públicos que mudam entre destinos, inicialmente `baseUrl`. Valores estáveis dos cenários, como IDs reservados para not-found, serão collection variables. IDs e dados criados por setup serão runtime variables e deixarão de existir ao fim da execução.

O fluxo Authentication gerará credenciais exclusivas durante a execução e manterá password e token apenas em runtime. Se CI ou um operador precisar fornecer um segredo em vez de gerá-lo, ele entrará por mecanismo secreto do Bruno ou variável de processo e nunca por um arquivo versionado. Relatórios também deverão omitir bodies ou headers sensíveis quando puderem transportar credenciais.

Alternativa rejeitada: manter todos os valores no arquivo de ambiente. Isso é simples, mas confunde destino, fixtures e segredos e aumenta o risco de versionar credenciais.

### O fluxo Authentication reutilizará a sessão emitida, sem fixture secreta

Os requests serão ordenados para criar uma identidade e credencial temporárias, iniciar sessão, capturar o token retornado uma única vez, provar uma chamada Bearer, encerrar a sessão e provar que o mesmo token foi revogado. Falhas de validação, credenciais inválidas e conflito continuarão em cenários próprios conforme a spec vigente de Authentication; throttling permanece fora do escopo da capability.

O token será salvo com `bru.setVar` no post-response de `SignIn`; nenhum valor real aparecerá na collection ou nos ambientes. Requests públicos de `SignUp` e `SignIn` declararão `auth: none`, e requests protegidos referenciarão a runtime variable.

Alternativa rejeitada: cadastrar um token fixo em Local. Tokens opacos são revogáveis e expiram; uma fixture persistente seria insegura e instável.

### A documentação Bruno será concisa e hierárquica

A documentação da collection explicará pré-requisitos, JSON:API, amount em centavos, ambientes, autenticação e como executar cenários com efeitos destrutivos. Cada pasta descreverá seu objetivo, ordem, setup e cleanup. Requests receberão documentação própria somente quando nome, método, payload e testes não expressarem suficientemente o comportamento, como token retornado uma vez ou transição inválida.

Essa documentação poderá apontar para OpenSpec em vez de copiar regras extensas. Assim, OpenSpec continua sendo a fonte normativa e a collection permanece uma referência prática para quem integra a API.

Alternativa rejeitada: repetir toda requirement OpenSpec em cada request. A duplicação aumentaria drift e dificultaria revisão.

### A suíte smoke será pequena, serial e isolada

Requests críticos receberão ou preservarão uma tag `smoke`. A automação subirá a aplicação com banco descartável, executará migrations, aguardará health e chamará a collection recursivamente por Bruno CLI. A execução será serial porque os cenários compartilham runtime variables e realizam setup/cleanup; uma falha de request, assertion ou test falhará a etapa.

O ambiente de CI terá `baseUrl` próprio e uma guarda impedirá destinos de produção ou não autorizados. Relatórios, se publicados como artefatos, mascararão headers sensíveis e não incluirão bodies que possam carregar password ou token. A versão do runner Bruno será fixada para evitar mudança silenciosa de sintaxe ou execução.

A forma de instalar o Bruno CLI será escolhida durante a implementação entre dependência de desenvolvimento e action oficial fixada. Nenhuma dependência será adicionada sem a aprovação exigida pelo projeto.

Alternativas rejeitadas: executar toda a collection em paralelo ou contra staging compartilhado. A primeira quebra encadeamento; a segunda torna os dados não determinísticos e amplia o risco de limpeza indevida.

### O HTML será derivado e regenerável

Bruno gerará uma referência HTML a partir da mesma collection documentada. O resultado será inspecionado para confirmar navegação, payloads, headers, autenticação e ausência de segredos. O procedimento e a versão da collection serão registrados, mas o HTML não será editado manualmente nem usado para definir comportamento.

O artefato poderá ser compartilhado internamente com o time do app consumidor. Hospedagem pública, domínio, controle de acesso e atualização automática ficam fora desta mudança; caso sejam necessários, terão decisão operacional própria.

Alternativa rejeitada: manter uma documentação HTML escrita separadamente. Ela duplicaria requests e perderia sincronização com os testes executáveis.

## Risks / Trade-offs

- [A collection e os endpoints podem divergir] -> Executar smoke em CI e derivar o HTML da mesma collection, mantendo regras duráveis em OpenSpec.
- [Cenários Bruno mutáveis podem deixar dados após falha intermediária] -> Usar dados exclusivos, cleanup explícito e banco descartável em CI; não prometer isolamento transacional entre requests HTTP.
- [Um relatório pode capturar password ou token] -> Usar runtime/secret variables, mascaramento e reporters configurados para omitir headers e bodies sensíveis.
- [Documentação interativa pode apontar para destino perigoso] -> Gerar com ambiente não produtivo e deixar produção fora dos ambientes publicados.
- [A mudança depende de endpoints ainda ativos em `add-authentication`] -> Implementar a organização comum independentemente e concluir os cenários autenticados somente após a capability Authentication estar disponível.
- [Fixar Bruno CLI introduz manutenção de ferramenta] -> Fixar versão, atualizar deliberadamente e obter aprovação antes de adicionar dependência ao projeto.

## Migration Plan

1. Inventariar headers, auth, variáveis, tags, scripts e testes atuais para preservar comportamento.
2. Configurar o header comum e mover variáveis para os escopos definidos, validando os fluxos existentes serialmente.
3. Adicionar documentação da collection e das pastas sem copiar requisitos extensos.
4. Após os endpoints de Authentication existirem, adicionar o fluxo runtime completo e cenários de segurança previstos naquela mudança.
5. Selecionar e fixar o runner Bruno aprovado, criar o ambiente isolado de CI e executar o subconjunto smoke serial.
6. Gerar e revisar o HTML para compartilhamento interno com o app consumidor.

Rollback remove a etapa de CI e a configuração compartilhada, restaura os headers e variáveis por request e descarta o HTML regenerável. Nenhuma migration ou alteração de dados da aplicação faz parte desta mudança.

## Open Questions

Nenhuma questão bloqueia a especificação. O local de hospedagem da referência HTML e uma eventual adoção futura de OpenAPI/SDK serão decididos separadamente caso o app consumidor necessite automação além da documentação executável.
