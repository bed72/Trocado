## 1. Confirmar integrações antes de implementar

- [x] 1.1 Após autorização de apply, carregar `trocado-architecture`, confirmar versões e consultar Boost/Search Docs sobre broker, hasher, notifications, cifragem da fila, limiter e validação JSON:API; se indisponível, registrar limitação e confirmar pelo código instalado. Verificar compatibilidade das primitivas com fronteira temporal inclusiva e transação única (requirements de token, atomicidade e observabilidade).
- [x] 1.2 Descobrir site Lerd e ler suas instruções antes de operar o ambiente; consultar schema/conexão PostgreSQL e configuração de fila/limiter por MCP disponível, sem inferir tabela pela configuração e sem migrations destrutivas (design, decisões 3 e 8).
- [x] 1.3 Confirmar no código as seções críticas de SignIn, extensão de sessão e exclusão de conta, registrando a coordenação mínima necessária para revogação/cleanup sem refactor amplo (requirements de elegibilidade e consumo atômico).

Evidência S01 (2026-10-21): descoberta autorizada pelo usuário; versões por Lerd `composer show --direct --format=json`, `composer show phpunit/phpunit --format=json` e `artisan about --only=environment --json`. Boost SearchDocs/DatabaseQuery acessíveis pelo comando instalado `boost:execute-tool`, executado via MCP Lerd; configuração efetiva por `config:show` e identidade das conexões por introspecção somente leitura. Decisões, referências de código e limitações registradas em DESIGN, seção «Descoberta S01». Nenhum teste de aplicação, migration, alteração PHP ou runtime nesta sessão; as provas funcionais continuam nas tarefas pendentes.

## 2. Configuração e persistência incremental

- [x] 2.1 Criar migration incremental reversível para `password_reset_tokens` com endereço canônico único, hash e data de emissão, sem editar migrations históricas; comprovar shape e unicidade em Feature PostgreSQL (requirement de token temporário).
- [x] 2.2 Configurar expiração de 30 minutos, intervalo de 60 segundos e URL de Identity alimentada por `PASSWORD_RESET_URL`; adicionar exemplo sem segredo em `.env.example`, rejeitar destino inválido/reservado e não usar Host/fallback de API (requirement de link configurável).
- [x] 2.3 Classificar a nova tabela em `TestDatabaseCleanup` e integrar sua remoção à exclusão da conta na unidade existente, provando que eventual recadastro do endereço não herda link anterior e que outras contas permanecem intactas (design, decisão 8).
- [x] 2.4 Aplicar migrations pendentes no ambiente Lerd identificado somente na fase autorizada de implementação e antes de testar fluxos dependentes; registrar execução sem `migrate:fresh` (pré-requisito operacional).

Evidência operacional S02 (2026-10-21): alvo principal `trocado` confirmado por `site list` e SELECT `current_database()`; `password_reset_tokens` ausente e nenhuma migration preexistente pendente por `migrate:status`. MCP Lerd `exec action=artisan`, args `['migrate', '--no-interaction']` aplicou somente `2026_10_21_170047_create_password_reset_tokens_table` (15.57ms, DONE), antes dos fluxos de teste. Sem recriação/drop ou alteração de `.env`; bancos de teste permanecem sob ownership/preflight do launcher.

Evidência focada S02: quatro invocações isoladas via MCP Lerd `composer test -- <arquivo> --compact --fail-on-skipped --fail-on-incomplete --fail-on-risky`, todas aprovadas: `tests/Unit/Identity/Infrastructure/Adapters/PasswordRecoveryUrlAdapterTest.php` (24 testes/44 assertions); `tests/Feature/Identity/Infrastructure/Repositories/Persistence/PasswordRecoverySchemaTest.php` (3/19); `tests/Feature/Identity/Infrastructure/Repositories/Persistence/PasswordRecoveryAccountCleanupTest.php` (2/27); `tests/Feature/Core/Infrastructure/Isolation/PasswordRecoveryCleanupTest.php` (1/4). Provas: shape/PK/unicidade/hash nativo/conexão e defaults 30min/60s; reversão/reaplicação somente em banco de teste; URL absoluta confiável, HTTPS em produção, queries reservadas inclusive codificadas, fragmento/userinfo e ausência de fallback; ordem SQL conta bloqueada → recuperação → PATs → conta, isolamento do outro owner, recadastro sem herdar link, rollback real com exceção sentinela depois da exclusão e cleanup do launcher preservando migrations. Nenhuma dessas provas declara emissão/reset concorrentes ou contratos HTTP já implementados. Regressões e formatação da sessão são registradas abaixo ao executar.

