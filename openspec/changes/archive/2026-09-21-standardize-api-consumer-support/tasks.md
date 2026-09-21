## 1. Baseline da collection

- [x] 1.1 Inventariar os headers, modos de auth, variáveis, scripts, testes, tags e dependências de ordem atuais da collection antes da reorganização.
- [x] 1.2 Executar serialmente os fluxos existentes contra Local e registrar a baseline de requests aprovados para detectar regressões da própria collection.

## 2. Configuração compartilhada e variáveis

- [x] 2.1 Configurar `Accept: application/vnd.api+json` no nível da collection e remover somente as declarações redundantes dos requests, preservando overrides necessários.
- [x] 2.2 Manter `Content-Type: application/vnd.api+json` nos requests com documento JSON:API e confirmar que requests sem body não o recebem por herança.
- [x] 2.3 Manter no ambiente Local apenas `baseUrl`, mover IDs sentinela para collection variables e preservar IDs de setup como runtime variables.
- [x] 2.4 Revisar todos os arquivos Bruno versionados para confirmar que não contêm password, token, cookie ou credencial real.

## 3. Documentação operacional

- [x] 3.1 Documentar no nível da collection pré-requisitos, convenções JSON:API, amount em centavos, ambientes, autenticação, execução serial, efeitos destrutivos e relação com OpenSpec.
- [x] 3.2 Documentar as pastas de User, Budget, Budget Recurrence, System e Authentication com objetivo, ordem, setup e cleanup aplicáveis.
- [x] 3.3 Adicionar documentação por request apenas aos comportamentos não evidentes, incluindo token retornado uma vez e transições inválidas, sem duplicar integralmente as specs.

## 4. Fluxo Authentication

- [x] 4.1 Após `add-authentication` disponibilizar os endpoints, criar os requests Bruno de `SignUp`, `SignIn`, chamada Bearer, `SignOut` e rejeição do token revogado na ordem definida pela spec.
- [x] 4.2 Gerar e-mail e password exclusivos durante a execução, capturar o token de `SignIn` em runtime e confirmar que nenhum segredo é persistido na collection ou em ambientes.
- [x] 4.3 Manter `auth: none` nos requests públicos e configurar Bearer somente nos requests protegidos, confirmando que User e Budget atuais não recebem auth global.
- [x] 4.4 Completar os cenários de credenciais inválidas, validação e conflito previstos por Authentication, com cleanup dos dados auxiliares; manter throttling fora do escopo conforme a spec vigente.

## 5. Smoke tests em CI

- [x] 5.1 Definir o subconjunto mínimo `smoke` cobrindo health, contrato JSON:API e Authentication sem incluir cenários deliberadamente lentos ou instáveis.
- [x] 5.2 Selecionar uma integração oficial do Bruno CLI, obter aprovação antes de adicionar qualquer dependência e fixar sua versão.
- [x] 5.3 Criar um ambiente de CI com `baseUrl` não produtivo e uma guarda que interrompa a execução antes de requests mutáveis quando o host estiver fora da allowlist.
- [x] 5.4 Configurar a pipeline para preparar banco descartável, executar migrations, iniciar e aguardar health e rodar recursivamente a tag `smoke` de forma serial e com falha propagada.
- [x] 5.5 Configurar eventuais relatórios para mascarar headers sensíveis e omitir request/response bodies capazes de conter password ou token.

## 6. Referência HTML para o app consumidor

- [x] 6.1 Definir a versão ou revisão da collection e gerar a documentação HTML usando somente ambiente não produtivo.
- [x] 6.2 Revisar navegação, requests, payloads, headers e orientação de autenticação do HTML e confirmar a ausência de segredos e URLs de produção não aprovadas.
- [x] 6.3 Registrar o procedimento de regeneração e disponibilizar o artefato internamente sem edição manual do HTML nem publicação pública implícita.

## 7. Verificação final

- [x] 7.1 Reexecutar serialmente os fluxos Bruno completos e o subconjunto smoke após a reorganização, comparando-os com a baseline.
- [x] 7.2 Executar a suíte Pest/PHPUnit relevante para confirmar que a mudança operacional não mascarou regressões da aplicação.
- [x] 7.3 Validar a mudança OpenSpec estritamente e revisar o diff final para duplicação documental, segredos, destinos inseguros e dependências não aprovadas.
