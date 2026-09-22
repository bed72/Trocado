## 1. Fronteira e estrutura de Identity

- [x] 1.1 Atualizar primeiro os testes de arquitetura para reconhecer somente `Identity` e `Budget`, remover a allowlist `Authentication Infrastructure -> App\User` e provar a matriz normal de dependências.
- [x] 1.2 Criar `app/Identity/{Domain,Application,Infrastructure,Presentation}` e migrar `UserEntity`, `EmailValueObject`, `PasswordValueObject`, enums e exceções de Domain com namespaces Identity e testes unitários equivalentes.
- [x] 1.3 Migrar Inputs, Outputs, exceções e UseCases de User e Authentication para Identity Application, preservando retornos naturais e `SignInOutput`.
- [x] 1.4 Remover os diretórios antigos somente depois de atualizar todos os imports e adicionar uma verificação que não reste referência a `App\User` ou `App\Authentication`.
- [x] 1.5 Introduzir `NameValueObject`, fazer `UserEntity` carregá-lo e espelhar nos Form Requests a normalização de whitespace, o uso exclusivo de letras Unicode separadas por espaços e o limite inclusivo de 2 a 12 letras sem contar espaços.

## 2. Contratos da Application

- [x] 2.1 Criar `IdentityWritePort` com callback transacional e testes de UseCase que provem que a Application escolhe o escopo atômico completo.
- [x] 2.2 Criar `CreatePort` limitado a provisionar um novo principal e sua credencial, com password sensível e retorno `UserEntity`, sem métodos de consulta, atualização, exclusão ou save genérico.
- [x] 2.3 Migrar `SignInPort` e `SignOutPort` para Identity mantendo contratos separados, `SignInOutput` e ausência de tipos Laravel.
- [x] 2.4 Substituir `UserRepository` por `IdentityRepository` sem operação de criação e atualizar testes de consulta, listagem, atualização e exclusão.
- [x] 2.5 Atualizar `SignUpUseCase` para executar `CreatePort` dentro de `IdentityWritePort` e cobrir sucesso, conflito e rollback sem emissão implícita de token.
- [x] 2.6 Atualizar `DeleteUserUseCase` para executar a remoção de todos os tokens e da identidade dentro de `IdentityWritePort`, cobrindo sucesso, User inexistente e rollback conjunto.
- [x] 2.7 Remover `CreateUserUseCase` e seus testes, confirmando que nenhum contrato alternativo da Application ainda cria User.

## 3. Infrastructure e persistência

- [x] 3.1 Implementar `IdentityWriteAdapter` com transação e retry, sem escolher operações de negócio dentro do Adapter.
- [x] 3.2 Implementar `RegistrationAdapter` com `UserModel`, hash Laravel, tradução de unicidade e retorno de `UserEntity`, incluindo teste de persistência sem password em texto puro.
- [x] 3.3 Migrar `SignInAdapter` e `SignOutAdapter` para Identity e manter testes de provider, rehash, emissão, expiração e revogação seletiva do token atual.
- [x] 3.4 Migrar `UserModel` para Identity Infrastructure, remover o callback que gera password aleatório e testar que criação sem password é rejeitada.
- [x] 3.5 Implementar `EloquentIdentityRepository`, incluindo remoção dos tokens associados antes de excluir `users`, e testar mapping, queries, atualização, cleanup e rollback.
- [x] 3.6 Criar `IdentityServiceProvider` com bindings de `IdentityRepository` e das quatro Ports, registro de Commands aplicáveis e prevenção de lazy loading fora de produção.
- [x] 3.7 Remover `UserServiceProvider` e `AuthenticationServiceProvider` após testes de resolução confirmarem todos os bindings de Identity.
- [ ] 3.8 Executar os testes de unicidade e registro concorrente no banco alvo quando PostgreSQL estiver disponível; até lá, manter a limitação SQLite explicitamente visível na evidência da mudança.

## 4. Presentation e contrato HTTP

- [x] 4.1 Migrar Controllers, Form Requests, Responses e rotas de User e Authentication para Identity Presentation sem alterar os endpoints preservados.
- [x] 4.2 Remover `POST /api/users`, `CreateUserController` e `CreateUserRequest` e adicionar teste de `405` JSON:API sem persistência.
- [x] 4.3 Preservar route names, resource types, IDs string, `Location`, headers contra cache e envelopes JSON:API de SignUp, SignIn, SignOut, GET, PATCH e DELETE.
- [x] 4.4 Atualizar os testes HTTP para criar contas exclusivamente por SignUp e autenticar todas as operações protegidas com Personal Access Token de runtime.
- [x] 4.5 Testar que excluir uma conta com múltiplos tokens responde `204`, remove os tokens e impede autenticação posterior.

## 5. Composition roots e configuração

- [x] 5.1 Registrar somente `IdentityServiceProvider` e `BudgetServiceProvider` em `bootstrap/providers.php`.
- [x] 5.2 Atualizar `bootstrap/app.php` para carregar as rotas Identity e mapear exceções pelos novos namespaces sem alterar os documentos de erro.
- [x] 5.3 Atualizar `config/auth.php` e demais referências ao principal para o novo namespace de `UserModel`.
- [x] 5.4 Confirmar por `route:list` que `POST /api/users` não existe, as rotas preservadas mantêm nomes e middleware e não restam rotas duplicadas.
- [x] 5.5 Confirmar que a mudança não exige migration de dados ou renome de tabela e que todas as migrations existentes continuam aplicáveis em clone limpo.

## 6. Consumidores e documentação

- [x] 6.1 Atualizar a collection Bruno para usar SignUp em todo setup de User, remover requests de `POST /api/users` e manter Bearer somente em runtime.
- [x] 6.2 Corrigir o fluxo smoke para executar cleanup autenticado antes de revogar o token ou obter uma sessão própria válida para exclusão.
- [ ] 6.3 Regenerar a referência HTML derivada e verificar que ela não contém password, token, header real ou documentação do endpoint removido.
- [x] 6.4 Atualizar `ARCHITECTURE.md`, `README.md` e Obsidian para apresentar Identity como owner do lifecycle e registrar `POST /api/users` como breaking change.
- [x] 6.5 Atualizar as main specs e a matriz de rastreabilidade para os novos namespaces, Ports, remoção de endpoint e cleanup de tokens.

## 7. Verificação completa

- [x] 7.1 Executar separadamente testes de Identity Domain, Application, Infrastructure, Presentation e arquitetura e corrigir todas as falhas.
- [x] 7.2 Executar a suíte Budget para confirmar que a consolidação de identidade não altera comportamento financeiro existente.
- [x] 7.3 Executar a suíte completa, confirmar ausência de referências aos contextos removidos e registrar a contagem final de 273 testes e 1.186 assertions.
- [x] 7.4 Executar `vendor/bin/pint --dirty --format agent` depois da última alteração PHP e repetir os testes afetados.
- [x] 7.5 Executar `openspec validate consolidate-identity-context --type change --strict --json --no-interactive` e manter todas as tarefas não comprovadas desmarcadas.
