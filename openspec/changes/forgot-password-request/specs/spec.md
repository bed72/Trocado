# Spec: forgot-password-request

## Requirements

### Requirement: Enviar e-mail de recuperação de senha

The system SHALL call `POST /api/v1/auth/password/request` com o e-mail informado e retornar `Right(void)` em caso de sucesso.

#### Scenario: success

Given um e-mail válido informado pelo usuário
When `AuthenticationRepository.requestPasswordReset` é chamado
Then retorna `Right(void)` e nenhum token é persistido

---

### Requirement: Exibir confirmação de sucesso na tela

The system SHALL exibir um toast de sucesso com a mensagem `'Verifique seu email'` quando a requisição for bem-sucedida.

#### Scenario: success toast

Given o notifier recebe `Right(void)` do repositório
When o estado muda para `ForgotPasswordStatus.success`
Then a tela exibe um toast `.success` com title `'Verifique seu email'`
And a tela permanece aberta (sem navegação)

---

### Requirement: Exibir erro da API na tela

The system SHALL exibir um toast de falha com a mensagem da API quando a requisição falhar.

#### Scenario: failure toast

Given o notifier recebe `Left(ValidationFailure)` do repositório
When o estado muda para `ForgotPasswordStatus.failure`
Then a tela exibe um toast `.failure` com title `'Opps'` e description igual a `failure.message`

---

### Requirement: Validar e-mail antes de submeter

The system SHALL validar o campo e-mail antes de chamar o repositório e exibir `emailFailure` quando inválido.

#### Scenario: e-mail vazio

Given o campo e-mail está vazio
When o usuário pressiona 'Enviar'
Then `emailFailure` é setado, status permanece `initial` e o repositório NÃO é chamado

#### Scenario: e-mail inválido

Given o campo e-mail contém um valor sem formato de e-mail
When o usuário pressiona 'Enviar'
Then `emailFailure` é setado com a mensagem de validação

#### Scenario: e-mail válido

Given o campo e-mail contém um e-mail válido
When o usuário pressiona 'Enviar'
Then `emailFailure` é null e o repositório é chamado

---

### Requirement: Limpar falha ao editar o e-mail

The system SHALL limpar `emailFailure` quando o usuário editar o campo e-mail.

#### Scenario: clear failure on change

Given `emailFailure` está setado após submit inválido
When o usuário digita qualquer caractere no campo e-mail
Then `emailFailure` passa a ser null

---

### Requirement: PasswordResetResponse deserialization

The system SHALL desserializar corretamente a resposta da API em `PasswordResetResponse`.

#### Scenario: fromJson parseia detail

Given um JSON `{ "detail": "If this email is registered, a reset link has been sent." }`
When `PasswordResetResponse.fromJson` é chamado
Then `response.detail` contém o valor esperado

---

### Requirement: Falhas de rede e servidor mapeadas corretamente

The system SHALL retornar `Left(NetworkFailure)` em erro de rede e `Left(ServerFailure)` em erro de servidor.

#### Scenario: network error

Given nenhuma conectividade de rede
When `AuthenticationRepository.requestPasswordReset` é chamado
Then retorna `Left(NetworkFailure)`

#### Scenario: server error

Given a API responde com código de erro `server_error`
When `AuthenticationRepository.requestPasswordReset` é chamado
Then retorna `Left(ServerFailure)`
