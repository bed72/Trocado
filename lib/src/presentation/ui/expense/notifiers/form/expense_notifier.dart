import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:trocado/src/main/providers/services_provider.dart';
import 'package:trocado/src/main/providers/validators_provider.dart';
import 'package:trocado/src/main/providers/repositories_provider.dart';

import 'package:trocado/src/domain/services/date_formatter_service.dart';
import 'package:trocado/src/domain/repositories/interface_expense_repository.dart';

import 'package:trocado/src/presentation/ui/home/notifiers/active_budget_notifier.dart';
import 'package:trocado/src/presentation/ui/home/notifiers/recent_expenses_notifier.dart';

import 'package:trocado/src/presentation/ui/expenses/notifiers/expenses_notifier.dart';
import 'package:trocado/src/presentation/ui/expense/notifiers/form/expense_state.dart';
import 'package:trocado/src/presentation/ui/expense/notifiers/form/expense_intent.dart';
import 'package:trocado/src/presentation/ui/expense/notifiers/expense_by_id_notifier.dart';
import 'package:trocado/src/presentation/ui/expense/validators/expense_form_validator.dart';

part 'expense_notifier.g.dart';

@Riverpod()
final class ExpenseNotifier extends _$ExpenseNotifier {
  late DateTime Function() _now;
  late IExpenseRepository _repository;
  late ExpenseFormValidator _validator;
  late IDateFormatterService _dateFormatter;

  @override
  Future<ExpenseState> build(int? id) async {
    _now = ref.watch(nowProvider);
    _repository = ref.watch(expenseRepositoryProvider);
    _validator = ref.watch(expenseFormValidatorProvider);
    _dateFormatter = ref.watch(dateFormatterServiceProvider);

    if (id == null) {
      final millis = _now().millisecondsSinceEpoch;
      return ExpenseState(
        date: millis,
        formattedDate: _dateFormatter.formatShortDate(millis),
      );
    }

    final expense = await ref.watch(expenseByIdProvider(id).future);

    return ExpenseState(
      id: expense.id,
      date: expense.date,
      value: expense.value,
      description: expense.description,
      formattedDate: _dateFormatter.formatShortDate(expense.date),
    );
  }

  void dispatch(ExpenseIntent intent) => switch (intent) {
    ValueChanged(:final value) => _mutate(
      state.value!.copyWith(value: value, clearValueFailure: true),
    ),
    DescriptionChanged(:final value) => _mutate(
      state.value!.copyWith(description: value, clearDescriptionFailure: true),
    ),
    DateChanged(:final date) => _mutate(
      state.value!.copyWith(
        date: date,
        clearDateFailure: true,
        formattedDate: _dateFormatter.formatShortDate(date),
      ),
    ),
    SubmitPressed() => _submit(),
  };

  void _mutate(ExpenseState next) => state = AsyncData(next);

  Future<void> _submit() async {
    final current = state.value!;
    final validation = _validator(current);
    final validated = validation.state;

    _mutate(validated);

    if (!validation.isValid) return;

    _mutate(validated.copyWith(status: .loading));

    final data = current.id == null
        ? await _repository.create(
            date: validated.date!,
            value: validated.value,
            description: validated.description,
          )
        : await _repository.update(
            id: current.id!,
            date: validated.date!,
            value: validated.value,
            description: validated.description,
          );

    data.fold(
      (failure) => _mutate(
        state.value!.copyWith(status: .failure, message: failure.message),
      ),
      (_) {
        ref.invalidate(expensesProvider);
        ref.invalidate(activeBudgetProvider);
        ref.invalidate(recentExpensesProvider);
        _mutate(state.value!.copyWith(status: .success));
      },
    );
  }
}