Regressões/qualidade S02 após implementação (MCP Lerd, sem Pest direto):

| Comando (`composer test --` salvo Pint) | Resultado |
| --- | --- |
| `pint --dirty --format agent` por `vendor_run` | passed; sem alterações PHP preexistentes absorvidas |
| `tests/Feature/Identity --compact --fail-on-skipped --fail-on-incomplete --fail-on-risky` | 157 passed, 1.280 assertions, 6.914s |
| `tests/Unit/Identity --compact --fail-on-skipped --fail-on-incomplete --fail-on-risky` | 121 passed, 429 assertions, 0.077s |
| `tests/Unit/Architecture --compact --fail-on-skipped --fail-on-incomplete --fail-on-risky` | 30 passed, 502 assertions, 5.103s |
| `--compact --fail-on-skipped --fail-on-incomplete --fail-on-risky` | 2.470 passed, 39.959 assertions, 81.046s |
| `--order-by=random --random-order-seed=20261009 --compact --fail-on-skipped --fail-on-incomplete --fail-on-risky` | 2.470 passed, 39.959 assertions, 83.948s |
| `--order-by=random --random-order-seed=20261010 --compact --fail-on-skipped --fail-on-incomplete --fail-on-risky` | 2.470 passed, 39.959 assertions, 83.077s |
| `--parallel --processes=2 --compact --fail-on-skipped --fail-on-incomplete --fail-on-risky` | 2.470 passed, 39.959 assertions, 48.503s |

O gate completo incluiu Redis/concorrência e `SimultaneousInvocationsTest` (duas invocações paralelas com ownership), sem excluir grupos ou aceitar skips/incomplete/risky. Cada execução Feature usou banco exclusivo pelo preflight, sem mudanças nos guards. Pós-migration: Boost DatabaseQuery confirmou no banco operacional somente `email`, `token`, `created_at`, PK única de e-mail; `config:show auth.passwords.users` confirmou 30/60; `migrate:status` sem pendências. Não foi disparado DELETE HTTP contra conta operacional para perfilamento; regressão HTTP de encerramento foi exercitada no banco guardado. Nenhum segredo, e-mail ou job de recuperação foi emitido em runtime.

Saída documental S02: validação OpenSpec estrita aprovada sem issues; `openspec list --json` confirma 7/29 tarefas concluídas; `git diff --check` sem erros nos arquivos rastreados. Alterações preexistentes em composer.lock/SPEC.md preservadas; sem commit/archive. S03 não iniciada.

## 3. Application e Infrastructure de recuperação

- [ ] 3.1 Introduzir UseCases de solicitação/redefinição, `ResetPasswordInput`, contratos mínimos de Repository/Port e bindings; manter tipos puros, dados sensíveis transitórios e dependências Port → UseCase → Repository (requirement de ownership e fronteiras).
- [x] 3.2 Implementar solicitação com canonicalização, conta active/verificada sob lock, intervalo global por endereço e substituição atômica do hash, usando primitivas nativas compatíveis; testar Unit de orquestração e Feature de estado/supressão (requirements de solicitação, elegibilidade, token e limites).
- [ ] 3.3 Implementar validação e consumo sob lock na transação do UseCase, incluindo expiração em `now >= emissão + 30 minutos`, verificação de nova senha pelo VO/hasher e rejeição de senha atual sem efeitos; cobrir limites temporais, caracteres/bytes e repetição válida após rejeição (requirements de token, política e senha atual).
- [ ] 3.4 Atualizar hash, consumir recuperação e excluir todos os PATs somente do owner na mesma unidade; provar rollback real com falha sentinela após escrita e ausência de efeitos afterCommit na tentativa abortada (requirement de consumo atômico).
- [ ] 3.5 Coordenar somente as seções críticas necessárias de SignIn/renovação para não emitir PAT por validação antiga após revogação nem ressuscitar PAT removido; preservar contratos existentes e registrar evidência focada (design, decisão 4).

