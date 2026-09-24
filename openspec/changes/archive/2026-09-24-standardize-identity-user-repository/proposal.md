## Why

Em Identity, `CreatePort` persiste `UserModel` e faz mapping para `UserEntity`, enquanto `IdentityRepository` consulta, atualiza e exclui a mesma identidade. A exceção atual divide a persistência do mesmo agregado entre Port e Repository e duplica o mapping. Queremos que Repository seja a fronteira de leitura e escrita do agregado User e que Ports representem capacidades como transação e autenticação.

## What Changes

- Renomear `IdentityRepository` e sua implementação para `UserRepository` e `EloquentUserRepository`, reunindo criação, leitura, atualização e exclusão da identidade.
- Fazer `SignUpUseCase` criar a conta por `UserRepository` dentro de `Core` `TransactionPort`, sem emitir token implicitamente.
- Remover `CreatePort` e `RegistrationAdapter`; usar `Core` `TransactionPort` para transações e manter `SignInPort` e `SignOutPort` para suas capacidades atuais.
- Preservar a criação exclusiva pelo SignUp, a unicidade do e-mail, o hash do password na Infrastructure, o cleanup de tokens na exclusão e os contratos HTTP existentes.
- Atualizar bindings, testes de Identity, `ARCHITECTURE.md` e as main specs afetadas na aplicação da mudança.

## Capabilities

### Modified Capabilities

- `identity-context`: Repository assume persistência do agregado User; Ports permanecem para transação, login e logout.
- `user`: Contrato e implementação de persistência passam a ser `UserRepository` e `EloquentUserRepository` com criação autenticável.
- `authentication`: SignUp usa Repository para criar a identidade e mantém transação e comportamento externo.

## Impact

- Somente classes, bindings, referências e verificações de Identity precisam ser reorganizados; não são necessários novos contextos, tabelas, colunas ou migrations.
- `POST /api/authentication/sign-up` continua sendo a única criação pública; `POST /api/users` permanece indisponível.
- Esta mudança substitui a exceção arquitetural explícita para `CreatePort` documentada na mudança de consolidação de Identity e em `ARCHITECTURE.md`; a mudança anterior não é reescrita retroativamente.
