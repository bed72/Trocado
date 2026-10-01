## 1. Configuração e emissão

- [x] 1.1 Inspecionar emissores de Personal Access Tokens da API e confirmar que nenhum depende de `sanctum.expiration` com `expires_at` nulo; ajustar o contrato de configuração do Sanctum para não impor o corte global de 120 minutos.
- [x] 1.2 Ajustar SignIn para emitir somente um token Sanctum por login com `expires_at` inicial em 30 dias; preservar hash, Bearer, JSON:API e headers `no-store` sem alterar logins independentes.

## 2. Extensão por atividade em Identity

- [x] 2.1 Definir a política na Application de Identity e a fronteira necessária para estender apenas o token atual: janela inclusiva de 15 dias, novo prazo de até 30 dias e teto de 90 dias a partir de `created_at`.
- [x] 2.2 Implementar a atualização condicional atômica na Infrastructure usando o registro Sanctum atual; conferir existência, expiração, idade e prazo persistido no instante da escrita, sem alterar segredo, `created_at` ou criar linha adicional.
- [x] 2.3 Conectar middleware fino de Identity às rotas protegidas de User e Expense depois dos controles de autenticação e elegibilidade; estender apenas respostas `2xx`, sem aplicar a rotas públicas nem ao SignOut.

## 3. Comportamento e segurança

- [x] 3.1 Verificar o ciclo temporal com relógio controlado: validade inicial, acesso semanal/quinzenal, request antes da janela sem extensão, extensão com 15 dias restantes, término após 30 dias da última extensão efetiva e recusa no limite absoluto de 90 dias.
- [x] 3.2 Verificar que Bearer inválido/vencido/revogado, contas inativas/não verificadas, erros `403`/`404`/`422`/`429`/`5xx` e SignOut não prolongam a sessão; outros tokens do usuário continuam independentes.
- [x] 3.3 Verificar concorrência: extensões paralelas não encurtam `expires_at`, revogação concorrente não recria registro, e expiração entre autenticação e escrita não reativa token; conferir que o identificador/hash e a quantidade de tokens permanecem estáveis.
- [x] 3.4 Verificar que tokens legados com `expires_at` futuro seguem válidos até seu prazo e que o comando `sanctum:prune-expired --hours=24` mantém a remoção por `expires_at` com a configuração global desligada.

## 4. Entrega

- [x] 4.1 Revisar contratos JSON:API e comunicação de cliente para tratar `expires_at` do SignIn como snapshot inicial e `401` como necessidade de novo login, sem novo token nas respostas protegidas.
- [x] 4.2 Executar verificações focadas de autenticação/rotas, conformidade com as fronteiras de Identity, validação OpenSpec e Laravel Pint após as mudanças PHP; registrar qualquer limitação de verificação antes de encerrar a implementação.
