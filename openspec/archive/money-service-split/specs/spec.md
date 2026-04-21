# Spec: money-service-split

## Context

`MoneyService` hoje vive em `lib/src/domain/services/money_service.dart` e importa `package:intl/intl.dart`. Isso **viola a regra "`domain/` com zero pacote externo"** declarada no `CLAUDE.md` (seção Arquitetura / camada `domain/`).

A solução de simplesmente mover o arquivo inteiro para `infrastructure/services/` **não funciona** porque 17+ consumidores na camada `presentation/` dependem da abstração, e a regra de dependência declara explicitamente que `presentation/` nunca conhece `infrastructure/`.

A solução correta (Clean Architecture padrão): **separar interface e implementação**. A interface `IMoneyService`, sendo Dart puro, permanece em `domain/`. A implementação `MoneyService`, que depende de pacote externo, move para `infrastructure/services/`. O provider em `main/` faz o wiring — é a única camada que conhece ambos os lados.

## Scope

**Dentro do escopo:**
- Reestruturação do arquivo `lib/src/domain/services/money_service.dart` — remover impl e import de `intl`, manter só a interface.
- Criação de `lib/src/infrastructure/services/money_service.dart` com a classe `MoneyService` e o import de `intl`.
- Atualização de `lib/src/main/providers/services_provider.dart` para importar a impl de `infrastructure/`.

**Fora do escopo:**
- Qualquer alteração na interface `IMoneyService` — mesmos três métodos, mesmas assinaturas.
- Qualquer alteração nos 17+ consumidores — todos continuam importando `IMoneyService` de `domain/services/money_service.dart` (mesmo caminho).
- Introdução de outros services ou novos métodos de formatação/parsing.

---

## Requirements

### Requirement: Interface `IMoneyService` pura em `domain/`

The system SHALL keep o arquivo `lib/src/domain/services/money_service.dart` contendo **apenas** a interface:

```dart
abstract interface class IMoneyService {
  double parse(String value);
  String format(double value);
  String formatWithoutSymbol(double value);
}
```

The system SHALL remove a classe `MoneyService` e o `import 'package:intl/intl.dart';` desse arquivo.

#### Scenario: Domain sem pacote externo
Given a refatoração concluída
When `grep -rn "package:intl" lib/src/domain/` é executado
Then zero resultados

#### Scenario: Interface intocada
Given `lib/src/domain/services/money_service.dart` após a refatoração
When as três assinaturas de método são comparadas com o estado anterior
Then são idênticas: `parse`, `format`, `formatWithoutSymbol`

---

### Requirement: Implementação `MoneyService` em `infrastructure/`

The system SHALL create o arquivo `lib/src/infrastructure/services/money_service.dart` com a classe `MoneyService`:

```dart
import 'package:intl/intl.dart';

import 'package:trocado/src/domain/services/money_service.dart';

final class MoneyService implements IMoneyService {
  final NumberFormat _formatter;

  MoneyService()
    : _formatter = NumberFormat.currency(
        symbol: 'R\$',
        locale: 'pt_BR',
        decimalDigits: 2,
      );

  @override
  String format(double value) => _formatter.format(value);

  @override
  String formatWithoutSymbol(double value) =>
      format(value).replaceAll('R\$', '').trim();

  @override
  double parse(String value) {
    final normalized = value
        .replaceAll('R\$', '')
        .replaceAll('.', '')
        .replaceAll(',', '.')
        .trim();

    return double.tryParse(normalized) ?? 0.0;
  }
}
```

The system SHALL preserve o comportamento da impl atual — mesma formatação `pt_BR`, mesmas regras de parsing, mesmos métodos.

#### Scenario: Comportamento idêntico
Given a nova impl em `infrastructure/services/money_service.dart`
When os três métodos são chamados com os mesmos inputs dos testes existentes
Then os outputs são idênticos aos da impl anterior

---

### Requirement: Provider faz o wiring

The system SHALL update `lib/src/main/providers/services_provider.dart` para importar a interface de `domain/` e a impl de `infrastructure/`:

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:trocado/src/domain/services/money_service.dart';
import 'package:trocado/src/infrastructure/services/money_service.dart';

part 'services_provider.g.dart';

@Riverpod(keepAlive: true)
IMoneyService moneyService(Ref _) => MoneyService();
```

The system SHALL keep a assinatura do provider `moneyService` inalterada — mesma identidade, mesmo `keepAlive: true`, mesma nomenclatura gerada em `services_provider.g.dart`.

#### Scenario: Provider gerado sem mudança de nome
Given `dart run build_runner build --delete-conflicting-outputs` executado
When `services_provider.g.dart` é inspecionado
Then o nome do provider gerado é o mesmo de antes (`moneyServiceProvider`)

---

### Requirement: Consumidores não mudam

The system SHALL NOT modify nenhum consumidor de `IMoneyService` em `lib/src/presentation/`. Todos os 17+ imports continuam apontando para `package:trocado/src/domain/services/money_service.dart` — o caminho da interface não muda.

The system SHALL NOT introduzir import de `infrastructure/services/` em nenhum arquivo fora de `main/providers/`.

#### Scenario: Presentation não importa infrastructure
Given a refatoração concluída
When `grep -rn "infrastructure/services" lib/src/presentation/` é executado
Then zero resultados

#### Scenario: Imports de presentation inalterados
Given `git diff lib/src/presentation/` após a refatoração
When as linhas de `import` são inspecionadas
Then nenhuma linha de `import 'package:trocado/src/domain/services/money_service.dart';` é adicionada ou removida

---

### Requirement: Testes passam e app renderiza valores

The system SHALL keep qualquer teste existente de `MoneyService` passando — se o teste importa `MoneyService` concreto, o import é atualizado para `infrastructure/services/money_service.dart`; se importa apenas `IMoneyService` (via mock), nada muda.

#### Scenario: Suite passa
Given a refatoração concluída
When `flutter analyze && flutter test` é executado
Then zero erros de análise e zero falhas

#### Scenario: Runtime — formatação `pt_BR` preservada
Given o app rodando após a refatoração
When uma tela que exibe valores monetários é aberta (ex: home com budget, tela de despesas)
Then os valores são renderizados em formato `pt_BR` (ex: `R$ 1.234,56`), idênticos ao estado anterior

---

## Files

### Create

- `lib/src/infrastructure/services/money_service.dart` — classe `MoneyService` com import de `intl`

### Modify

| Arquivo | Mudança |
|---|---|
| `lib/src/domain/services/money_service.dart` | Remover classe `MoneyService` e import de `intl`; manter só a interface |
| `lib/src/main/providers/services_provider.dart` | + import de `infrastructure/services/money_service.dart` |
| `test/src/domain/services/money_service_test.dart` *(se existir)* | Atualizar import para `infrastructure/services/money_service.dart` |

### Unchanged

- Todos os 17+ consumidores em `lib/src/presentation/` — imports preservados
- `CalculatorNotifier` — importa `IMoneyService` pelo caminho de domain; nenhuma mudança
- Pasta `lib/src/application/` — não é recriada (não existe hoje e permanece ausente)

---

## Out of scope

- Criação/renomeação da camada `application/`.
- Introdução de novos métodos em `IMoneyService`.
- Substituição de `intl` por outro package.
- Mudança da moeda padrão (`R$`) ou locale (`pt_BR`).
- Migração de `double` para um tipo de dinheiro dedicado (`Money`, `Decimal`, etc.) — separado, fora desta spec.
