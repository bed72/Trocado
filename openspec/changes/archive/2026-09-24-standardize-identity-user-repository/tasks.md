## 1. Contratos e fluxo de Identity

- [x] 1.1 Substituir `IdentityRepository` por `UserRepository` e incluir criação autenticável com password sensível, retorno `UserEntity` e tipos independentes do ORM.
- [x] 1.2 Fazer `SignUpUseCase` usar `UserRepository::create` dentro de `TransactionPort::execute`; remover `CreatePort` da Application.
- [x] 1.3 Atualizar os demais UseCases de consulta, atualização e exclusão para o novo contrato, preservando a transação de exclusão.

## 2. Infrastructure

- [x] 2.1 Consolidar a criação e o mapping do antigo `RegistrationAdapter` em `EloquentUserRepository`, mantendo hash, exceção de unicidade, proteção de senha e cleanup transacional de tokens na exclusão.
- [x] 2.2 Atualizar `IdentityServiceProvider` para o binding do novo Repository; remover `RegistrationAdapter` e o binding de `CreatePort`.
- [x] 2.3 Confirmar que não há outro caminho público de criação nem alteração do schema, rotas ou recursos JSON:API.

## 3. Evidência e alinhamento

- [x] 3.1 Atualizar as verificações focadas de contratos, UseCases, Repository, provider e API de Identity para criação, leitura, atualização, exclusão, unicidade, rollback e ausência de token implícito; manter a limitação de concorrência real em PostgreSQL explícita se não houver banco alvo.
- [x] 3.2 Atualizar `ARCHITECTURE.md` e as main specs `identity-context`, `user` e `authentication` para refletir o Repository como owner da persistência de User e a remoção de `CreatePort`.
- [x] 3.3 Executar verificações focadas de Identity e arquitetura, Pint quando PHP for alterado, e validar esta mudança OpenSpec em modo strict; marcar tarefas apenas após evidência.

Evidência: suíte Identity (134 testes, 623 assertions), suíte completa (175 testes, 805 assertions), Pint e validação strict passaram. A corrida simulada cobre a tradução da constraint única no SQLite; concorrência real em PostgreSQL permanece sem execução por indisponibilidade do banco alvo.
