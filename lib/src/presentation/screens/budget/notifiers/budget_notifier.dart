import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:trocado/src/main/providers/validators_provider.dart';
import 'package:trocado/src/main/providers/repositories_provider.dart';

import 'package:trocado/src/domain/repositories/interface_budget_repository.dart';

import 'package:trocado/src/presentation/screens/budget/notifiers/budget_state.dart';
import 'package:trocado/src/presentation/screens/budget/notifiers/budget_intent.dart';
import 'package:trocado/src/presentation/screens/budget/validators/budget_form_validator.dart';

part 'budget_notifier.g.dart';

@riverpod
final class BudgetNotifier extends _$BudgetNotifier {
  late BudgetFormValidator _validator;
  late IBudgetRepository _repository;

  @override
  BudgetState build() {
    _validator = ref.watch(budgetFormValidatorProvider);
    _repository = ref.watch(budgetRepositoryProvider);
    return const BudgetState();
  }

  void dispatch(BudgetIntent intent) => switch (intent) {
    ValueChanged(:final value) => state = state.copyWith(
      value: value,
      clearValueFailure: true,
    ),
    DateRangeChanged(:final startDate, :final endDate) =>
      state = state.copyWith(
        endDate: endDate,
        startDate: startDate,
        clearDateFailure: true,
      ),
    DescriptionChanged(:final value) => state = state.copyWith(
      description: value,
      clearDescriptionFailure: true,
    ),
    SubmitPressed() => _submit(),
  };

  Future<void> _submit() async {
    final (:state, :isValid) = _validator(this.state);
    this.state = state;

    if (!isValid) return;

    this.state = this.state.copyWith(status: BudgetStatus.loading);

    final data = await _repository.create(
      value: this.state.value,
      endDate: this.state.endDate!,
      startDate: this.state.startDate!,
      description: this.state.description,
    );

    data.fold(
      (failure) => this.state = this.state.copyWith(
        status: .failure,
        message: failure.message,
      ),
      (_) => this.state = this.state.copyWith(status: .success),
    );
  }
}
