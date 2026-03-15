import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:trocado/src/application/services/money_service.dart';

import 'package:trocado/src/domain/repositories/interface_expense_repository.dart';

import 'package:trocado/src/presentation/mapper/expense_presentation_mapper.dart';

import 'package:trocado/src/presentation/bloc/expense_form/expense_form_event.dart';
import 'package:trocado/src/presentation/bloc/expense_form/expense_form_state.dart';

final class ExpenseFormBloc extends Bloc<ExpenseFormEvent, ExpenseFormState> {
  final IMoneyService _service;
  final IExpenseRepository _repository;
  final ExpenseStateToModelMapper _mapper;

  ExpenseFormBloc({
    required IMoneyService service,
    required IExpenseRepository repository,
    required ExpenseStateToModelMapper mapper,
  }) : _mapper = mapper,
       _service = service,
       _repository = repository,
       super(
         ExpenseFormState(date: .now(), formattedAmount: service.format(0)),
       ) {
    on<ExpenseFormReset>(_onFormReset);
    on<ExpenseDateChanged>(_onDateChanged);
    on<ExpenseAmountCleared>(_onAmountCleared);
    on<ExpenseFormSubmitted>(_onFormSubmitted);
    on<ExpenseCategoryChanged>(_onCategoryChanged);
    on<ExpenseDescriptionChanged>(_onDescriptionChanged);
    on<ExpenseAmountDigitPressed>(_onAmountDigitPressed);
    on<ExpenseAmountDeletePressed>(_onAmountDeletePressed);
  }

  void _onDescriptionChanged(
    ExpenseDescriptionChanged event,
    Emitter<ExpenseFormState> emit,
  ) {
    emit(state.copyWith(description: event.value));
  }

  void _onAmountDigitPressed(
    ExpenseAmountDigitPressed event,
    Emitter<ExpenseFormState> emit,
  ) {
    final digit = int.parse(event.digit);
    final amount = state.amount * 10 + digit;
    emit(
      state.copyWith(
        amount: amount,
        formattedAmount: _service.format(amount / 100),
      ),
    );
  }

  void _onAmountDeletePressed(
    ExpenseAmountDeletePressed event,
    Emitter<ExpenseFormState> emit,
  ) {
    final amount = state.amount ~/ 10;
    emit(
      state.copyWith(
        amount: amount,
        formattedAmount: _service.format(amount / 100),
      ),
    );
  }

  void _onAmountCleared(
    ExpenseAmountCleared event,
    Emitter<ExpenseFormState> emit,
  ) {
    emit(state.copyWith(amount: 0, formattedAmount: _service.format(0)));
  }

  void _onDateChanged(
    ExpenseDateChanged event,
    Emitter<ExpenseFormState> emit,
  ) {
    emit(state.copyWith(date: event.date));
  }

  void _onCategoryChanged(
    ExpenseCategoryChanged event,
    Emitter<ExpenseFormState> emit,
  ) {
    emit(state.copyWith(category: event.category));
  }

  void _onFormSubmitted(
    ExpenseFormSubmitted event,
    Emitter<ExpenseFormState> emit,
  ) {
    if (!state.isValid) {
      emit(state.copyWith(hasFailure: true));
      return;
    }

    emit(state.copyWith(status: .loading));

    final data = _repository.upsert(_mapper(state));
    data.fold(
      (failure) => emit(state.copyWith(status: .failure, message: failure)),
      (_) {
        emit(
          state.copyWith(
            status: .success,
            message: 'Despesa salva com sucesso.',
          ),
        );
        add(const ExpenseFormReset());
      },
    );
  }

  void _onFormReset(ExpenseFormReset event, Emitter<ExpenseFormState> emit) {
    emit(ExpenseFormState(date: .now(), formattedAmount: _service.format(0)));
  }
}
