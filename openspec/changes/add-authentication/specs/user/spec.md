## MODIFIED Requirements

### Requirement: Identidade local independente de autenticação
O sistema MUST representar `UserEntity` como uma identidade local composta por identificador persistido, nome e e-mail, sem exigir ou armazenar senha, hash, token, sessão ou contrato de autenticação. Domain e Application de User MUST permanecer independentes de Laravel, Eloquent, HTTP, Sanctum e Infrastructure. `UserModel`, por pertencer à Infrastructure, MUST implementar os contratos de autenticação Laravel e Sanctum necessários para representar essa identidade nas bordas.

#### Scenario: Usuário existe sem credencial conhecida
- **WHEN** um User anterior a Authentication é migrado
- **THEN** sua identidade permanece válida mesmo sem possuir uma senha conhecida
- **AND** o backfill irrecuperável não concede acesso a terceiros

#### Scenario: Entidade permanece pura
- **WHEN** as dependências de `UserEntity` são verificadas
- **THEN** a entidade não depende de Laravel, Illuminate, Eloquent, HTTP, Infrastructure, Sanctum ou contratos de autenticação

#### Scenario: Model integra com o framework
- **WHEN** `UserModel` é inspecionado após Authentication
- **THEN** ele implementa `Authenticatable` e usa `HasApiTokens`
- **AND** essa integração não é exposta por `UserEntity` nem pelos contratos de Application

### Requirement: Persistência mínima de User
O sistema MUST persistir identificador, nome, e-mail canônico, password hash e timestamps na tabela `users`. `UserModel` MUST representar essa persistência e o principal autenticável em Infrastructure sem funcionar como entidade de Domain. Tokens MUST permanecer na tabela oficial do Sanctum, e sessão web MUST permanecer no driver configurado pelo Laravel.

#### Scenario: Registro persistido
- **WHEN** um User é criado por `SignUp`
- **THEN** a tabela `users` contém nome, e-mail canônico, password hash e timestamps
- **AND** não contém token, sessão, remember token ou password em texto puro

#### Scenario: Mapping para o domínio
- **WHEN** `EloquentUserRepository` recupera um registro existente
- **THEN** retorna `UserEntity` sem password hash ou `UserModel`
- **AND** não expõe relações ou tipos do Sanctum fora de Infrastructure

#### Scenario: Serialização segura
- **WHEN** `UserModel` é serializado acidentalmente em uma borda Laravel
- **THEN** o atributo `password` permanece oculto
- **AND** nenhum Personal Access Token é incluído automaticamente
