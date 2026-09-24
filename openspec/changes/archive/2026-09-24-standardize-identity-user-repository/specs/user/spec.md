## MODIFIED Requirements

### Requirement: Atualização parcial de User
O sistema MUST permitir atualizar nome e/ou e-mail de um User existente, MUST preservar atributos omitidos e MUST reaplicar normalização, invariantes e unicidade de e-mail. A operação MUST usar `UserRepository::update` e MUST retornar a entidade persistida atualizada.

#### Scenario: Atualização de nome
- **WHEN** somente um novo nome válido é informado
- **THEN** o nome canônico é atualizado
- **AND** o e-mail existente é preservado

#### Scenario: Atualização de e-mail
- **WHEN** um novo e-mail ainda não utilizado é informado
- **THEN** o e-mail canônico é atualizado
- **AND** o nome existente é preservado

#### Scenario: Manutenção do próprio e-mail
- **WHEN** o User é atualizado com outra representação do seu próprio e-mail canônico
- **THEN** a atualização é permitida
- **AND** nenhum conflito de unicidade é produzido

#### Scenario: E-mail de outro User
- **WHEN** a atualização tenta usar o e-mail canônico de outro User
- **THEN** a atualização é rejeitada como e-mail já utilizado
- **AND** o User permanece inalterado

#### Scenario: Atualização de User inexistente
- **WHEN** se tenta atualizar um identificador inexistente
- **THEN** o caso de uso produz uma exceção explícita de User não encontrado

### Requirement: Exclusão de User
O sistema MUST excluir uma conta existente dentro de `Core` `TransactionPort`, MUST remover todos os seus Personal Access Tokens antes de remover `users` por `UserRepository::delete` e MUST reverter ambos diante de falha. A exclusão definitiva do User MUST remover também todas as suas despesas, inclusive as que possuírem `deleted_at` preenchido, na mesma transação. Uma identidade inexistente MUST produzir a mesma falha explícita de User não encontrado.

#### Scenario: Exclusão bem-sucedida
- **WHEN** uma conta existente com múltiplos tokens é excluída
- **THEN** todos os tokens dessa identidade e seu registro `users` são removidos
- **AND** consultas e autenticação posteriores não a encontram

#### Scenario: Exclusão com despesas
- **WHEN** uma conta com despesas ativas e logicamente excluídas é removida
- **THEN** todas as despesas dessa conta são removidas definitivamente na mesma transação
- **AND** não restam despesas órfãs

#### Scenario: Falha durante exclusão
- **WHEN** a remoção da identidade falha depois da tentativa de remover tokens
- **THEN** a transação restaura os tokens e mantém o User
- **AND** mantém também todas as suas despesas

#### Scenario: Exclusão de User inexistente
- **WHEN** se tenta excluir um identificador inexistente
- **THEN** o caso de uso produz uma exceção explícita de User não encontrado

### Requirement: Contrato explícito de Repository
O sistema MUST declarar `UserRepository` na camada Application com `create(UserEntity, string password): UserEntity`, `update(UserEntity): ?UserEntity`, `delete(int): bool`, `all(): array`, `findById(int): ?UserEntity` e `findByEmail(EmailValueObject): ?UserEntity`. A senha de criação MUST ser tratada como sensível e transitória; o contrato MUST usar apenas tipos independentes do ORM e sua implementação Eloquent MUST permanecer em Infrastructure. Apenas SignUp MUST criar contas no fluxo atual.

#### Scenario: Fronteira independente do ORM
- **WHEN** o contrato `UserRepository` é verificado
- **THEN** seus parâmetros e retornos não incluem Model, Builder, query, facade ou outro tipo de Infrastructure
- **AND** a criação não expõe password hash ou `save` genérico

#### Scenario: Criação com credencial válida
- **WHEN** `SignUpUseCase` entrega uma `UserEntity` ainda não persistida e password válido
- **THEN** `UserRepository::create` retorna `UserEntity` com ID e timestamps
- **AND** o password hash é persistido sem inserir password em texto puro ou emitir token

#### Scenario: Conflito na criação
- **WHEN** o e-mail canônico já existe ou conflita sob concorrência
- **THEN** a constraint única permite no máximo uma identidade
- **AND** `EloquentUserRepository` traduz o conflito para a exceção de Application esperada

#### Scenario: Binding da implementação
- **WHEN** o container resolve `UserRepository`
- **THEN** `IdentityServiceProvider` fornece `EloquentUserRepository`
- **AND** nenhum Repository base ou genérico é introduzido

### Requirement: Persistência mínima de User
O sistema MUST persistir identificador, nome, e-mail canônico, password hash e timestamps na tabela `users`. `UserModel` de Identity Infrastructure MUST representar essa persistência e o principal autenticável sem funcionar como entidade de Domain. Tokens MUST permanecer na tabela oficial do Sanctum, e novas contas MUST NOT receber password aleatório de fallback.

#### Scenario: Registro persistido
- **WHEN** um User é criado por SignUp e `UserRepository::create`
- **THEN** a tabela `users` contém nome, e-mail canônico, password hash e timestamps
- **AND** não contém token, remember token ou password em texto puro

#### Scenario: Ausência de fallback
- **WHEN** código tenta criar `UserModel` sem password fora do fluxo de registro
- **THEN** a persistência rejeita a operação
- **AND** nenhum callback inventa uma credencial silenciosamente

#### Scenario: Mapping para o domínio
- **WHEN** `EloquentUserRepository` cria ou recupera um registro existente
- **THEN** retorna `UserEntity` sem password hash ou `UserModel`
- **AND** não expõe relações ou tipos do Sanctum fora de Infrastructure

#### Scenario: Serialização segura
- **WHEN** `UserModel` é serializado acidentalmente em uma borda Laravel
- **THEN** o atributo `password` permanece oculto
- **AND** nenhum Personal Access Token é incluído automaticamente
