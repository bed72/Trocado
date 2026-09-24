## 1. Decisões e pré-requisitos

- [x] 1.1 Confirmar a cota inicial de 60/min por User e excluir SignOut da cota; ajustar proposta, spec e design antes do apply.
- [x] 1.2 Conferir a mudança `limit-public-authentication-attempts`: Redis configurado para o limiter, cache geral independente e pendência operacional 2.4 tratada separadamente, sem marcar trabalho não verificado como concluído.

## 2. Política HTTP compartilhada

- [x] 2.1 Registrar o limitador autenticado em Core Infrastructure, usando o identificador do User como chave comum entre tokens, IPs e contextos e distinta das cotas públicas.
- [x] 2.2 Aplicar a mesma política às rotas protegidas atuais de User e Expense, preservando SignOut apenas com `auth:sanctum` e sem alterar SignIn e SignUp.
- [x] 2.3 Verificar a ordem real dos middlewares no Laravel 13 e, se necessário, ajustar a prioridade para `auth:sanctum` executar antes do throttle autenticado.

## 3. Verificação

- [x] 3.1 Exercitar por HTTP 60 requisições admitidas entre os dois contextos e a 61ª bloqueada, com tokens e IPs alternados do mesmo User, outro User independente e falhas após autenticação consumindo cota.
- [x] 3.2 Exercitar por HTTP `401` sem token/token inválido sem consumo de cota, SignOut revogando token válido após esgotamento, limites públicos intactos, `429` JSON:API com `Retry-After` sem efeitos colaterais e reabertura após a janela.
- [x] 3.3 Confirmar o store Redis efetivo, contagem compartilhada entre processos e ausência de fallback local; executar verificações focadas, arquitetura, Pint, revisão de diff e validação OpenSpec strict.
