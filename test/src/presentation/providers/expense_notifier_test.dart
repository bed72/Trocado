import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:trocado/src/domain/either/either.dart';

import 'package:trocado/src/main/providers/validators_provider.dart';
import 'package:trocado/src/main/providers/repositories_provider.dart';

import 'package:trocado/src/domain/failures/failure.dart';
import 'package:trocado/src/domain/models/expense/expense_model.dart';
import 'package:trocado/src/domain/enums/expense/expense_category_enum.dart';
import 'package:trocado/src/domain/repositories/interface_expense_repository.dart';

import 'package:trocado/src/presentation/ui/expense/notifiers/expense_state.dart';
import 'package:trocado/src/presentation/ui/expense/notifiers/expense_intent.dart';
import 'package:trocado/src/presentation/ui/expense/notifiers/expense_notifier.dart';

import 'package:trocado/src/presentation/ui/expense/validators/expense_form_validator.dart';
import 'package:trocado/src/presentation/ui/expense/validators/expense_date_validation.dart';
import 'package:trocado/src/presentation/ui/expense/validators/expense_value_validation.dart';
import 'package:trocado/src/presentation/ui/expense/validators/expense_description_validation.dart';

import '../../../mocks/mocks.dart';

const _date = 1741996800000; // 2026-03-15 UTC

const _expense = ExpenseModel(
  id: 1,
  value: 8550,
  date: _date,
  createdAt: _date,
  description: 'Mercado',
  category: ExpenseCategoryEnum.food,
);

ProviderContainer _makeContainer(
  IExpenseRepository repository, {
  ExpenseModel? expense,
}) {
  final container = ProviderContainer(
    overrides: [
      expenseRepositoryProvider.overrideWithValue(repository),
      expenseFormValidatorProvider.overrideWithValue(
        const ExpenseFormValidator(
          valueValidation: ExpenseValueValidation(),
          descriptionValidation: ExpenseDescriptionValidation(),
          dateValidation: ExpenseDateValidation(),
        ),
      ),
    ],
  );
  addTearDown(container.dispose);
  container.listen(expenseProvider(expense), (_, _) {});
  container.read(expenseProvider(expense));
  return container;
}

