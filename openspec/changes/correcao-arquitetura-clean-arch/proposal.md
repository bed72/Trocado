# Proposal: correcao-arquitetura-clean-arch

## Intent

Corrigir as violações de Clean Architecture e SOLID existentes no projeto Flutter Trocado,
alinhando a estrutura ao padrão documentado no app nativo Kotlin
(`Trocado/Native/02 - Architecture.md` no Obsidian).

## Problem

O projeto acumulou diversas violações desde a remoção do ObjectBox:

| Violação | Impacto |
|---|---|
| `ILoggerDataSource` em `data/datasources/` | `infrastructure/` importa de `data/` — dependência circular invertida |
| Nenhuma implementação concreta de repositório | BLoCs recebem `sl()` para repositório mas nada está registrado — app quebrado em runtime |
| Nenhuma interface de datasource para expense/budget | Impossível implementar offline-first ou remote no futuro |
| Erros como `Either<String, T>` | Sem tipagem — não é possível tratar erros por categoria |
| Entities removidas junto com ObjectBox | Data layer sem tipos de infraestrutura |

## Scope

**Incluído:**
- `domain/` — adicionar `errors/failure.dart` com `sealed class Failure`
- `domain/repositories/` — atualizar assinaturas para `Either<Failure, T>`
- `infrastructure/` — criar entities, interfaces de datasource, stubs locais
- `data/` — criar mappers e implementações de repositório
- `main/injection.dart` — registrar novos datasources e repositórios no GetIt
- `test/` — atualizar mocks e testes para `Failure`

**Excluído:**
- `presentation/` — BLoCs e screens não serão tocados neste ciclo
- Implementação de remote datasources (HTTP) — aguarda migração Riverpod
- Implementação de offline-first (local DB) — stubs suficientes por ora
- Migração GetIt → Riverpod — ciclo separado

## Motivation

O app está com a camada de dados completamente ausente após a remoção do ObjectBox.
Qualquer tentativa de usar os BLoCs existentes resulta em crash em runtime porque
`sl<IExpenseRepository>()` e `sl<IBudgetRepository>()` não têm registro no GetIt.

Este change estabelece a fundação arquitetural correta — com todas as interfaces,
stubs e registros de DI — para que o próximo ciclo (implementação real dos datasources)
possa ser feito de forma guiada, camada por camada.

## Reference

- Arquitetura nativa Kotlin: `Trocado/Native/02 - Architecture.md` (Obsidian)
- Spec técnico detalhado: `docs/architecture-spec.md`
- Contrato da API: `openapi.json`
