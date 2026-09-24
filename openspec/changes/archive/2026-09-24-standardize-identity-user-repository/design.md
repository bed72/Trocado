## Context

`RegistrationAdapter` implementa `CreatePort` criando a linha `users` e convertendo `UserModel` em `UserEntity`. `EloquentIdentityRepository` já faz esse mapping nas leituras e atualizações, mas não oferece criação. A separação foi deliberada na consolidação de Identity; agora o contrato desejado é Repository para operações ordinárias de persistência do agregado, Port para outras capacidades de Infrastructure.

## Goals / Non-Goals

**Goals:**

- Concentrar criação, consulta, atualização e exclusão da identidade em `UserRepository`, com implementação Eloquent única para mapping.
- Usar `Core` `TransactionPort` como limite da transação definido pelo UseCase e manter `SignInPort`/`SignOutPort` como fronteiras da autenticação e do token atual.
- Preservar as invariantes e respostas existentes de SignUp e manutenção de User.

**Non-Goals:**

- Criar `AuthenticationRepository`, novo bounded context de negócio ou Repository genérico.
- Levar Eloquent, hashing, Auth ou Sanctum para Domain/Application.
- Alterar autenticação, políticas de password, rotas, schema ou contrato JSON:API.
- Criar outro caminho de criação de contas além de SignUp.

## Decisions

### UserRepository é a fronteira do agregado

`app/Identity/Application/Repositories/UserRepository.php` define as operações necessárias aos UseCases: `create(UserEntity, string password): UserEntity`, `all`, `findById`, `findByEmail`, `update` e `delete`. A senha transitória é marcada como sensível; nenhuma assinatura expõe Model, Builder, hash ou objeto Sanctum. A operação `create` exige uma entidade ainda não persistida e retorna a entidade persistida com ID e timestamps. Não há `save` genérico.

`app/Identity/Infrastructure/Persistence/Repositories/EloquentUserRepository.php` implementa a criação junto das operações existentes, reutiliza o mapping de `UserModel` para `UserEntity`, mantém o hash por mecanismo do Laravel na Infrastructure e traduz a violação da constraint de e-mail para `EmailAlreadyUsedException`. A constraint única continua sendo a garantia definitiva em concorrência. Na exclusão, o Repository continua removendo todos os tokens antes da identidade na mesma transação delimitada pelo UseCase; a FK mantém a remoção das despesas, inclusive soft-deleted.

O fato de o Repository receber a senha transitória não faz dela estado de `UserEntity`: a entrada serve somente à criação de um principal autenticável, sem expor hash ou credencial nos retornos.

### SignUp mantém a unidade de trabalho

`SignUpUseCase` valida `UserEntity` e `PasswordValueObject` e executa `UserRepository::create` dentro de `TransactionPort::execute`. Somente SignUp chama essa criação na Application atual. O registro continua sem login ou emissão implícita de token e mantém os mesmos erros públicos para e-mail duplicado e falhas.

### Ports representam capacidades distintas

`CreatePort` e `RegistrationAdapter` são removidos. `Core` `TransactionPort`, implementado por `DatabaseTransactionAdapter`, mantém transação e retry sem escolher as operações de negócio; `SignInPort` mantém validação por provider, rehash e emissão de token; `SignOutPort` mantém revogação somente do token atual. Essas operações podem tocar banco internamente sem se tornarem Repository de User: seu contrato expõe a capacidade, não CRUD do agregado.

### Bindings e especificações

`IdentityServiceProvider` vincula `UserRepository` a `EloquentUserRepository` e não registra `CreatePort`. A main spec será atualizada ao aplicar a mudança, junto de `ARCHITECTURE.md`, para remover a exceção antiga. O histórico de `consolidate-identity-context` permanece intacto; sua tarefa pendente de concorrência em PostgreSQL não é declarada concluída por esta spec.

## Risks / Trade-offs

- `UserRepository::create` recebe uma senha sensível além de `UserEntity`: isso mantém o Domain livre de credenciais, à custa de um argumento especializado no Repository. Impedir criação sem senha e restringir o chamador a SignUp preserva o lifecycle único.
- Mover o mapping pode alterar inadvertidamente ID, timestamps ou tratamento de erros: comparar comportamento de SignUp, consultas, atualização, exclusão e rollback antes de concluir a implementação.
- A mudança se sobrepõe a decisões da spec ainda aberta de consolidação: aplicar este delta depois dela, sem alterar artefatos históricos ou marcar sua tarefa de PostgreSQL como concluída.
