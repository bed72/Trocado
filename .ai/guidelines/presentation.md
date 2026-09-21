# Presentation

- Use Laravel para Controllers, Form Requests, Responses e middleware.
- Prefira `HTTP → Form Request → Controller → UseCase → Response → HTTP`.
- Controllers devem ser finos: sem consultas a Eloquent/Models, persistência ou regra de negócio.
- Form Request valida entrada HTTP; mantenha invariantes no Domain para outros chamadores.
- Facades são permitidas quando idiomáticas; prefira injeção para dependências relevantes.