Evidência focada S03 (2026-10-21): `composer test -- tests/Unit/Identity/Application/UseCases/RequestPasswordRecoveryUseCaseTest.php --compact --fail-on-skipped --fail-on-incomplete --fail-on-risky` via MCP Lerd: **6 passed / 32 assertions**; `composer test -- tests/Feature/Identity/Infrastructure/Repositories/Persistence/EloquentPasswordRecoveryRepositoryTest.php --compact --fail-on-skipped --fail-on-incomplete --fail-on-risky`: **19 passed / 98 assertions**, PostgreSQL provisionado pelo launcher. Provas: canonicalização e unidade definida pelo UseCase; callback observado somente após commit; distinção inelegível/suprimida/emitida; matriz active/verificada, active/não verificada, pending/blocked com e sem verificação, ausente/removida/endereço diferente; estado relido a cada emissão; locks conta → recuperação; hash nativo sem mudar conta/PATs; instâncias internas distintas compartilham supressão aos 59s sem renovar hash/prazo, rotação aos 60s e link anterior rejeitado pelo componente nativo; rollback real restaura token anterior e descarta callback; falha SQL após delete sanitizada sem previous; rejeição de conexão divergente/escrita sem transação e indisponibilidade antes de lookup. Double de entrega somente em testes, sem notification ou transporte real.

Parcela de 3.1 entregue em S03: RequestPasswordRecoveryUseCase, PasswordRecoveryRepository/EloquentPasswordRecoveryRepository, PasswordRecoveryPort e PasswordRecoveryEmissionOutput; binding somente do Repository concreto. A Port de entrega não tem binding até adapter real em S04; não existe rota nem adapter no-op. **3.1 permanece aberta** até reset/input/contratos restantes em S05. 4.5/6.1 continuam abertas: emissão sequencial interna não comprova HTTP, Redis entre processos, consumo ou corridas S06. Formatação e regressões S03 serão registradas após execução.

Qualidade/regressões S03: descoberta de `vendor_bins`, depois `vendor_run pint --dirty --format agent` aprovado. Reexecução isolada pós-Pint: Unit 6/32 (0.034s) e Feature 19/98 (0.777s), sem falhas. Suítes por `composer test -- <caminho> --compact --fail-on-skipped --fail-on-incomplete --fail-on-risky`: Unit Identity **127 passed / 461 assertions** (0.080s), Feature Identity **176 / 1.378** (7.285s), Unit Architecture **30 / 513** (5.012s). Gate completo padrão `composer test -- --compact --fail-on-skipped --fail-on-incomplete --fail-on-risky`: **2.495 passed / 40.100 assertions** (81.910s), incluindo integrações existentes; sem skips/incomplete/risky. Nenhum suporte transversal ou migration alterado nesta sessão; gate ampliado anterior de S02 permanece histórico, não foi reatribuído ao código S03. Sem rota de recuperação para perfilamento HTTP; nenhum fluxo mutável foi executado contra conta operacional.

## 4. Contratos HTTP e proteção contra abuso

- [ ] 4.1 Implementar Requests/Controllers finos e rotas nomeadas forgot-password/reset-password com documentos fechados `password-recovery-requests`/`password-resets`, sem Bearer obrigatório, página ou redirect; conferir `202` com `meta.message` e `204` sem corpo/novo PAT (requirements de solicitação, redefinição e API-only).
- [ ] 4.2 Reutilizar a política de senha do cadastro, confirmação obrigatória e preservação exata de segredos; testar atributos desconhecidos, tipos inválidos, e-mail inválido, limites 6/32 caracteres e 72 bytes, maiúscula Unicode, dígito e confirmação divergente com pointers pertinentes (requirement de redefinição pública).
- [ ] 4.3 Mapear conta inexistente/inapta, token incorreto, expirado, substituído e consumido para o mesmo `422` JSON:API com detalhe aprovado e pointer `/data/attributes/token`; senha igual usa pointer de password sem consumir link (requirements de falhas e senha atual).
- [ ] 4.4 Registrar limiters Redis independentes de 6/10 minutos por IP por endpoint, antes da validação; provar sétimo request `429` com `Retry-After`, contagem de inválidos/sucessos, reabertura, isolamento entre endpoints/IPs/outros fluxos e ausência de fallback local (requirement de limites compartilhados).
- [ ] 4.5 Provar que solicitações equivalentes por caixa/espaços e por IPs distintos respeitam o mesmo intervalo global de 60 segundos, conservam `202` e não alteram link/prazo durante supressão; comprovar contador combinado entre processos Redis (requirement de limites compartilhados).