void main() {
  late IExpenseRepository repository;

  setUp(() {
    repository = MockExpenseRepository();
  });

  group('initial state', () {
    test('value is zero', () {
      final container = _makeContainer(repository);
      expect(container.read(expenseProvider(null)).value, 0);
    });

    test('date is pre-filled with today', () {
      final container = _makeContainer(repository);
      expect(container.read(expenseProvider(null)).date, isNotNull);
    });

    test('description is empty', () {
      final container = _makeContainer(repository);
      expect(container.read(expenseProvider(null)).description, '');
    });

    test('status is initial', () {
      final container = _makeContainer(repository);
      expect(container.read(expenseProvider(null)).status, ExpenseStatus.initial);
    });
  });

  group('dispatch — ValueChanged', () {
    test('updates value in state', () {
      final container = _makeContainer(repository);

      container
          .read(expenseProvider(null).notifier)
          .dispatch(const ValueChanged(8550));

      expect(container.read(expenseProvider(null)).value, 8550);
    });

    test('clears valueFailure', () {
      final container = _makeContainer(repository);
      container.read(expenseProvider(null).notifier).dispatch(const SubmitPressed());

      container
          .read(expenseProvider(null).notifier)
          .dispatch(const ValueChanged(8550));

      expect(container.read(expenseProvider(null)).valueFailure, isNull);
    });
  });

  group('dispatch — DescriptionChanged', () {
    test('updates description in state', () {
      final container = _makeContainer(repository);

      container
          .read(expenseProvider(null).notifier)
          .dispatch(const DescriptionChanged('Mercado'));

      expect(container.read(expenseProvider(null)).description, 'Mercado');
    });

    test('clears descriptionFailure', () {
      final container = _makeContainer(repository);
      container.read(expenseProvider(null).notifier).dispatch(const SubmitPressed());

      container
          .read(expenseProvider(null).notifier)
          .dispatch(const DescriptionChanged('Mercado'));

      expect(container.read(expenseProvider(null)).descriptionFailure, isNull);
    });
  });

  group('dispatch — DateChanged', () {
    test('updates date in state', () {
      final container = _makeContainer(repository);

      container
          .read(expenseProvider(null).notifier)
          .dispatch(const DateChanged(_date));

      expect(container.read(expenseProvider(null)).date, _date);
    });

    test('clears dateFailure', () {
      final container = _makeContainer(repository);
      container.read(expenseProvider(null).notifier).dispatch(const SubmitPressed());

      container
          .read(expenseProvider(null).notifier)
          .dispatch(const DateChanged(_date));

      expect(container.read(expenseProvider(null)).dateFailure, isNull);
    });
  });

  group('dispatch — SubmitPressed', () {
    test('sets value and description failures when only those are missing', () {
      final container = _makeContainer(repository);

      container.read(expenseProvider(null).notifier).dispatch(const SubmitPressed());

      final state = container.read(expenseProvider(null));

      expect(state.valueFailure, isNotNull);
      expect(state.descriptionFailure, isNotNull);
      expect(state.dateFailure, isNull);
    });

    test('does not call repository when validation fails', () {
      final container = _makeContainer(repository);

      container.read(expenseProvider(null).notifier).dispatch(const SubmitPressed());

      verifyNever(
        () => repository.create(
          date: any(named: 'date'),
          value: any(named: 'value'),
          description: any(named: 'description'),
        ),
      );
    });

    test('keeps status as initial when validation fails', () {
      final container = _makeContainer(repository);

      container.read(expenseProvider(null).notifier).dispatch(const SubmitPressed());

      expect(container.read(expenseProvider(null)).status, ExpenseStatus.initial);
    });

    test(
      'sets status to loading then success on successful creation',
      () async {
        when(
          () => repository.create(
            date: any(named: 'date'),
            value: any(named: 'value'),
            description: any(named: 'description'),
          ),
        ).thenAnswer((_) async => const Right(_expense));

        final container = _makeContainer(repository);
        final notifier = container.read(expenseProvider(null).notifier);

        notifier.dispatch(const ValueChanged(8550));
        notifier.dispatch(const DescriptionChanged('Mercado'));
        notifier.dispatch(const DateChanged(_date));
        notifier.dispatch(const SubmitPressed());

        await pumpEventQueue();

        expect(container.read(expenseProvider(null)).status, ExpenseStatus.success);
      },
    );

    test('sets status to failure with message on validation error', () async {
      when(
        () => repository.create(
          date: any(named: 'date'),
          value: any(named: 'value'),
          description: any(named: 'description'),
        ),
      ).thenAnswer(
        (_) async => const Left(ValidationFailure('Valor inválido.')),
      );

      final container = _makeContainer(repository);
      final notifier = container.read(expenseProvider(null).notifier);

      notifier.dispatch(const ValueChanged(8550));
      notifier.dispatch(const DescriptionChanged('Mercado'));
      notifier.dispatch(const DateChanged(_date));
      notifier.dispatch(const SubmitPressed());

      await pumpEventQueue();

      final state = container.read(expenseProvider(null));
      expect(state.status, ExpenseStatus.failure);
      expect(state.message, 'Valor inválido.');
    });

    test('sets status to failure on network error', () async {
      when(
        () => repository.create(
          value: any(named: 'value'),
          date: any(named: 'date'),
          description: any(named: 'description'),
        ),
      ).thenAnswer((_) async => const Left(NetworkFailure()));

      final container = _makeContainer(repository);
      final notifier = container.read(expenseProvider(null).notifier);

      notifier.dispatch(const ValueChanged(8550));
      notifier.dispatch(const DescriptionChanged('Mercado'));
      notifier.dispatch(const DateChanged(_date));
      notifier.dispatch(const SubmitPressed());

      await pumpEventQueue();

      final state = container.read(expenseProvider(null));
      expect(state.message, isNotEmpty);
      expect(state.status, ExpenseStatus.failure);
    });

    test('sets status to failure on server error', () async {
      when(
        () => repository.create(
          value: any(named: 'value'),
          date: any(named: 'date'),
          description: any(named: 'description'),
        ),
      ).thenAnswer((_) async => const Left(ServerFailure()));

      final container = _makeContainer(repository);
      final notifier = container.read(expenseProvider(null).notifier);

      notifier.dispatch(const ValueChanged(8550));
      notifier.dispatch(const DescriptionChanged('Mercado'));
      notifier.dispatch(const DateChanged(_date));
      notifier.dispatch(const SubmitPressed());

      await pumpEventQueue();

      expect(container.read(expenseProvider(null)).status, ExpenseStatus.failure);
    });
  });

  group('build(expense) — edit mode', () {
    test('returns state pre-filled with id, date, value, description', () {
      final container = _makeContainer(repository, expense: _expense);
      final state = container.read(expenseProvider(_expense));

      expect(state.id, _expense.id);
      expect(state.date, _expense.date);
      expect(state.value, _expense.value);
      expect(state.description, _expense.description);
    });

    test('status is initial', () {
      final container = _makeContainer(repository, expense: _expense);
      expect(
        container.read(expenseProvider(_expense)).status,
        ExpenseStatus.initial,
      );
    });
  });

  group('build(null) — create mode', () {
    test('id is null', () {
      final container = _makeContainer(repository);
      expect(container.read(expenseProvider(null)).id, isNull);
    });
  });

  group('dispatch — SubmitPressed in edit mode', () {
    test('calls repository.update with state.id and does not call create', () async {
      when(
        () => repository.update(
          id: any(named: 'id'),
          date: any(named: 'date'),
          value: any(named: 'value'),
          description: any(named: 'description'),
        ),
      ).thenAnswer((_) async => const Right(_expense));

      final container = _makeContainer(repository, expense: _expense);
      final notifier = container.read(expenseProvider(_expense).notifier);

      notifier.dispatch(const SubmitPressed());

      await pumpEventQueue();

      verify(
        () => repository.update(
          id: _expense.id,
          date: _expense.date,
          value: _expense.value,
          description: _expense.description,
        ),
      ).called(1);

      verifyNever(
        () => repository.create(
          date: any(named: 'date'),
          value: any(named: 'value'),
          description: any(named: 'description'),
        ),
      );
    });

    test('sets status to success on successful update', () async {
      when(
        () => repository.update(
          id: any(named: 'id'),
          date: any(named: 'date'),
          value: any(named: 'value'),
          description: any(named: 'description'),
        ),
      ).thenAnswer((_) async => const Right(_expense));

      final container = _makeContainer(repository, expense: _expense);
      final notifier = container.read(expenseProvider(_expense).notifier);

      notifier.dispatch(const SubmitPressed());

      await pumpEventQueue();

      expect(
        container.read(expenseProvider(_expense)).status,
        ExpenseStatus.success,
      );
    });

    test(
      'sets status to failure and preserves form fields on update failure',
      () async {
        when(
          () => repository.update(
            id: any(named: 'id'),
            date: any(named: 'date'),
            value: any(named: 'value'),
            description: any(named: 'description'),
          ),
        ).thenAnswer(
          (_) async => const Left(ValidationFailure('Valor inválido.')),
        );

        final container = _makeContainer(repository, expense: _expense);
        final notifier = container.read(expenseProvider(_expense).notifier);

        notifier.dispatch(const SubmitPressed());

        await pumpEventQueue();

        final state = container.read(expenseProvider(_expense));
        expect(state.status, ExpenseStatus.failure);
        expect(state.message, 'Valor inválido.');
        expect(state.id, _expense.id);
        expect(state.value, _expense.value);
        expect(state.description, _expense.description);
        expect(state.date, _expense.date);
      },
    );
  });

  group('dispatch — DeletePressed', () {
    test('calls repository.delete with state.id in edit mode', () async {
      when(
        () => repository.delete(id: any(named: 'id')),
      ).thenAnswer((_) async => const Right(null));

      final container = _makeContainer(repository, expense: _expense);
      final notifier = container.read(expenseProvider(_expense).notifier);

      notifier.dispatch(const DeletePressed());

      await pumpEventQueue();

      verify(() => repository.delete(id: _expense.id)).called(1);
    });

    test('does not call repository.delete in create mode (id null)', () async {
      final container = _makeContainer(repository);
      final notifier = container.read(expenseProvider(null).notifier);

      notifier.dispatch(const DeletePressed());

      await pumpEventQueue();

      verifyNever(() => repository.delete(id: any(named: 'id')));
    });

    test('sets status to success on successful delete', () async {
      when(
        () => repository.delete(id: any(named: 'id')),
      ).thenAnswer((_) async => const Right(null));

      final container = _makeContainer(repository, expense: _expense);
      final notifier = container.read(expenseProvider(_expense).notifier);

      notifier.dispatch(const DeletePressed());

      await pumpEventQueue();

      final state = container.read(expenseProvider(_expense));
      expect(state.status, ExpenseStatus.success);
      expect(state.isDeleting, isFalse);
    });

    test(
      'sets status to failure with message on delete failure, preserves form',
      () async {
        when(() => repository.delete(id: any(named: 'id'))).thenAnswer(
          (_) async => const Left(ServerFailure()),
        );

        final container = _makeContainer(repository, expense: _expense);
        final notifier = container.read(expenseProvider(_expense).notifier);

        notifier.dispatch(const DeletePressed());

        await pumpEventQueue();

        final state = container.read(expenseProvider(_expense));
        expect(state.status, ExpenseStatus.failure);
        expect(state.message, isNotEmpty);
        expect(state.isDeleting, isFalse);
        expect(state.id, _expense.id);
        expect(state.value, _expense.value);
        expect(state.description, _expense.description);
        expect(state.date, _expense.date);
      },
    );

    test('toggles isDeleting to true while in flight', () async {
      when(() => repository.delete(id: any(named: 'id'))).thenAnswer(
        (_) async {
          await Future<void>.delayed(Duration.zero);
          return const Right(null);
        },
      );

      final container = _makeContainer(repository, expense: _expense);
      final notifier = container.read(expenseProvider(_expense).notifier);

      notifier.dispatch(const DeletePressed());

      expect(
        container.read(expenseProvider(_expense)).isDeleting,
        isTrue,
      );

      await pumpEventQueue();

      expect(
        container.read(expenseProvider(_expense)).isDeleting,
        isFalse,
      );
    });
  });
}
