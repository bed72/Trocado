## Context

GET, PATCH e DELETE `/api/users/{user}` exigem `auth:sanctum`, mas os UseCases recebem somente o ID da URL. `SignOutPort`/`SignOutAdapter` já separam o acesso ao guard Sanctum da Application, sem depender de `$request->user()` nos Controllers. O requisito atual de Authentication reconhece que autenticar não prova ownership. Expense já limita sua listagem pelo proprietário, fora do escopo desta mudança.

## Goals / Non-Goals

**Goals:** limitar as três operações de User ao titular, sem vazar a existência de outras contas e sem acoplar Application ou Controllers ao Request para obter o principal; manter sucesso e formato de erro existentes.

**Non-Goals:** autorização administrativa, policies genéricas, RLS, migração de banco, alteração de Expense ou refatoração da autenticação existente.

## Decisions

1. Adicionar em Identity Application um Port dedicado, por exemplo `AuthenticatedUserPort::id(): int`, implementado por Adapter em Identity Infrastructure e registrado em `IdentityServiceProvider`. O Adapter usa explicitamente o guard `sanctum`, conforme o padrão do `SignOutAdapter`, verifica que o principal é `UserModel` e devolve apenas um identificador inteiro. Sem principal válido, falha como autenticação (`401`); nunca usa ID do payload nem oferece fallback para outro guard. Alternativa descartada: `$request->user()` nos Controllers, que faz a política depender de um parâmetro de confiança escolhido pela borda HTTP, ou estender `SignOutPort`, que tem responsabilidade distinta.
2. `GetUserUseCase`, `UpdateUserUseCase` e `DeleteUserUseCase` consultam o Port e comparam seu ID com o ID alvo antes de qualquer leitura ou escrita no Repository. Em divergência, produzem a mesma `UserNotFoundException` usada para identidade ausente; o mapeamento JSON:API existente devolve `404` nos dois casos. A verificação vem antes da consulta de e-mail e da transação de exclusão; o fluxo de exclusão próprio continua atômico via `TransactionPort`. Alternativas descartadas: checagem exclusiva em middleware/Form Request, `403` que confirma existência da conta e filtros Eloquent ocultos que não protegem outros chamadores dos UseCases.
3. Os Controllers continuam passando somente o alvo da URL e os dados validados; não resolvem o principal. A validação `data.id` continua exigindo que o ID informado corresponda ao alvo da URL, sem se tornar autorização. As rotas mantêm `auth:sanctum` e os nomes atuais. Não é necessário criar um Port para o Repository nem retornar `UserModel` à Application.

## Risks / Trade-offs

- [UseCase executado sem contexto autenticado] → O Adapter falha explicitamente com `401`; chamadas não HTTP devem estabelecer principal válido em vez de ganhar bypass.
- [ID alheio e inexistente são indistinguíveis] → Escolha intencional para não revelar contas, inclusive quando o ID alheio não existe; validar ambos os casos e ausência de efeitos colaterais.
- [Mudança para clientes que operavam contas de terceiros] → Contrato quebra esse acesso; nenhum privilégio implícito é mantido.

## Migration Plan

Implantar a mudança de código sem migration. Rollback do código restaura o comportamento anterior, mas também reabre o acesso cruzado: não usar como mitigação permanente.

## Open Questions

Nenhuma decisão bloqueante; `404` para conta alheia segue a proposta discutida.
