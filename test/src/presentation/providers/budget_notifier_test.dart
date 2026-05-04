import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:trocado/src/domain/either/either.dart';

import 'package:trocado/src/main/providers/validators_provider.dart';
import 'package:trocado/src/main/providers/repositories_provider.dart';

import 'package:trocado/src/domain/failures/failure.dart';
import 'package:trocado/src/domain/models/budget/budget_model.dart';
import 'package:trocado/src/domain/repositories/interface_budget_repository.dart';

import 'package:trocado/src/presentation/ui/budget/notifiers/form/budget_form_state.dart';
import 'package:trocado/src/presentation/ui/budget/notifiers/form/budget_form_intent.dart';
import 'package:trocado/src/presentation/ui/budget/notifiers/form/budget_form_notifier.dart';
import 'package:trocado/src/presentation/ui/budget/validators/budget_form_validator.dart';
import 'package:trocado/src/presentation/ui/budget/validators/budget_value_validation.dart';
import 'package:trocado/src/presentation/ui/budget/validators/budget_description_validation.dart';
import 'package:trocado/src/presentation/ui/budget/validators/budget_date_range_validation.dart';

import '../../../mocks/mocks.dart';

const _endDate = 1743379200000;
const _startDate = 1740787200000;

const _budget = BudgetModel(
  id: 1,
  value: 100000,
  endDate: _endDate,
  startDate: _startDate,
  description: 'March budget',
);

Future<ProviderContainer> _makeContainer(
  IBudgetRepository repository, {
  int? id,
}) async {
  final container = ProviderContainer(
    overrides: [
      budgetRepositoryProvider.overrideWithValue(repository),
      budgetFormValidatorProvider.overrideWithValue(
        const BudgetFormValidator(
          valueValidation: BudgetValueValidation(),
          dateRangeValidation: BudgetDateRangeValidation(),
          descriptionValidation: BudgetDescriptionValidation(),
        ),
      ),
    ],
  );
  addTearDown(container.dispose);
  container.listen(budgetFormProvider(id), (_, _) {});
  await container.read(budgetFormProvider(id).future);
  return container;
}

BudgetFormState _formState(ProviderContainer container, {int? id}) =>
    container.read(budgetFormProvider(id)).value!;

BudgetFormNotifier _formNotifier(ProviderContainer container, {int? id}) =>
    container.read(budgetFormProvider(id).notifier);

