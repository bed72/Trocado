# Proposal: fix-splash-health-gate

## Intenção

Restaurar a verificação de saúde da API durante a inicialização do app para que o splash retorne `SplashStatus.maintenance` quando o backend estiver indisponível ou reportar estado não saudável.

## Motivação

Os testes de `SplashNotifier` esperam que a verificação de saúde aconteça antes da sessão. Atualmente esse bloco está comentado, então o notifier chama `checkSession()` sem mock nos cenários de manutenção e os testes falham.

## Escopo

- Descomentar o health gate em `SplashNotifier.build()`.
- Manter `noConnection` como retorno prioritário quando não houver conexão.
- Executar `checkSession()` somente quando a API estiver saudável.
- Preservar o registro de token e os demais estados existentes.
- Manter os testes existentes como cobertura do comportamento.

## Fora de escopo

- Alterar contratos de repositórios.
- Alterar a tela de splash ou a navegação.
- Alterar o tratamento de autenticação, conectividade ou registro de token.
