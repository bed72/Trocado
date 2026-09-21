# Domain

- Mantenha Domain em PHP puro: Entities, Value Objects, Domain Services, exceções e invariantes.
- Proíba dependências de Laravel, Illuminate, Eloquent, facades, HTTP, container, banco, migrations, Infrastructure e Presentation.
- Domain não conhece persistência nem serialização. Proteja invariantes também fora do Form Request.
- Crie Value Objects só para conceitos reais; prefira imutabilidade e não crie interfaces para Entities ou Value Objects.
- Mantenha carriers sem comportamento em `Application/Data`; dados com invariantes, igualdade semântica ou operações próprias do conceito pertencem ou devem ser reavaliados como Value Objects de Domain.
