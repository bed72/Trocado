import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:trocado/src/main/providers/validators_provider.dart';
import 'package:trocado/src/main/providers/repositories_provider.dart';

import 'package:trocado/src/domain/models/expense/expense_model.dart';
import 'package:trocado/src/domain/repositories/interface_expense_repository.dart';

import 'package:trocado/src/presentation/ui/home/notifiers/active_budget_notifier.dart';
import 'package:trocado/src/presentation/ui/home/notifiers/recent_expenses_notifier.dart';

import 'package:trocado/src/presentation/ui/expense/notifiers/expense_state.dart';
import 'package:trocado/src/presentation/ui/expense/notifiers/expense_intent.dart';
import 'package:trocado/src/presentation/ui/expenses/notifiers/expenses_notifier.dart';
import 'package:trocado/src/presentation/ui/expense/validators/expense_form_validator.dart';

part 'expense_notifier.g.dart';

@riverpod
final class ExpenseNotifier extends _$ExpenseNotifier {
  late IExpenseRepository _repository;
  late ExpenseFormValidator _validator;

  @override
  ExpenseState build(ExpenseModel? expense) {
    _repository = ref.watch(expenseRepositoryProvider);
    _validator = ref.watch(expenseFormValidatorProvider);

    return expense == null
        ? ExpenseState(date: DateTime.now().millisecondsSinceEpoch)
        : ExpenseState(
            id: expense.id,
            date: expense.date,
            value: expense.value,
            description: expense.description,
          );
  }

  void dispatch(ExpenseIntent intent) => switch (intent) {
    ValueChanged(:final value) => state = state.copyWith(
      value: value,
      clearValueFailure: true,
    ),
    DescriptionChanged(:final value) => state = state.copyWith(
      description: value,
      clearDescriptionFailure: true,
    ),
    DateChanged(:final date) => state = state.copyWith(
      date: date,
      clearDateFailure: true,
    ),
    SubmitPressed() => _submit(),
    DeletePressed() => _delete(),
  };

  Future<void> _submit() async {
    final (:state, :isValid) = _validator(this.state);
    this.state = state;

    if (!isValid) return;

    this.state = this.state.copyWith(status: .loading);

    final data = this.state.id == null
        ? await _repository.create(
            date: this.state.date!,
            value: this.state.value,
            description: this.state.description,
          )
        : await _repository.update(
            id: this.state.id!,
            date: this.state.date!,
            value: this.state.value,
            description: this.state.description,
          );

    data.fold(
      (failure) => this.state = this.state.copyWith(
        status: .failure,
        message: failure.message,
      ),
      (_) {
        ref.invalidate(expensesProvider);
        ref.invalidate(activeBudgetProvider);
        ref.invalidate(recentExpensesProvider);
        this.state = this.state.copyWith(status: .success);
      },
    );
  }

  Future<void> _delete() async {
    if (state.id == null) return;

    state = state.copyWith(isDeleting: true);

    final data = await _repository.delete(id: state.id!);

    data.fold(
      (failure) => state = state.copyWith(
        isDeleting: false,
        status: .failure,
        message: failure.message,
      ),
      (_) {
        ref.invalidate(expensesProvider);
        ref.invalidate(activeBudgetProvider);
        ref.invalidate(recentExpensesProvider);
        state = state.copyWith(isDeleting: false, status: .success);
      },
    );
  }
}
