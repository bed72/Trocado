## Context

`SignInAdapter` emite Personal Access Tokens Sanctum com `expires_at` calculado a partir de `sanctum.expiration` (120 minutos). `auth:sanctum` verifica tanto o limite global contado desde `created_at` quanto `expires_at`; o primeiro impediria qualquer extensão apenas do segundo. As rotas protegidas de Identity e Expense já usam o guard e as verificações de conta ativa e e-mail confirmado. `SignOut` revoga só o token atual. O comando `sanctum:prune-expired --hours=24` roda diariamente.

A spec principal de `authentication` hoje exige prazo fixo e proíbe renovação a cada requisição: esta mudança substitui expressamente esse contrato. O objetivo é acomodar acesso semanal ou quinzenal sem proliferar tokens; a alteração permanece sob ownership de Identity, mesmo quando a atividade ocorrer em Expense.

## Goals / Non-Goals

**Goals:**

- Reutilizar o mesmo Bearer e o mesmo registro Sanctum durante a sessão; conceder janelas de 30 dias a partir da emissão e de cada extensão efetiva, atendendo ao padrão semanal ou quinzenal de uso.
- Limitar a sessão a 90 dias desde `created_at`, independentemente da atividade.
- Prorrogar apenas quando `expires_at` estiver a 15 dias ou menos, sem encurtar a validade existente e sem escrita adicional em todos os requests.
- Garantir que tokens expirados, revogados e contas não aptas não recuperem validade.

**Non-Goals:**

- Refresh token, token paralelo, JWT, cookies, sessão stateful, biometria ou rota dedicada de renovação.
- Impor token único por usuário, limitar dispositivos, excluir outros logins válidos ou modificar as regras de SignIn rate limiting.
- Persistir atividade numa nova tabela, registrar segredo em logs ou retornar novamente o token puro.

## Decisions

### 1. Apenas `expires_at` controlará a expiração após a emissão

Remover o limite global ativo `sanctum.expiration` (usar `null`), conservando `expires_at` obrigatório nos tokens emitidos por SignIn. Inicializar `expires_at = min(now + 30 dias, created_at + 90 dias)`; o momento de criação do token é o marco do limite absoluto. Na renovação, calcular `min(now + 30 dias, created_at + 90 dias)`. O campo `created_at` nunca será atualizado para simular novo login. O guard Sanctum continuará recusando tokens vencidos pelo `expires_at`; a rotina oficial de pruning continuará excluindo-os depois de 24 horas, mesmo sem `sanctum.expiration` global.

Alternativas rejeitadas: estender somente `expires_at` mantendo `sanctum.expiration=120` (o guard recusaria o token após duas horas); mover `created_at` (apagaria a origem do limite absoluto); definir `expires_at` nulo (retiraria a expiração efetiva).

### 2. Atividade válida estende o token atual sem mudar seu segredo

Nas rotas protegidas de User e Expense, após `auth:sanctum`, `user.active`, `verified` e o restante dos controles existentes, atividade elegível significa resposta HTTP bem-sucedida (`2xx`) de uma requisição autenticada. Se o token ainda estiver válido e sua expiração estiver a 15 dias ou menos, prolongar a validade, no máximo até o 90º dia. Não tentar prorrogar SignIn, rotas públicas ou SignOut; resultados `401`, `403`, `404`, `422`, `429` e `5xx` não contam como atividade elegível. O login inicial permanece o único momento de entrega do segredo; a resposta de SignIn mostra apenas o prazo inicial, que poderá mudar no servidor. O cliente não deve tratar aquele `expires_at` original como limite imutável: um `401` exige novo SignIn.

Um middleware de Identity na Presentation cobre os grupos protegidos sem replicar regra em cada Controller e delega a decisão à Application; um Port/Adapter de Identity implementa a integração com `currentAccessToken()` e a escrita condicional no registro Sanctum. Laravel, Auth, Eloquent e o Model do token ficam fora da Application. Não adicionar Repository/Entity de token por antecipação.

O limite de 30 dias é contado da última extensão efetiva, não necessariamente da última requisição. Por exemplo, acesso no 1º dia após o SignIn não atualiza o prazo ainda distante: sem novo acesso, a sessão ainda vence no 30º dia após o login (29 dias após aquele acesso). Esse compromisso evita escrever `expires_at` em toda chamada e mantém as visitas semanais/quinzenais cobertas.

