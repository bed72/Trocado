## MODIFIED Requirements

### Requirement: Authentication não concede autorização
O sistema MUST limitar Authentication à comprovação do principal e MUST NOT interpretar token válido como autorização de negócio ou ownership sobre recursos de User ou Expense. As rotas atuais desses contextos MUST exigir `auth:sanctum`; as operações de User por ID MUST verificar ownership em seus UseCases por meio de um Port de Identity, independentemente da autenticação da rota. Outras regras de autorização e ownership MUST permanecer sob responsabilidade de specs próprias.

#### Scenario: Rotas autenticadas sem autorização de negócio
- **WHEN** um endpoint de User ou Expense recebe uma requisição sem Personal Access Token válido
- **THEN** responde `401`
- **AND** um token válido somente identifica o principal, sem provar ownership ou privilégio administrativo
- **AND** regras de autorização e ownership permanecem responsabilidade das operações de cada contexto

#### Scenario: Token válido de outra conta
- **WHEN** uma conta autenticada tenta consultar, alterar ou excluir outra conta pela rota de User
- **THEN** a autenticação é insuficiente para autorizar a operação
- **AND** a regra de ownership de User impede o acesso
