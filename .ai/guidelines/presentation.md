# Presentation

- Use Laravel para Controllers, Form Requests, Resources e middleware.
- Prefira `HTTP → Form Request → Controller → UseCase → JsonApiResource → HTTP`.
- Controllers devem ser finos: sem consultas a Eloquent/Models, persistência ou regra de negócio.
- Form Request valida entrada HTTP; mantenha invariantes no Domain para outros chamadores.
- Facades são permitidas quando idiomáticas; prefira injeção para dependências relevantes.
