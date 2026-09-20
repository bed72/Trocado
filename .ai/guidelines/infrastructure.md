# Infrastructure

- Use Laravel e Eloquent diretamente quando forem idiomáticos: Query Builder, Cache, Queue, Filesystem, HTTP Client, facades, SDKs e migrations são permitidos.
- Implemente contratos da Application sem expor Model, Builder ou query do ORM neles.
- Registre bindings de fronteira em Service Providers; não registre classes concretas resolvidas automaticamente.
- Deixe mapping simples no Repository; só extraia Mapper com complexidade real. Não crie wrappers de uma única chamada nem DI externo.