Alternativas rejeitadas: criar um token novo em toda atividade (acúmulo, rotação desnecessária), atualizar em cada request (escrita excessiva), renovar antes de autorização ou em respostas de falha (manter sessões de contas bloqueadas ou chamadas rejeitadas).

### 3. Limites e concorrência são conferidos na escrita

A operação de extensão compara estado atual no banco, não apenas o Model carregado no início da requisição: registro ainda existente, prazo maior que o instante da escrita, criação dentro dos 90 dias e prazo dentro da janela de 15 dias. A nova validade é monotônica (`max(expires_at atual, min(now + 30 dias, created_at + 90 dias))`) e nunca excede `created_at + 90 dias`. Usar atualização condicional atômica (ou transação com lock e revalidação) para que requests paralelos não encurtem a sessão, nem a escrita recrie um token apagado por logout ou pruning. Se outro request já estendeu, este não precisa atualizar. Se o token vencer entre a autenticação e a escrita, ele não é reativado. Nenhum efeito externo deve ocorrer dentro de eventual callback transacional com retry.

Esta regra não substitui as checagens de autorização de User/Expense: o middleware apenas mantém a validade da credencial depois de uma requisição efetivamente bem-sucedida. O término da sessão não depende de a limpeza física dos registros já ter ocorrido.

### 4. Compatibilidade operacional e cliente

Não há migration: `personal_access_tokens` já tem `created_at`, `expires_at` indexado e `last_used_at`. Tokens anteriores ainda válidos, emitidos com prazo de duas horas, poderão entrar na nova política quando fizerem uma requisição elegível; tokens já vencidos permanecem recusados. O antigo `expires_at` explícito desses tokens evita torná-los eternos ao desligar o limite global. O cliente preserva o Bearer em armazenamento apropriado e não recebe token novo ao prolongar a sessão; para uma UI que mostra expiração, a data inicial de SignIn não deve ser tomada como estado atual após atividade.

## Risks / Trade-offs

- [Um Bearer comprometido pode continuar válido por mais tempo] → expiração por inatividade, teto absoluto de 90 dias, transporte seguro, armazenamento seguro do cliente e revogação seletiva no logout; não prometer proteção biométrica no servidor.
- [Configuração global desligada pode afetar tokens emitidos fora de SignIn sem `expires_at`] → inspecionar outros emissores e assegurar que toda emissão para a API define `expires_at`; não gerar token sem prazo nesta mudança.
- [Renovação após resposta bem-sucedida falha no banco] → não devolver validade fictícia nem ignorar a falha silenciosamente; a implementação deve preservar erro coerente e não alterar o token se a operação falhar.
- [Alteração de contrato para consumidores que usam `expires_at` do login para logout local] → documentar que é um snapshot inicial e que `401` do servidor determina perda da sessão.
- [Rollback da configuração] → voltar ao limite fixo faz tokens com mais de 120 minutos desde a criação deixarem de funcionar imediatamente; planejar rollback com esse efeito explícito, sem restaurar validade por backfill.

## Migration Plan

1. Ajustar a spec de `authentication` antes de implementar: revogar a regra de expiração fixa e documentar janelas, teto, elegibilidade e concorrência.
2. Mudar a configuração global do Sanctum e a emissão do SignIn de forma coordenada com o mecanismo de extensão; não publicar a configuração sem `expires_at` em todos os tokens relevantes.
3. Instalar a integração de extensão nos grupos protegidos de Identity e Expense, deixando SignOut fora; preservar o pruning agendado.
4. Verificar os limites temporais, pedidos simultâneos, logout, contas bloqueadas/não verificadas, rate limiting e compatibilidade dos contratos JSON:API, além do comportamento da limpeza oficial.
5. Se for necessário reverter, restaurar configuração/fluxo antigo e informar que sessões com mais de duas horas de idade exigirão novo login.

## Open Questions

Nenhuma bloqueante. A política inicial acordada é 30 dias sem atividade, janela de extensão nos últimos 15 dias e teto de 90 dias desde SignIn; suporte a múltiplos dispositivos permanece independente.
