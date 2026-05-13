import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:trocado/src/main/providers/services_provider.dart';
import 'package:trocado/src/main/providers/validators_provider.dart';
import 'package:trocado/src/main/providers/repositories_provider.dart';

import 'package:trocado/src/domain/services/date_formatter_service.dart';
import 'package:trocado/src/domain/repositories/interface_budget_repository.dart';

import 'package:trocado/src/presentation/ui/home/notifiers/active_budget_notifier.dart';

import 'package:trocado/src/presentation/ui/budgets/notifiers/budgets_notifier.dart';
import 'package:trocado/src/presentation/ui/budget/notifiers/budget_by_id_notifier.dart';
import 'package:trocado/src/presentation/ui/budget/notifiers/form/budget_form_state.dart';
import 'package:trocado/src/presentation/ui/budget/validators/budget_form_validator.dart';
import 'package:trocado/src/presentation/ui/budget/notifiers/form/budget_form_intent.dart';

part 'budget_form_notifier.g.dart';

@riverpod
final class BudgetFormNotifier extends _$BudgetFormNotifier {
  late DateTime Function() _now;
  late IBudgetRepository _repository;
  late BudgetFormValidator _validator;
  late IDateFormatterService _dateFormatter;

  @override
  Future<BudgetFormState> build(int? id) async {
    _now = ref.watch(nowProvider);
    _repository = ref.watch(budgetRepositoryProvider);
    _validator = ref.watch(budgetFormValidatorProvider);
    _dateFormatter = ref.watch(dateFormatterServiceProvider);

    final descriptionHint =
        'Ex: Orçamento de ${_dateFormatter.formatMonth(_now())}';

    if (id == null) return BudgetFormState(descriptionHint: descriptionHint);

    final budget = await ref.watch(budgetByIdProvider(id).future);

    return BudgetFormState(
      id: budget.id,
      value: budget.value,
      endDate: budget.endDate,
      startDate: budget.startDate,
      description: budget.description,
      descriptionHint: descriptionHint,
      formattedPeriod: _dateFormatter.formatPeriod(
        budget.startDate,
        budget.endDate,
      ),
    );
  }

  void dispatch(BudgetFormIntent intent) => switch (intent) {
    ValueChanged(:final value) => _mutate(
      state.value!.copyWith(value: value, clearValueFailure: true),
    ),
    DateRangeChanged(:final startDate, :final endDate) => _mutate(
      state.value!.copyWith(
        endDate: endDate,
        startDate: startDate,
        clearDateFailure: true,
        formattedPeriod: _dateFormatter.formatPeriod(startDate, endDate),
      ),
    ),
    DescriptionChanged(:final value) => _mutate(
      state.value!.copyWith(description: value, clearDescriptionFailure: true),
    ),
    SubmitPressed() => _submit(),
  };

  void _mutate(BudgetFormState next) => state = AsyncData(next);

  Future<void> _submit() async {
    final current = state.value!;
    final validation = _validator(current);
    final validated = validation.state;

    _mutate(validated);

    if (!validation.isValid) return;

    _mutate(validated.copyWith(status: .loading));

    final data = current.id == null
        ? await _repository.create(
            value: validated.value,
            endDate: validated.endDate!,
            startDate: validated.startDate!,
            description: validated.description,
          )
        : await _repository.update(
            id: current.id!,
            value: validated.value,
            endDate: validated.endDate!,
            startDate: validated.startDate!,
            description: validated.description,
          );

    data.fold(
      (failure) => _mutate(
        state.value!.copyWith(status: .failure, message: failure.message),
      ),
      (_) {
        ref.invalidate(budgetsProvider);
        ref.invalidate(activeBudgetProvider);
        _mutate(state.value!.copyWith(status: .success));
      },
    );
  }
}
