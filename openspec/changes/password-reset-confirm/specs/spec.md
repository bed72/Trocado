# Spec: password-reset-confirm

## Requirements

---

### Requirement: Acesso exclusivo por deep link
The system SHALL render `PasswordResetConfirmScreen` only when navigated via deep link `/reset-password?uid=<uid>&token=<token>`, extracting `uid` and `token` from the query parameters.

#### Scenario: Deep link com uid e token válidos
Given o app recebe o deep link `/reset-password?uid=Mw&token=bm7gkj-1a2b3c4d`
When o router processa a URL
Then `PasswordResetConfirmScreen` é renderizada com `uid="Mw"` e `token="bm7gkj-1a2b3c4d"`

---

### Requirement: Validação de nova senha
The system SHALL validate that `newPassword` is non-empty and has at least 8 characters before submitting.

#### Scenario: Campo nova senha vazio
Given o usuário não preencheu o campo "Nova senha"
When `SubmitPressed` é disparado
Then `state.newPasswordFailure` é não-nulo
And `state.status` permanece `initial`
And o repositório não é chamado

#### Scenario: Nova senha com menos de 8 caracteres
Given o usuário preencheu "Nova senha" com `"abc123"`
When `SubmitPressed` é disparado
Then `state.newPasswordFailure` é não-nulo
And o repositório não é chamado

---

### Requirement: Validação de confirmação de senha
The system SHALL validate that `confirmPassword` matches `newPassword` before submitting.

#### Scenario: Senhas não coincidem
Given `newPassword` é `"NewSecure!456"` e `confirmPassword` é `"Different!789"`
When `SubmitPressed` é disparado
Then `state.confirmPasswordFailure` é não-nulo
And o repositório não é chamado

#### Scenario: Senhas coincidem
Given `newPassword` e `confirmPassword` são ambos `"NewSecure!456"`
When `SubmitPressed` é disparado
Then nenhum `failure` é definido no estado
And o repositório é chamado

---

### Requirement: Limpeza de falhas ao editar campos
The system SHALL clear `newPasswordFailure` when `NewPasswordChanged` is dispatched, and `confirmPasswordFailure` when `ConfirmPasswordChanged` is dispatched.

#### Scenario: Limpa falha de nova senha ao editar
Given `state.newPasswordFailure` é não-nulo
When `NewPasswordChanged("NewSecure!456")` é disparado
Then `state.newPasswordFailure` é nulo

#### Scenario: Limpa falha de confirmação ao editar
Given `state.confirmPasswordFailure` é não-nulo
When `ConfirmPasswordChanged("NewSecure!456")` é disparado
Then `state.confirmPasswordFailure` é nulo

---

### Requirement: Indicador de carregamento
The system SHALL set `status` to `loading` immediately when submit is triggered with valid data, before the repository responds.

#### Scenario: Status loading durante requisição
Given `newPassword` e `confirmPassword` são válidos e coincidem
When `SubmitPressed` é disparado
Then `state.status` é `loading` imediatamente
And o botão "Redefinir senha" exibe indicador de carregamento

---

### Requirement: Sucesso na redefinição
The system SHALL display a success toast and navigate to `SignInLocation` (root, replace) when the repository returns `Right`.

#### Scenario: Redefinição bem-sucedida
Given o repositório retorna `Right(null)`
When a requisição completa
Then toast `.success` com título "Senha redefinida" é exibido
And o app navega para `SignInLocation` com `root: true, replace: true`
And `state.status` é `success`

---

### Requirement: Falha na redefinição
The system SHALL display a failure toast with the error message when the repository returns `Left(Failure)`.

#### Scenario: Token expirado ou inválido
Given o repositório retorna `Left(ValidationFailure('Token inválido ou expirado.'))`
When a requisição completa
Then toast `.failure` com título "Opps" e descrição "Token inválido ou expirado." é exibido
And `state.status` é `failure`
And `state.message` é `"Token inválido ou expirado."`

#### Scenario: Erro de rede
Given o repositório retorna `Left(NetworkFailure())`
When a requisição completa
Then toast `.failure` é exibido com a mensagem padrão de `NetworkFailure`
And `state.status` é `failure`
