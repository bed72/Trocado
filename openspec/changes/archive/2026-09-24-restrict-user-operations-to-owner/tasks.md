## 1. Fronteira de autenticação em Identity

- [x] 1.1 Declarar Port em Identity Application para obter somente o ID do principal autenticado; implementar Adapter via guard Sanctum com falha explícita sem UserModel válido e registrar o binding no provider.
- [x] 1.2 Verificar por testes focados que o Port entrega o ID autenticado e rejeita principal ausente ou guard diferente sem fallback.

## 2. Ownership das operações de User

- [x] 2.1 Exigir igualdade entre principal e alvo nos UseCases de consulta por ID, atualização e exclusão antes de qualquer consulta ou escrita; preservar a transação de exclusão para operações autorizadas.
- [x] 2.2 Manter Controllers finos com ID alvo da rota e dados validados, sem `$request->user()` ou ID de principal informado pelo cliente; confirmar `401` sem principal e `404` JSON:API indistinguível para alheio e inexistente.
- [x] 2.3 Verificar por testes de UseCase e HTTP com duas contas que GET/PATCH/DELETE próprios mantêm o sucesso, ações cruzadas não consultam nem alteram a conta alheia, seus tokens ou suas despesas, e requisições sem autenticação são rejeitadas.

## 3. Verificação da mudança

- [x] 3.1 Executar testes focados, verificação arquitetural e Laravel Pint; revisar diff e validar a mudança OpenSpec em modo strict antes de considerá-la implementada.
