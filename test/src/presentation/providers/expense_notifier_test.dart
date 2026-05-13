import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:trocado/src/domain/either/either.dart';

import 'package:trocado/src/main/providers/services_provider.dart';
import 'package:trocado/src/main/providers/validators_provider.dart';
import 'package:trocado/src/main/providers/repositories_provider.dart';

import 'package:trocado/src/domain/failures/failure.dart';
import 'package:trocado/src/domain/models/expense/expense_model.dart';
import 'package:trocado/src/domain/services/date_formatter_service.dart';
import 'package:trocado/src/domain/repositories/interface_expense_repository.dart';

import 'package:trocado/src/presentation/ui/expense/notifiers/form/expense_state.dart';
import 'package:trocado/src/presentation/ui/expense/notifiers/form/expense_intent.dart';
import 'package:trocado/src/presentation/ui/expense/notifiers/form/expense_notifier.dart';

import 'package:trocado/src/presentation/ui/expense/validators/expense_form_validator.dart';
import 'package:trocado/src/presentation/ui/expense/validators/expense_date_validation.dart';
import 'package:trocado/src/presentation/ui/expense/validators/expense_value_validation.dart';
import 'package:trocado/src/presentation/ui/expense/validators/expense_description_validation.dart';

import '../../../mocks/mocks.dart';

const _date = 1741996800000;

const _expense = ExpenseModel(
  id: 1,
  value: 8550,
  date: _date,
  category: .food,
  createdAt: _date,
  description: 'Mercado',
);

Future<ProviderContainer> _makeContainer(
  IExpenseRepository repository, {
  int? id,
  IDateFormatterService? dateFormatter,
}) async {
  final formatter = dateFormatter ?? MockDateFormatterService();
  when(() => formatter.formatShortDate(any())).thenReturn('15/03/2026');

  final container = ProviderContainer(
    overrides: [
      dateFormatterServiceProvider.overrideWithValue(formatter),
      expenseRepositoryProvider.overrideWithValue(repository),
      expenseFormValidatorProvider.overrideWithValue(
        const ExpenseFormValidator(
          dateValidation: ExpenseDateValidation(),
          valueValidation: ExpenseValueValidation(),
          descriptionValidation: ExpenseDescriptionValidation(),
        ),
      ),
    ],
  );
  addTearDown(container.dispose);
  container.listen(expenseProvider(id), (_, _) {});
  await container.read(expenseProvider(id).future);
  return container;
}

ExpenseState _formState(ProviderContainer container, {int? id}) =>
    container.read(expenseProvider(id)).value!;

ExpenseNotifier _formNotifier(ProviderContainer container, {int? id}) =>
    container.read(expenseProvider(id).notifier);

