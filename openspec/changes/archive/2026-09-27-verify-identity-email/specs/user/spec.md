## ADDED Requirements

### Requirement: Verificação de e-mail persiste separada do status de User
O sistema MUST manter `users.email_verified_at` nullable e independente de `status` (`pending`, `active`, `blocked`). `UserModel` MUST implementar `Illuminate\Contracts\Auth\MustVerifyEmail` e usar os recursos nativos do Laravel nas bordas. O timestamp MUST NOT entrar em `UserEntity` apenas por existir no schema; Repository e UseCases de User MUST manter tipos sem Eloquent nem detalhes do framework. A migration MUST ser incremental e não apagar ou verificar implicitamente contas existentes.

#### Scenario: Estados ortogonais
- **WHEN** um endereço de uma conta `pending` é confirmado
- **THEN** a conta pode estar simultaneamente `pending` e com `email_verified_at` preenchido
- **AND** GET/PATCH/DELETE preservam suas regras atuais de autenticação e ownership

#### Scenario: Migração com conta preexistente
- **WHEN** a migration é aplicada sobre tabela `users` com registros existentes
- **THEN** ela adiciona o campo nullable sem excluir registros nem mudar seus status ou tokens
- **AND** uma conta com valor nulo continua sujeita às regras novas de acesso

### Requirement: E-mail de User é imutável pela API nesta etapa
O sistema MUST aceitar somente `name` como atributo de `PATCH /api/users/{user}`. Uma tentativa de incluir `email`, mesmo igual ao atual ou canonicamente equivalente, MUST responder `422` em JSON:API antes do UseCase, sem alterar e-mail, verificação, tokens ou outros atributos. `UpdateUserUseCase` MUST aceitar somente ID e nome e `UserRepository::update` MUST persistir somente o nome; não deve haver operação exposta de alteração de e-mail e revogação de tokens nessa interface. Atualizar nome MUST conservar o timestamp de verificação e todos os tokens. A checagem de ownership permanece obrigatória.

#### Scenario: E-mail diferente é enviado no PATCH
- **WHEN** o titular autenticado tenta enviar `email` novo no PATCH
- **THEN** responde `422` JSON:API com erro de validação e não altera User
- **AND** preserva todos os tokens, o e-mail e `email_verified_at` anteriores
- **AND** não solicita novo envio de verificação

#### Scenario: Mesmo e-mail canônico é enviado no PATCH
- **WHEN** o titular envia seu próprio e-mail com ou sem diferenças de caixa/espaços
- **THEN** responde `422` JSON:API sem alterar os dados ou tokens

#### Scenario: Atualização só de nome
- **WHEN** o titular altera o nome válido sem incluir e-mail
- **THEN** responde `200` com recurso `users` contendo nome atualizado e o mesmo e-mail
- **AND** verificação e todos os tokens são preservados, sem enfileirar nova mensagem

#### Scenario: Tentativa de alterar conta de terceiro
- **WHEN** um token da conta A tenta editar o nome da conta B
- **THEN** recebe o mesmo `404` de ownership atual antes de ler ou alterar B
- **AND** nenhum token é revogado

#### Scenario: Entrada inválida ou usuário removido
- **WHEN** o nome é inválido ou o alvo não existe
- **THEN** preserva a conta e os tokens, sem notificação de verificação

## MODIFIED Requirements

### Requirement: Atualização parcial de User
O sistema MUST permitir atualizar somente o nome de um User existente pelo `UserRepository::update`, MUST preservar e-mail, status, verificação e tokens, MUST reaplicar normalização e invariantes do nome e MUST retornar a entidade persistida atualizada. O e-mail não é editável por este endpoint nesta etapa.

#### Scenario: Atualização de nome
- **WHEN** um novo nome válido é informado
- **THEN** o nome canônico é atualizado
- **AND** o e-mail existente, a verificação e os tokens são preservados

#### Scenario: E-mail enviado
- **WHEN** a requisição tenta atualizar ou reenviar o e-mail existente
- **THEN** responde `422` JSON:API e nenhuma atualização ou revogação é executada

#### Scenario: Nome inválido
- **WHEN** o nome informado viola as regras de `NameValueObject`
- **THEN** a atualização é rejeitada sem alterar a conta

#### Scenario: Atualização de User inexistente
- **WHEN** se tenta atualizar um identificador inexistente
- **THEN** o caso de uso produz uma exceção explícita de User não encontrado
