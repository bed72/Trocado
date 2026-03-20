import 'package:mocktail/mocktail.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/src/application/services/money_service.dart';

import 'package:trocado/src/domain/either/either.dart';
import 'package:trocado/src/domain/models/expense_model.dart';
import 'package:trocado/src/domain/repositories/interface_expense_repository.dart';

import 'package:trocado/src/presentation/mapper/expense_presentation_mapper.dart';
import 'package:trocado/src/presentation/bloc/expense_form/expense_form_bloc.dart';
import 'package:trocado/src/presentation/bloc/expense_form/expense_form_event.dart';
import 'package:trocado/src/presentation/bloc/expense_form/expense_form_state.dart';

import '../../../mocks/mocks.dart';

void main() {
  late IMoneyService service;
  late IExpenseRepository repository;
  late ExpenseStateToModelMapper mapper;

  setUp(() {
    service = MockMoneyService();
    repository = MockExpenseRepository();
    mapper = MockExpenseStateToModelMapper();

    when(() => service.format(any())).thenAnswer((invocation) {
      final value = invocation.positionalArguments[0] as double;
      return 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
    });

    registerFallbackValue(
      const ExpenseModel(
        date: 0,
        amount: 123,
        category: 'other',
        description: 'café',
      ),
    );

    registerFallbackValue(
      ExpenseFormState(
        amount: 123,
        category: .other,
        description: 'Café',
        date: DateTime(2026, 2, 27),
      ),
    );
  });

  ExpenseFormBloc buildBloc() =>
      ExpenseFormBloc(service: service, repository: repository, mapper: mapper);

  group('amount', () {
    blocTest<ExpenseFormBloc, ExpenseFormState>(
      'should start with zero amount',
      build: buildBloc,
      verify: (bloc) {
        expect(bloc.state.amount, 0);
        expect(bloc.state.formattedAmount, 'R\$ 0,00');
      },
    );

    blocTest<ExpenseFormBloc, ExpenseFormState>(
      'should append digit when digit action is received',
      build: buildBloc,
      act: (bloc) {
        bloc.add(const ExpenseAmountDigitPressed('1'));
        bloc.add(const ExpenseAmountDigitPressed('2'));
      },
      expect: () => [
        isA<ExpenseFormState>()
            .having((s) => s.amount, 'amount', 1)
            .having((s) => s.formattedAmount, 'formatted', 'R\$ 0,01'),
        isA<ExpenseFormState>()
            .having((s) => s.amount, 'amount', 12)
            .having((s) => s.formattedAmount, 'formatted', 'R\$ 0,12'),
      ],
    );

    blocTest<ExpenseFormBloc, ExpenseFormState>(
      'should remove last digit when delete action is received',
      build: buildBloc,
      act: (bloc) {
        bloc.add(const ExpenseAmountDigitPressed('5'));
        bloc.add(const ExpenseAmountDigitPressed('0'));
        bloc.add(const ExpenseAmountDeletePressed());
      },
      expect: () => [
        isA<ExpenseFormState>().having((s) => s.amount, 'amount', 5),
        isA<ExpenseFormState>().having((s) => s.amount, 'amount', 50),
        isA<ExpenseFormState>().having((s) => s.amount, 'amount', 5),
      ],
    );

    blocTest<ExpenseFormBloc, ExpenseFormState>(
      'should reset amount when clear action is received',
      build: buildBloc,
      act: (bloc) {
        bloc.add(const ExpenseAmountDigitPressed('9'));
        bloc.add(const ExpenseAmountDigitPressed('9'));
        bloc.add(const ExpenseAmountCleared());
      },
      expect: () => [
        isA<ExpenseFormState>().having((s) => s.amount, 'amount', 9),
        isA<ExpenseFormState>().having((s) => s.amount, 'amount', 99),
        isA<ExpenseFormState>()
            .having((s) => s.amount, 'amount', 0)
            .having((s) => s.formattedAmount, 'formatted', 'R\$ 0,00'),
      ],
    );

    blocTest<ExpenseFormBloc, ExpenseFormState>(
      'should handle a realistic user input sequence correctly',
      build: buildBloc,
      act: (bloc) {
        bloc.add(const ExpenseAmountDigitPressed('1'));
        bloc.add(const ExpenseAmountDigitPressed('2'));
        bloc.add(const ExpenseAmountDigitPressed('3'));
        bloc.add(const ExpenseAmountDeletePressed());
        bloc.add(const ExpenseAmountDigitPressed('9'));
        bloc.add(const ExpenseAmountCleared());
      },
      expect: () => [
        isA<ExpenseFormState>().having((s) => s.amount, 'amount', 1),
        isA<ExpenseFormState>().having((s) => s.amount, 'amount', 12),
        isA<ExpenseFormState>().having((s) => s.amount, 'amount', 123),
        isA<ExpenseFormState>().having((s) => s.amount, 'amount', 12),
        isA<ExpenseFormState>().having((s) => s.amount, 'amount', 129),
        isA<ExpenseFormState>().having((s) => s.amount, 'amount', 0),
      ],
    );
  });

  group('description', () {
    blocTest<ExpenseFormBloc, ExpenseFormState>(
      'should start empty and update value',
      build: buildBloc,
      act: (bloc) {
        bloc.add(const ExpenseDescriptionChanged('Nova descri\u00e7\u00e3o'));
      },
      expect: () => [
        isA<ExpenseFormState>().having(
          (s) => s.description,
          'description',
          'Nova descrição',
        ),
      ],
    );
  });

  group('validation', () {
    blocTest<ExpenseFormBloc, ExpenseFormState>(
      'should show errors when form submitted with invalid data',
      build: buildBloc,
      act: (bloc) {
        bloc.add(const ExpenseFormSubmitted());
      },
      expect: () => [
        isA<ExpenseFormState>().having((s) => s.hasFailure, 'hasFailure', true),
      ],
    );

    blocTest<ExpenseFormBloc, ExpenseFormState>(
      'errors should clear reactively when fields become valid',
      build: buildBloc,
      act: (bloc) {
        bloc.add(const ExpenseFormSubmitted());
        bloc.add(const ExpenseDescriptionChanged('Café'));
        bloc.add(const ExpenseAmountDigitPressed('1'));
      },
      verify: (bloc) {
        expect(bloc.state.isValid, true);
        expect(bloc.state.hasFailure, true);
        expect(bloc.state.amountFailure, isNull);
        expect(bloc.state.descriptionFailure, isNull);
      },
    );
  });

  group('save', () {
    blocTest<ExpenseFormBloc, ExpenseFormState>(
      'should save successfully when form is valid',
      build: buildBloc,
      setUp: () {
        when(() => mapper(any())).thenReturn(
          const ExpenseModel(
            date: 0,
            amount: 1.23,
            category: 'other',
            description: 'Café',
          ),
        );
        when(() => repository.upsert(any())).thenReturn(const Right(null));
      },
      act: (bloc) {
        bloc.add(const ExpenseAmountDigitPressed('1'));
        bloc.add(const ExpenseAmountDigitPressed('2'));
        bloc.add(const ExpenseAmountDigitPressed('3'));
        bloc.add(const ExpenseDescriptionChanged('Café'));
        bloc.add(const ExpenseFormSubmitted());
      },
      verify: (bloc) {
        verify(() => repository.upsert(any())).called(1);
      },
    );
  });
}
