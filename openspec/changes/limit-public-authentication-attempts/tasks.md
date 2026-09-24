## 1. Políticas HTTP de Identity

- [x] 1.1 Registrar no `IdentityServiceProvider` o limite nomeado de SignIn (5/min por IP + e-mail canônico; 30/min por IP), usando chaves distintas e sem persistir e-mail em claro na chave.
- [x] 1.2 Registrar o limite nomeado de SignUp (3/h por IP), com contador independente de SignIn e contabilização de requisições admitidas com qualquer resultado.
- [x] 1.3 Aplicar os dois limitadores exclusivamente às rotas públicas correspondentes em `Identity/Presentation/Routes/api.php`.
- [x] 1.4 Configurar o store Redis dedicado do limiter sem alterar o cache geral; explicitar a configuração de ambiente e confirmar que a falha do Redis não usa fallback local.

## 2. Verificação dos contratos

- [x] 2.1 Verificar pelo fluxo HTTP que SignIn limita a combinação IP/e-mail após 5 tentativas, limita o IP após 30 tentativas com e-mails variados e compartilha a cota entre variantes de caixa/espaços do mesmo e-mail.
- [x] 2.2 Verificar pelo fluxo HTTP que SignUp limita após 3 requisições por IP, que contadores dos dois endpoints são independentes e que outra origem não é afetada.
- [x] 2.3 Verificar que `429` preserva `Retry-After` e o envelope JSON:API, não cria User/token e que após o tempo de espera a operação volta a ser admitida; confirmar que requisições dentro da cota preservam respostas existentes.
- [ ] 2.4 Confirmar IP real em ambiente com proxy confiável e verificar o Redis como store efetivo do limiter no Lerd, com contadores compartilhados sem mudar o cache geral; executar verificações focadas e Laravel Pint, revisar o diff e validar a mudança OpenSpec em modo strict.
