# Arquitetura

- Leia `ARCHITECTURE.md` antes de mudanças estruturais.
- Organize features em `app/<Contexto>/{Domain,Application,Infrastructure,Presentation}`; não crie contextos vazios.
- Respeite `Presentation → Application → Domain` e `Infrastructure → Application/Domain`.
- Domain puro, Application explícita, Infrastructure Laravel, Presentation Laravel.
- A convenção do projeto prevalece sobre orientações genéricas do Boost para pastas globais, acesso direto a Eloquent na Presentation e geração automática de factories, seeders ou testes.
- Use geradores Artisan quando úteis, colocando as classes geradas na camada e no contexto corretos.
- Para Laravel e packages Laravel instalados, consulte primeiro Laravel Boost/Search Docs antes de assumir APIs por memória; confira o código instalado quando necessário.
- Se houver conflito com a arquitetura, explique o trade-off e proponha a menor mudança antes de alterar as regras. Evite refactors amplos não solicitados.
