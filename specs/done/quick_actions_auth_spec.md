# Spec: Quick Actions condicionais por autenticação

## Resumo

Transformar a função livre `quickAction()` num serviço com interface no domain, mover o registro para a `HomeScreen` (executado uma única vez), e limpar os atalhos no logout via `SettingsNotifier`.

---

## Problema atual

1. `quickAction()` é chamada como side-effect no `HomeLocation.builder` — Location não deve ter side-effects
2. Sem guarda de autenticação (embora Home só seja acessado pós-auth, os atalhos persistem no OS)
3. Após logout, atalhos permanecem registrados no OS

---

## Domain

### Interface `IQuickActionService`

**Path:** `lib/src/domain/services/quick_action_service.dart`

```dart
abstract interface class IQuickActionService {
  void register({required void Function(String type) action});
  void clear();
}
```

- `register` — inicializa o handler e registra os atalhos no OS
- `clear` — remove todos os atalhos do OS
- Interface pura, sem imports de Flutter ou pacotes externos

---

## Infrastructure

### Implementação `QuickActionService`

**Path:** `lib/src/infrastructure/services/quick_action_service.dart`

```dart
final class QuickActionService implements IQuickActionService {
  @override
  void register({required void Function(String type) action}) {
    QuickActions()
      ..initialize(action)
      ..setShortcutItems(_items);
  }

  @override
  void clear() {
    QuickActions().setShortcutItems([]);
  }
}
```

Move a lista `_items` e o enum `QuickActionsConstant` para dentro deste arquivo — são detalhes de plataforma (nomes de ícones, títulos localizados) que pertencem à infraestrutura.

---

## Main

### Provider (adicionar em `services_provider.dart`)

```dart
@Riverpod(keepAlive: true)
IQuickActionService quickActionService(Ref _) => QuickActionService();
```

`keepAlive: true` — mesma instância durante todo o ciclo do app, consistente com os outros services.

---

## Presentation

### HomeLocation (remover side-effect)

**Antes:**
```dart
quickAction(
  action: (type) {
    context.navigate(
      type == QuickActionsConstant.budget.name
          ? BudgetLocation()
          : ExpenseLocation(),
    );
  },
);
```

**Depois:** remover bloco inteiro + import de `quick_action.dart`.

### HomeScreen (registrar quick actions uma vez)

A `HomeScreen` já é `StatefulWidget` com `_HomeScreenState`. Adicionar flag `_quickActionsRegistered` para garantir execução única no primeiro build do Consumer:

```dart
class _HomeScreenState extends State<HomeScreen>
    with BackButtonMixin<HomeScreen> {
  bool _quickActionsRegistered = false;

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (_, ref, _) {
        if (!_quickActionsRegistered) {
          _quickActionsRegistered = true;
          ref.read(quickActionServiceProvider).register(
            action: (type) {
              if (type == QuickActionsConstant.budget.name) {
                widget.navigateToBudget();
              } else {
                widget.navigateToCreateExpense();
              }
            },
          );
        }
        // ... resto do build
      },
    );
  }
}
```

**Nota:** a regra "screens não leem service providers" se aplica a serviços de formatação/dados que produzem view-models (ex: `moneyServiceProvider`). Quick action registration é um side-effect de plataforma one-shot, não produção de dados para a UI — exceção intencional e narrada.

### SettingsNotifier (limpar no logout)

Injetar `IQuickActionService` e chamar `clear()` no branch de sucesso do logout:

```dart
@Riverpod()
final class SettingsNotifier extends _$SettingsNotifier {
  late IAuthenticationRepository _repository;
  late IQuickActionService _quickActionService;

  @override
  SettingsState build() {
    _repository = ref.watch(authenticationRepositoryProvider);
    _quickActionService = ref.watch(quickActionServiceProvider);
    return const SettingsState();
  }

  Future<void> _logout() async {
    if (state.status == .loading) return;
    state = state.copyWith(status: .loading);

    final data = await _repository.logout();

    data.fold(
      (failure) =>
          state = state.copyWith(status: .failure, message: failure.message),
      (_) {
        _quickActionService.clear();
        state = state.copyWith(status: .success);
      },
    );
  }
}
```

### Deletar arquivo antigo

Remover `lib/src/presentation/actions/quick_action.dart` — todo o conteúdo migrou para o service.

---

## Árvore de mudanças

```
lib/src/
├── domain/services/
│   └── quick_action_service.dart              (novo — interface)
├── infrastructure/services/
│   └── quick_action_service.dart              (novo — implementação + QuickActionsConstant)
├── main/providers/
│   └── services_provider.dart                 (edit — + quickActionServiceProvider)
├── presentation/
│   ├── actions/
│   │   └── quick_action.dart                  (deletar)
│   ├── ui/home/
│   │   ├── locations/home_location.dart        (edit — remover quickAction call)
│   │   └── screens/home_screen.dart            (edit — registrar via service)
│   └── ui/settings/
│       └── notifiers/settings_notifier.dart    (edit — clear no logout)
```

---

## Fora de escopo

- Testes (não há testes de services puros no projeto atualmente)
- Modificar o pacote `quick_actions`
- Registrar/limpar quick actions em outros fluxos além de Home/Logout
