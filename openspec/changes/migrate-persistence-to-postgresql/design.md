## Context

O projeto usa SQLite na configuração de exemplo, na suíte (`:memory:`) e no ambiente local. O Lerd declara Redis e Mailpit, mas não PostgreSQL. Identity persiste `users` e tokens Sanctum; Expense persiste despesas com FK, exclusão lógica e índice para paginação por cursor. Os dados SQLite existentes são apenas de desenvolvimento, sem necessidade de cópia. O Laravel 13 já inclui a conexão `pgsql`; verificar no runtime o driver PDO PostgreSQL antes de configurar o serviço.

## Goals / Non-Goals

**Goals:** PostgreSQL como banco padrão do desenvolvimento e da suíte de testes; migrations reproduzíveis desde banco vazio; preservar comportamentos e constraints de Identity e Expense; documentar bootstrap seguro.

**Non-Goals:** importar dados SQLite, modificar contratos HTTP, reescrever agregados, migrar Redis/cache, configurar produção ou aplicar RLS/policies SQL nesta etapa.

## Decisions

1. Usar o serviço PostgreSQL gerenciado pelo Lerd e sua configuração de ambiente, com driver `pgsql` do Laravel. No apply, usar `lerd db set` para provisionar banco da aplicação e banco `_testing`, depois configurar o ambiente pela ferramenta do Lerd e seguir os passos necessários de setup. Não commitar credenciais, nem fixar host/senha pessoal em `phpunit.xml`; `.env.example` e README explicam as variáveis necessárias. Alternativa descartada: manter SQLite como padrão e validar PostgreSQL apenas esporadicamente, pois esconderia regressões de dialeto até a próxima mudança.
2. Manter banco de teste PostgreSQL separado do banco de desenvolvimento e remover `sqlite`/`:memory:` do ambiente PHPUnit. `DB_URL` não pode apontar a suíte de volta para o banco de desenvolvimento. Antes de executar testes com operações que recriam schema, confirmar a conexão efetiva e que ela aponta ao banco `_testing`; nunca usar `migrate:fresh` no banco de desenvolvimento. Alternativa descartada: testar com SQLite apesar do runtime PostgreSQL, que não exercita constraints e semântica reais.
3. Aplicar as migrations já versionadas desde um PostgreSQL vazio, alterando somente o necessário para compatibilidade real. Verificar especialmente `users.password` (`change()`), FKs e cascata de exclusão, índice composto de Expense, índice único de e-mail/token, datas e `QueryException` traduzida por Repository. Nenhuma migration de conversão ou SQL de transferência de dados é necessária. Manter `Domain` e `Application` independentes do banco. Alternativa descartada: criar schema SQL paralelo não reproduzível pelas migrations Laravel.
4. Não introduzir RLS nesta mudança: as queries existentes continuam responsáveis pelo isolamento de conta. A próxima spec poderá definir roles PostgreSQL, políticas, escopo transacional do principal e cobertura para impedir bypass; não antecipar SQL de política sem esse desenho.

## Risks / Trade-offs

- [Teste acidental sobre banco de desenvolvimento] → Exigir conexão de testes distinta e verificar antes da suíte; evitar comandos destrutivos no banco compartilhado.
- [Diferenças de dialeto] → Executar migrations do zero e suíte de integração sobre PostgreSQL real; ajustar só os pontos comprovadamente incompatíveis.
- [Driver ou serviço PostgreSQL indisponível] → Tratar como erro explícito de bootstrap; não cair silenciosamente para SQLite.
- [Dados locais ausentes no novo banco] → Aceito: não há usuários reais; não copiar credenciais ou tokens de desenvolvimento.

## Migration Plan

No apply: confirmar driver e serviço; provisionar PostgreSQL e bancos isolados pelo Lerd; atualizar configuração de exemplo e PHPUnit; executar migrations no novo banco e testar fluxos críticos e suíte; atualizar README. Não apagar o arquivo SQLite antigo como parte da mudança. Se necessário reverter, reconfigurar explicitamente a conexão anterior; isto não transporta dados escritos em PostgreSQL de volta para SQLite.

## Open Questions

Nenhuma questão funcional bloqueante: dados locais não serão importados e RLS fica para mudança própria. Confirmar os nomes/variáveis efetivos fornecidos pelo Lerd durante o apply, antes de fixar valores no ambiente de testes.