void main() {
  late IExpenseRepository repository;

  setUp(() {
    repository = MockExpenseRepository();
  });

  group('build(null) — create mode', () {
    test(
      'returns initial state with id null and date defaulted to now',
      () async {
        final container = await _makeContainer(repository);

        final state = _formState(container);
        expect(state.id, isNull);
        expect(state.value, 0);
        expect(state.description, '');
        expect(state.date, isNotNull);
        expect(state.status, ExpenseStatus.initial);
      },
    );
  });

  group('build(id) — edit mode', () {
    test('awaits findById and returns state prefilled', () async {
      when(
        () => repository.findById(id: any(named: 'id')),
      ).thenAnswer((_) async => const Right(_expense));

      final container = await _makeContainer(repository, id: 1);

      final state = _formState(container, id: 1);
      expect(state.id, _expense.id);
      expect(state.date, _expense.date);
      expect(state.value, _expense.value);
      expect(state.description, _expense.description);
    });
  });

  group('dispatch — ValueChanged', () {
    test('updates value in state', () async {
      final container = await _makeContainer(repository);

      _formNotifier(container).dispatch(const ValueChanged(8550));

      expect(_formState(container).value, 8550);
    });

    test('clears valueFailure', () async {
      final container = await _makeContainer(repository);
      _formNotifier(container).dispatch(const SubmitPressed());

      _formNotifier(container).dispatch(const ValueChanged(8550));

      expect(_formState(container).valueFailure, isNull);
    });
  });

  group('dispatch — DescriptionChanged', () {
    test('updates description in state', () async {
      final container = await _makeContainer(repository);

      _formNotifier(container).dispatch(const DescriptionChanged('Mercado'));

      expect(_formState(container).description, 'Mercado');
    });

    test('clears descriptionFailure', () async {
      final container = await _makeContainer(repository);
      _formNotifier(container).dispatch(const SubmitPressed());

      _formNotifier(container).dispatch(const DescriptionChanged('Mercado'));

      expect(_formState(container).descriptionFailure, isNull);
    });
  });

  group('dispatch — DateChanged', () {
    test('updates date in state', () async {
      final container = await _makeContainer(repository);

      _formNotifier(container).dispatch(const DateChanged(_date));

      expect(_formState(container).date, _date);
    });
  });

  group('dispatch — SubmitPressed (create)', () {
    test('sets validation failures when state is empty', () async {
      final container = await _makeContainer(repository);

      _formNotifier(container).dispatch(const SubmitPressed());

      final state = _formState(container);
      expect(state.valueFailure, isNotNull);
      expect(state.descriptionFailure, isNotNull);
    });

    test('does not call repository when validation fails', () async {
      final container = await _makeContainer(repository);

      _formNotifier(container).dispatch(const SubmitPressed());

      verifyNever(
        () => repository.create(
          date: any(named: 'date'),
          value: any(named: 'value'),
          description: any(named: 'description'),
        ),
      );
    });

    test('calls repository.create on valid submit', () async {
      when(
        () => repository.create(
          date: any(named: 'date'),
          value: any(named: 'value'),
          description: any(named: 'description'),
        ),
      ).thenAnswer((_) async => const Right(_expense));

      final container = await _makeContainer(repository);
      final notifier = _formNotifier(container);

      notifier.dispatch(const ValueChanged(8550));
      notifier.dispatch(const DescriptionChanged('Mercado'));
      notifier.dispatch(const DateChanged(_date));
      notifier.dispatch(const SubmitPressed());

      await pumpEventQueue();

      expect(_formState(container).status, ExpenseStatus.success);
      verifyNever(
        () => repository.update(
          id: any(named: 'id'),
          date: any(named: 'date'),
          value: any(named: 'value'),
          description: any(named: 'description'),
        ),
      );
    });

    test('sets status to failure on network error', () async {
      when(
        () => repository.create(
          date: any(named: 'date'),
          value: any(named: 'value'),
          description: any(named: 'description'),
        ),
      ).thenAnswer((_) async => const Left(NetworkFailure()));

      final container = await _makeContainer(repository);
      final notifier = _formNotifier(container);

      notifier.dispatch(const ValueChanged(8550));
      notifier.dispatch(const DescriptionChanged('Mercado'));
      notifier.dispatch(const DateChanged(_date));
      notifier.dispatch(const SubmitPressed());

      await pumpEventQueue();

      expect(_formState(container).status, ExpenseStatus.failure);
    });
  });

  group('dispatch — SubmitPressed (update)', () {
    test('calls repository.update with state.id and not create', () async {
      when(
        () => repository.findById(id: any(named: 'id')),
      ).thenAnswer((_) async => const Right(_expense));
      when(
        () => repository.update(
          id: any(named: 'id'),
          date: any(named: 'date'),
          value: any(named: 'value'),
          description: any(named: 'description'),
        ),
      ).thenAnswer((_) async => const Right(_expense));

      final container = await _makeContainer(repository, id: 1);
      _formNotifier(container, id: 1).dispatch(const SubmitPressed());

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
        () => repository.findById(id: any(named: 'id')),
      ).thenAnswer((_) async => const Right(_expense));
      when(
        () => repository.update(
          id: any(named: 'id'),
          date: any(named: 'date'),
          value: any(named: 'value'),
          description: any(named: 'description'),
        ),
      ).thenAnswer((_) async => const Right(_expense));

      final container = await _makeContainer(repository, id: 1);
      _formNotifier(container, id: 1).dispatch(const SubmitPressed());

      await pumpEventQueue();

      expect(_formState(container, id: 1).status, ExpenseStatus.success);
    });

    test('preserves form fields on update failure', () async {
      when(
        () => repository.findById(id: any(named: 'id')),
      ).thenAnswer((_) async => const Right(_expense));
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

      final container = await _makeContainer(repository, id: 1);
      _formNotifier(container, id: 1).dispatch(const SubmitPressed());

      await pumpEventQueue();

      final state = _formState(container, id: 1);
      expect(state.status, ExpenseStatus.failure);
      expect(state.message, 'Valor inválido.');
      expect(state.id, _expense.id);
      expect(state.value, _expense.value);
      expect(state.description, _expense.description);
      expect(state.date, _expense.date);
    });
  });

  group('dispatch — DeletePressed', () {
    test('does not call repository.delete in create mode (id null)', () async {
      final container = await _makeContainer(repository);
      _formNotifier(container).dispatch(const DeletePressed());
      await pumpEventQueue();

      verifyNever(() => repository.delete(id: any(named: 'id')));
    });

    test('calls repository.delete with state.id in edit mode', () async {
      when(
        () => repository.findById(id: any(named: 'id')),
      ).thenAnswer((_) async => const Right(_expense));
      when(
        () => repository.delete(id: any(named: 'id')),
      ).thenAnswer((_) async => const Right(null));

      final container = await _makeContainer(repository, id: 1);
      _formNotifier(container, id: 1).dispatch(const DeletePressed());

      await pumpEventQueue();

      verify(() => repository.delete(id: _expense.id)).called(1);
    });

    test(
      'sets status to success and isDeleting back to false on success',
      () async {
        when(
          () => repository.findById(id: any(named: 'id')),
        ).thenAnswer((_) async => const Right(_expense));
        when(
          () => repository.delete(id: any(named: 'id')),
        ).thenAnswer((_) async => const Right(null));

        final container = await _makeContainer(repository, id: 1);
        _formNotifier(container, id: 1).dispatch(const DeletePressed());

        await pumpEventQueue();

        final state = _formState(container, id: 1);
        expect(state.status, ExpenseStatus.success);
        expect(state.isDeleting, isFalse);
      },
    );

    test('sets status to failure on delete failure, preserves form', () async {
      when(
        () => repository.findById(id: any(named: 'id')),
      ).thenAnswer((_) async => const Right(_expense));
      when(
        () => repository.delete(id: any(named: 'id')),
      ).thenAnswer((_) async => const Left(ServerFailure()));

      final container = await _makeContainer(repository, id: 1);
      _formNotifier(container, id: 1).dispatch(const DeletePressed());

      await pumpEventQueue();

      final state = _formState(container, id: 1);
      expect(state.id, _expense.id);
      expect(state.message, isNotEmpty);
      expect(state.date, _expense.date);
      expect(state.isDeleting, isFalse);
      expect(state.value, _expense.value);
      expect(state.status, ExpenseStatus.failure);
      expect(state.description, _expense.description);
    });
  });
}