## 5. Notifications e proteção de credenciais

- [ ] 5.1 Implementar entrega assíncrona do link com URL configurada e query codificada, após commit da emissão; proteger payload sensível de fila e validar destinatário esperado no worker, sem transportar no request nem gerar token no worker (requirements de link, e-mails e observabilidade).
- [ ] 5.2 Implementar aviso assíncrono após commit da redefinição, sem senha/token, sem envio em rollback e sem rollback de senha/revogação por falha de enqueue ou transporte (requirement de e-mails assíncronos).
- [ ] 5.3 Testar job processado com conta removida/endereço divergente, link antigo após rotação/expiração, worker atrasado e falhas de enqueue/transporte; distinguir fake de enqueue de execução real do job e comprovar manutenção de `202`/`204` quando o envio falha (requirement de e-mails assíncronos).
- [ ] 5.4 Garantir redaction de senha, confirmação, hash, token e URL em exceptions públicas, logs, SQL, observabilidade e falhas de fila; provar por campos estruturados e inspecionar armazenamento hash-only da recuperação e proteção do payload (requirement de observabilidade).

## 6. Provas integradas e concorrentes

- [ ] 6.1 Cobrir a matriz de elegibilidade na emissão e consumo: active/verificada, active/não verificada, pending, blocked, ausente, removida e endereço divergente, incluindo mudança entre emissão e consumo; provar ausência de ativação/verificação implícita (requirements de elegibilidade e solicitação uniforme).
- [ ] 6.2 Provar com processos PostgreSQL sincronizados emissões simultâneas, consumos simultâneos do mesmo token e disputa emissão/consumo; usar conexões novas, sinais, timeout limitado e cleanup seguro, verificando um token corrente e no máximo um sucesso por token (requirements de rotação e consumo atômico).
- [ ] 6.3 Provar revogação com PATs reais de vários dispositivos, isolamento de outra conta, senha antiga rejeitada/nova aceita no SignIn posterior e ausência de login automático; incluir corrida restrita com SignIn/renovação, sem prometer cancelar requests já autenticados (requirement de consumo atômico).
- [ ] 6.4 Executar jornada API-only solicitar → link → redefinir → rejeitar reuso → novo login, sem formulário/redirect; verificar que nova emissão admitida invalida anterior e abertura do destino não consome token (requirements de link, token e contratos HTTP).

## 7. Verificação e registro de evidências

- [ ] 7.1 Executar arquivos afetados isoladamente e suítes focadas pelo launcher `lerd composer test -- ...`, com PostgreSQL/Redis/concorrência quando necessários e recursos exclusivos; registrar comandos, resultados e limitações por cenário, sem confundir skips ou fakes com prova real.
- [ ] 7.2 Após mudanças PHP, descobrir Pint pelo Lerd e executar `pint --dirty --format agent`; verificar fronteiras arquiteturais e regressões focadas dos contratos existentes de Authentication/Identity.
- [ ] 7.3 Atualizar apenas a documentação de uso existente pertinente à API/configuração quando implementar, com exemplos sem segredos e requisitos de URL/mailer/worker; não criar páginas web ou documentação que afirme implementação mobile.
- [ ] 7.4 Revisar rastreabilidade requisito → cenário → evidência, carregar `trocado-quality-gate` na fase de implementação antes de declarar conclusão e validar estritamente a mudança; preservar tarefas pendentes e registrar falhas, sem arquivar sem solicitação.

## 8. Histórico e estado da entrega

Preparação documental: foram criados proposta, design, delta spec e tarefas, sem implementação, migrations, testes da aplicação ou Pint. A aprovação de produto não substituiu autorização de apply.

S01 concluída: descoberta 1.1–1.3. S02 concluída: 2.1–2.4. A pedido do usuário, alterações pendentes até S02 (incluindo composer.lock e remoção preexistente de SPEC.md) foram commitadas em `ec64ae3`; STEPS.md permaneceu local/excluído. S03 autorizada e concluída: 3.2 e parcela de 3.1, com provas acima; **3.1 e demais tarefas compartilhadas continuam abertas** até suas sessões de fechamento. Nenhum reset, entrega real, HTTP ou limiter novo implementado. S04 aguarda aprovação do usuário; evidências intermediárias não concluem a mudança inteira nem autorizam archive/deploy.