void main() {
  late IBudgetRepository repository;

  setUp(() {
    repository = MockBudgetRepository();
  });

  group('build(null) — create mode', () {
    test('returns initial state with id null', () async {
      final container = await _makeContainer(repository);

      expect(_formState(container).id, isNull);
      expect(_formState(container).value, 0);
    });
  });

  group('build(id) — edit mode', () {
    test('awaits findById and returns state prefilled', () async {
      when(
        () => repository.findById(id: any(named: 'id')),
      ).thenAnswer((_) async => const Right(_budget));

      final container = await _makeContainer(repository, id: 1);

      final state = _formState(container, id: 1);
      expect(state.id, 1);
      expect(state.value, 100000);
      expect(state.endDate, _endDate);
      expect(state.startDate, _startDate);
      expect(state.description, 'March budget');
    });
  });

  group('dispatch — ValueChanged', () {
    test('updates value in state', () async {
      final container = await _makeContainer(repository);

      _formNotifier(container).dispatch(const ValueChanged(100000));

      expect(_formState(container).value, 100000);
    });

    test('clears valueFailure', () async {
      final container = await _makeContainer(repository);
      _formNotifier(container).dispatch(const SubmitPressed());

      _formNotifier(container).dispatch(const ValueChanged(100000));

      expect(_formState(container).valueFailure, isNull);
    });
  });

  group('dispatch — DescriptionChanged', () {
    test('updates description in state', () async {
      final container = await _makeContainer(repository);

      _formNotifier(
        container,
      ).dispatch(const DescriptionChanged('March budget'));

      expect(_formState(container).description, 'March budget');
    });

    test('clears descriptionFailure', () async {
      final container = await _makeContainer(repository);
      _formNotifier(container).dispatch(const SubmitPressed());

      _formNotifier(
        container,
      ).dispatch(const DescriptionChanged('March budget'));

      expect(_formState(container).descriptionFailure, isNull);
    });
  });

  group('dispatch — DateRangeChanged', () {
    test('updates startDate and endDate in state', () async {
      final container = await _makeContainer(repository);

      _formNotifier(container).dispatch(
        const DateRangeChanged(startDate: _startDate, endDate: _endDate),
      );

      expect(_formState(container).endDate, _endDate);
      expect(_formState(container).startDate, _startDate);
    });

    test('clears dateFailure', () async {
      final container = await _makeContainer(repository);
      _formNotifier(container).dispatch(const SubmitPressed());

      _formNotifier(container).dispatch(
        const DateRangeChanged(startDate: _startDate, endDate: _endDate),
      );

      expect(_formState(container).dateFailure, isNull);
    });
  });

  group('dispatch — SubmitPressed (create)', () {
    test('sets validation failures when state is empty', () async {
      final container = await _makeContainer(repository);

      _formNotifier(container).dispatch(const SubmitPressed());

      final state = _formState(container);
      expect(state.valueFailure, isNotNull);
      expect(state.descriptionFailure, isNotNull);
      expect(state.dateFailure, isNotNull);
    });

    test('does not call repository when validation fails', () async {
      final container = await _makeContainer(repository);

      _formNotifier(container).dispatch(const SubmitPressed());

      verifyNever(
        () => repository.create(
          value: any(named: 'value'),
          endDate: any(named: 'endDate'),
          startDate: any(named: 'startDate'),
          description: any(named: 'description'),
        ),
      );
    });

    test(
      'sets status to loading then success on successful creation',
      () async {
        when(
          () => repository.create(
            value: any(named: 'value'),
            endDate: any(named: 'endDate'),
            startDate: any(named: 'startDate'),
            description: any(named: 'description'),
          ),
        ).thenAnswer((_) async => const Right(_budget));

        final container = await _makeContainer(repository);
        final notifier = _formNotifier(container);

        notifier.dispatch(const ValueChanged(100000));
        notifier.dispatch(const DescriptionChanged('March budget'));
        notifier.dispatch(
          const DateRangeChanged(startDate: _startDate, endDate: _endDate),
        );

        notifier.dispatch(const SubmitPressed());
        await pumpEventQueue();

        expect(_formState(container).status, BudgetFormStatus.success);
      },
    );

    test('sets status to failure with message on validation error', () async {
      when(
        () => repository.create(
          value: any(named: 'value'),
          endDate: any(named: 'endDate'),
          startDate: any(named: 'startDate'),
          description: any(named: 'description'),
        ),
      ).thenAnswer(
        (_) async => const Left(
          ValidationFailure('Orçamento já existe para o período.'),
        ),
      );

      final container = await _makeContainer(repository);
      final notifier = _formNotifier(container);

      notifier.dispatch(const ValueChanged(100000));
      notifier.dispatch(const DescriptionChanged('March budget'));
      notifier.dispatch(
        const DateRangeChanged(startDate: _startDate, endDate: _endDate),
      );
      notifier.dispatch(const SubmitPressed());

      await pumpEventQueue();

      final state = _formState(container);
      expect(state.status, BudgetFormStatus.failure);
      expect(state.message, 'Orçamento já existe para o período.');
    });

    test('sets status to failure on network error', () async {
      when(
        () => repository.create(
          value: any(named: 'value'),
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          description: any(named: 'description'),
        ),
      ).thenAnswer((_) async => const Left(NetworkFailure()));

      final container = await _makeContainer(repository);
      final notifier = _formNotifier(container);

      notifier.dispatch(const ValueChanged(100000));
      notifier.dispatch(const DescriptionChanged('March budget'));
      notifier.dispatch(
        const DateRangeChanged(startDate: _startDate, endDate: _endDate),
      );
      notifier.dispatch(const SubmitPressed());

      await pumpEventQueue();

      final state = _formState(container);
      expect(state.message, isNotEmpty);
      expect(state.status, BudgetFormStatus.failure);
    });
  });

  group('dispatch — SubmitPressed (update)', () {
    test('calls repository.update with state.id when in edit mode', () async {
      when(
        () => repository.findById(id: any(named: 'id')),
      ).thenAnswer((_) async => const Right(_budget));
      when(
        () => repository.update(
          id: any(named: 'id'),
          value: any(named: 'value'),
          endDate: any(named: 'endDate'),
          startDate: any(named: 'startDate'),
          description: any(named: 'description'),
        ),
      ).thenAnswer((_) async => const Right(_budget));

      final container = await _makeContainer(repository, id: 1);
      _formNotifier(container, id: 1).dispatch(const SubmitPressed());

      await pumpEventQueue();

      verify(
        () => repository.update(
          id: 1,
          value: 100000,
          endDate: _endDate,
          startDate: _startDate,
          description: 'March budget',
        ),
      ).called(1);
      verifyNever(
        () => repository.create(
          value: any(named: 'value'),
          endDate: any(named: 'endDate'),
          startDate: any(named: 'startDate'),
          description: any(named: 'description'),
        ),
      );
    });

    test('sets status to success on successful update', () async {
      when(
        () => repository.findById(id: any(named: 'id')),
      ).thenAnswer((_) async => const Right(_budget));
      when(
        () => repository.update(
          id: any(named: 'id'),
          value: any(named: 'value'),
          endDate: any(named: 'endDate'),
          startDate: any(named: 'startDate'),
          description: any(named: 'description'),
        ),
      ).thenAnswer((_) async => const Right(_budget));

      final container = await _makeContainer(repository, id: 1);
      _formNotifier(container, id: 1).dispatch(const SubmitPressed());

      await pumpEventQueue();

      expect(_formState(container, id: 1).status, BudgetFormStatus.success);
    });

    test('preserves form fields on update failure', () async {
      when(
        () => repository.findById(id: any(named: 'id')),
      ).thenAnswer((_) async => const Right(_budget));
      when(
        () => repository.update(
          id: any(named: 'id'),
          value: any(named: 'value'),
          endDate: any(named: 'endDate'),
          startDate: any(named: 'startDate'),
          description: any(named: 'description'),
        ),
      ).thenAnswer((_) async => const Left(NetworkFailure()));

      final container = await _makeContainer(repository, id: 1);
      _formNotifier(container, id: 1).dispatch(const SubmitPressed());

      await pumpEventQueue();

      final state = _formState(container, id: 1);
      expect(state.value, 100000);
      expect(state.description, 'March budget');
      expect(state.status, BudgetFormStatus.failure);
    });
  });

  group('dispatch — DeletePressed', () {
    test('is a no-op in create mode (id null)', () async {
      final container = await _makeContainer(repository);

      _formNotifier(container).dispatch(const DeletePressed());
      await pumpEventQueue();

      verifyNever(() => repository.delete(id: any(named: 'id')));
    });

    test('calls repository.delete with state.id in edit mode', () async {
      when(
        () => repository.findById(id: any(named: 'id')),
      ).thenAnswer((_) async => const Right(_budget));
      when(
        () => repository.delete(id: any(named: 'id')),
      ).thenAnswer((_) async => const Right(null));

      final container = await _makeContainer(repository, id: 1);
      _formNotifier(container, id: 1).dispatch(const DeletePressed());

      await pumpEventQueue();

      verify(() => repository.delete(id: 1)).called(1);
    });

    test(
      'sets status to success and isDeleting back to false on success',
      () async {
        when(
          () => repository.findById(id: any(named: 'id')),
        ).thenAnswer((_) async => const Right(_budget));
        when(
          () => repository.delete(id: any(named: 'id')),
        ).thenAnswer((_) async => const Right(null));

        final container = await _makeContainer(repository, id: 1);
        _formNotifier(container, id: 1).dispatch(const DeletePressed());

        await pumpEventQueue();

        final state = _formState(container, id: 1);
        expect(state.isDeleting, isFalse);
        expect(state.status, BudgetFormStatus.success);
      },
    );

    test('sets status to failure with message on delete error', () async {
      when(
        () => repository.findById(id: any(named: 'id')),
      ).thenAnswer((_) async => const Right(_budget));
      when(
        () => repository.delete(id: any(named: 'id')),
      ).thenAnswer((_) async => const Left(NetworkFailure()));

      final container = await _makeContainer(repository, id: 1);
      _formNotifier(container, id: 1).dispatch(const DeletePressed());

      await pumpEventQueue();

      final state = _formState(container, id: 1);
      expect(state.isDeleting, isFalse);
      expect(state.message, isNotEmpty);
      expect(state.status, BudgetFormStatus.failure);
    });
  });
}
