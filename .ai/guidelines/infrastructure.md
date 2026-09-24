# Infrastructure

- Use Laravel e Eloquent diretamente quando forem idiomáticos: Query Builder, Cache, Queue, Filesystem, HTTP Client, facades, SDKs e migrations são permitidos.
- Implemente contratos da Application sem expor Model, Builder ou query do ORM neles.
- Organize Repositories de persistência em `Infrastructure/Repositories/Persistence/` e seus Models em `Infrastructure/Repositories/Persistence/Models/`, como em Identity e Expense.
- Registre bindings de fronteira em Service Providers; não registre classes concretas resolvidas automaticamente.
- Implemente Ports em classes com sufixo `Adapter`; o Adapter executa transações e locks, mas o UseCase define o escopo atômico.
- Callbacks transacionais devem evitar efeitos externos não transacionais, pois uma tentativa pode ser repetida pelo banco.
- Coloque Commands Laravel em `Infrastructure/Console/Commands`; mantenha-os finos, resolvendo config, relógio e I/O antes de chamar um UseCase com valores explícitos.
- Deixe mapping simples no Repository; só extraia Mapper com complexidade real. Não crie wrappers de uma única chamada nem DI externo.
