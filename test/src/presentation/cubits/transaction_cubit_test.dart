import 'package:mocktail/mocktail.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:trocado/src/data/dtos/transaction_form_dto.dart';

import 'package:trocado/src/domain/either/either.dart';
import 'package:trocado/src/domain/models/category_model.dart';
import 'package:trocado/src/domain/models/transaction_model.dart';

import 'package:trocado/src/presentation/cubits/transaction/transaction_cubit.dart';

import '../../../mocks/mocks.dart';

void main() {
  late TransactionCubit cubit;
  late MockMoneyRepository moneyRepository;
  late MockTransactionRepository transactionRepository;

  final transaction = TransactionModel(
    id: 1,
    amount: 100.50,
    category: 'Salário',
    date: 1704067200000,
    description: 'Salário mensal',
    type: TransactionTypeModel.income.label,
  );

  setUpAll(() async {
    await initializeDateFormatting('pt_BR');

    registerFallbackValue(transaction);
  });

  setUp(() {
    moneyRepository = MockMoneyRepository();
    transactionRepository = MockTransactionRepository();

    when(() => moneyRepository.parse(any())).thenAnswer((invocation) {
      final value = invocation.positionalArguments[0] as String;
      return double.tryParse(value.replaceAll(',', '.')) ?? 0.0;
    });

    when(() => moneyRepository.format(any())).thenAnswer((invocation) {
      final value = invocation.positionalArguments[0] as double;
      return 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
    });

    cubit = TransactionCubit(
      formatter: moneyRepository,
      repository: transactionRepository,
    );
  });

  tearDown(() => cubit.close());

  group('TransactionCubit', () {
    test('initial state is TransactionIdle with empty form', () {
      expect(cubit.state.form.amount, 0.0);
      expect(cubit.state.form.formattedDate, '');
      expect(cubit.state, isA<TransactionIdle>());
      expect(cubit.state.form.category, CategoryModel.other);
    });

    group('format and parse', () {
      test('format delegates to moneyRepository', () {
        final result = cubit.format(100.50);

        expect(result, 'R\$ 100,50');
        verify(() => moneyRepository.format(100.50)).called(1);
      });

      test('parse delegates to moneyRepository', () {
        final result = cubit.parse('100,50');

        expect(result, 100.50);
        verify(() => moneyRepository.parse('100,50')).called(1);
      });
    });

    group('Calculator methods', () {
      group('appendAmount', () {
        blocTest<TransactionCubit, TransactionState>(
          'appends digit to buffer and updates amount',
          build: () => cubit,
          act: (cubit) {
            cubit.appendAmount('1');
            cubit.appendAmount('0');
            cubit.appendAmount('0');
          },
          expect: () => [
            isA<TransactionIdle>().having((s) => s.form.amount, 'amount', 1.0),
            isA<TransactionIdle>().having((s) => s.form.amount, 'amount', 10.0),
            isA<TransactionIdle>().having(
              (s) => s.form.amount,
              'amount',
              100.0,
            ),
          ],
        );

        blocTest<TransactionCubit, TransactionState>(
          'handles decimal separator correctly',
          build: () => cubit,
          act: (cubit) {
            cubit.appendAmount('5');
            cubit.appendAmount(',');
            cubit.appendAmount('5');
            cubit.appendAmount('0');
          },
          expect: () => [
            isA<TransactionIdle>().having((s) => s.form.amount, 'amount', 5.0),
            isA<TransactionIdle>().having((s) => s.form.amount, 'amount', 5.5),
          ],
        );

        blocTest<TransactionCubit, TransactionState>(
          'ignores second decimal separator',
          build: () => cubit,
          act: (cubit) {
            cubit.appendAmount('5');
            cubit.appendAmount(',');
            cubit.appendAmount(',');
            cubit.appendAmount('5');
          },
          expect: () => [
            isA<TransactionIdle>().having((s) => s.form.amount, 'amount', 5.0),
            isA<TransactionIdle>().having((s) => s.form.amount, 'amount', 5.5),
          ],
        );
      });

      group('deleteAmount', () {
        blocTest<TransactionCubit, TransactionState>(
          'removes last character from buffer',
          build: () => cubit,
          act: (cubit) {
            cubit.appendAmount('1');
            cubit.appendAmount('2');
            cubit.appendAmount('3');
            cubit.deleteAmount();
          },
          expect: () => [
            isA<TransactionIdle>().having((s) => s.form.amount, 'amount', 1.0),
            isA<TransactionIdle>().having((s) => s.form.amount, 'amount', 12.0),
            isA<TransactionIdle>().having(
              (s) => s.form.amount,
              'amount',
              123.0,
            ),
            isA<TransactionIdle>().having((s) => s.form.amount, 'amount', 12.0),
          ],
        );

        blocTest<TransactionCubit, TransactionState>(
          build: () => cubit,
          'does nothing when buffer is empty',
          act: (cubit) => cubit.deleteAmount(),
        );

        blocTest<TransactionCubit, TransactionState>(
          'sets amount to 0 when last character is deleted',
          build: () => cubit,
          act: (cubit) {
            cubit.appendAmount('5');
            cubit.deleteAmount();
          },
          expect: () => [
            isA<TransactionIdle>().having((s) => s.form.amount, 'amount', 5.0),
            isA<TransactionIdle>().having((s) => s.form.amount, 'amount', 0.0),
          ],
        );
      });

      group('clearAmount', () {
        blocTest<TransactionCubit, TransactionState>(
          'clears buffer and sets amount to 0',
          build: () => cubit,
          act: (cubit) {
            cubit.appendAmount('1');
            cubit.appendAmount('0');
            cubit.appendAmount('0');
            cubit.clearAmount();
          },
          expect: () => [
            isA<TransactionIdle>().having((s) => s.form.amount, 'amount', 1.0),
            isA<TransactionIdle>().having((s) => s.form.amount, 'amount', 10.0),
            isA<TransactionIdle>().having(
              (s) => s.form.amount,
              'amount',
              100.0,
            ),
            isA<TransactionIdle>().having((s) => s.form.amount, 'amount', 0.0),
          ],
        );
      });

      group('applyAmount', () {
        test('does not change state (confirms current amount)', () {
          cubit.appendAmount('5');
          cubit.appendAmount('0');

          final stateBeforeApply = cubit.state;
          cubit.applyAmount();
          final stateAfterApply = cubit.state;

          expect(stateBeforeApply.form.amount, 50.0);
          expect(stateAfterApply.form.amount, 50.0);
        });
      });

      group('onKeyTap', () {
        blocTest<TransactionCubit, TransactionState>(
          'delegates to appendAmount for digit keys',
          build: () => cubit,
          act: (cubit) => cubit.onKeyTap('5'),
          expect: () => [
            isA<TransactionIdle>().having((s) => s.form.amount, 'amount', 5.0),
          ],
        );

        blocTest<TransactionCubit, TransactionState>(
          'delegates to clearAmount for AC key',
          build: () => cubit,
          act: (cubit) {
            cubit.appendAmount('5');
            cubit.onKeyTap('AC');
          },
          expect: () => [
            isA<TransactionIdle>().having((s) => s.form.amount, 'amount', 5.0),
            isA<TransactionIdle>().having((s) => s.form.amount, 'amount', 0.0),
          ],
        );

        blocTest<TransactionCubit, TransactionState>(
          'delegates to deleteAmount for DEL key',
          build: () => cubit,
          act: (cubit) {
            cubit.appendAmount('5');
            cubit.appendAmount('0');
            cubit.onKeyTap('DEL');
          },
          expect: () => [
            isA<TransactionIdle>().having((s) => s.form.amount, 'amount', 5.0),
            isA<TransactionIdle>().having((s) => s.form.amount, 'amount', 50.0),
            isA<TransactionIdle>().having((s) => s.form.amount, 'amount', 5.0),
          ],
        );

        test('delegates to applyAmount for checkmark key', () {
          cubit.appendAmount('5');

          final stateBeforeApply = cubit.state;
          cubit.onKeyTap('✓');
          final stateAfterApply = cubit.state;

          expect(stateBeforeApply.form.amount, 5.0);
          expect(stateAfterApply.form.amount, 5.0);
        });
      });
    });

    group('Date methods', () {
      group('selectDate', () {
        blocTest<TransactionCubit, TransactionState>(
          'updates date and formattedDate in form',
          build: () => cubit,
          act: (cubit) => cubit.selectDate(DateTime(2024, 1, 15)),
          expect: () => [
            isA<TransactionIdle>()
                .having((s) => s.form.date, 'date', DateTime(2024, 1, 15))
                .having(
                  (s) => s.form.formattedDate,
                  'formattedDate',
                  '15/01/2024',
                ),
          ],
        );
      });

      group('clearDate', () {
        blocTest<TransactionCubit, TransactionState>(
          'resets date to now and clears formattedDate',
          build: () => cubit,
          seed: () => TransactionIdle(
            form: TransactionFormDto(
              amount: 0.0,
              category: .other,
              date: DateTime(2024, 1, 15),
              formattedDate: '15/01/2024',
            ),
          ),
          act: (cubit) => cubit.clearDate(),
          expect: () => [
            isA<TransactionIdle>().having(
              (s) => s.form.formattedDate,
              'formattedDate',
              '',
            ),
          ],
        );
      });
    });

    group('Category methods', () {
      group('selectCategory', () {
        blocTest<TransactionCubit, TransactionState>(
          'updates category in form',
          build: () => cubit,
          act: (cubit) => cubit.selectCategory(.salary),
          expect: () => [
            isA<TransactionIdle>().having(
              (s) => s.form.category,
              'category',
              CategoryModel.salary,
            ),
          ],
        );

        blocTest<TransactionCubit, TransactionState>(
          'can change category multiple times',
          build: () => cubit,
          act: (cubit) {
            cubit.selectCategory(.salary);
            cubit.selectCategory(.food);
            cubit.selectCategory(.transport);
          },
          expect: () => [
            isA<TransactionIdle>().having(
              (s) => s.form.category,
              'category',
              CategoryModel.salary,
            ),
            isA<TransactionIdle>().having(
              (s) => s.form.category,
              'category',
              CategoryModel.food,
            ),
            isA<TransactionIdle>().having(
              (s) => s.form.category,
              'category',
              CategoryModel.transport,
            ),
          ],
        );
      });

      group('clearCategory', () {
        blocTest<TransactionCubit, TransactionState>(
          'resets category to CategoryModel.other',
          build: () => cubit,
          seed: () => TransactionIdle(
            form: TransactionFormDto(
              amount: 0.0,
              date: .now(),
              formattedDate: '',
              category: .salary,
            ),
          ),
          act: (cubit) => cubit.clearCategory(),
          expect: () => [
            isA<TransactionIdle>().having(
              (s) => s.form.category,
              'category',
              CategoryModel.other,
            ),
          ],
        );
      });
    });

    group('CRUD methods', () {
      group('clear', () {
        blocTest<TransactionCubit, TransactionState>(
          'resets to TransactionIdle with empty form',
          build: () => cubit,
          seed: () => TransactionSuccess(
            form: TransactionFormDto(
              amount: 100.0,
              category: .salary,
              date: DateTime(2024, 1, 15),
              formattedDate: '15/01/2024',
            ),
            transaction: transaction,
          ),
          act: (cubit) => cubit.clear(),
          expect: () => [
            isA<TransactionIdle>()
                .having((s) => s.form.amount, 'amount', 0.0)
                .having((s) => s.form.formattedDate, 'formattedDate', '')
                .having(
                  (s) => s.form.category,
                  'category',
                  CategoryModel.other,
                ),
          ],
        );

        blocTest<TransactionCubit, TransactionState>(
          'clears buffer when resetting',
          build: () => cubit,
          act: (cubit) {
            cubit.appendAmount('1');
            cubit.appendAmount('0');
            cubit.appendAmount('0');
            cubit.clear();
            cubit.appendAmount('5');
          },
          expect: () => [
            isA<TransactionIdle>().having((s) => s.form.amount, 'amount', 1.0),
            isA<TransactionIdle>().having((s) => s.form.amount, 'amount', 10.0),
            isA<TransactionIdle>().having(
              (s) => s.form.amount,
              'amount',
              100.0,
            ),
            isA<TransactionIdle>().having((s) => s.form.amount, 'amount', 0.0),
            isA<TransactionIdle>().having((s) => s.form.amount, 'amount', 5.0),
          ],
        );
      });

      group('find', () {
        blocTest<TransactionCubit, TransactionState>(
          'emits Loading then Success with transaction data',
          build: () => cubit,
          setUp: () {
            when(
              () => transactionRepository.findTransactionById(1),
            ).thenReturn(Right(transaction));
          },
          act: (cubit) => cubit.find(1),
          expect: () => [
            isA<TransactionLoading>(),
            isA<TransactionSuccess>()
                .having((s) => s.transaction, 'transaction', transaction)
                .having((s) => s.form.amount, 'amount', 100.50)
                .having(
                  (s) => s.form.category,
                  'category',
                  CategoryModel.salary,
                ),
          ],
          verify: (_) {
            verify(
              () => transactionRepository.findTransactionById(1),
            ).called(1);
          },
        );

        blocTest<TransactionCubit, TransactionState>(
          'emits Loading then Failure when repository fails',
          build: () => cubit,
          setUp: () {
            when(
              () => transactionRepository.findTransactionById(1),
            ).thenReturn(const Left('Transaction not found'));
          },
          act: (cubit) => cubit.find(1),
          expect: () => [
            isA<TransactionLoading>(),
            isA<TransactionFailure>().having(
              (s) => s.failure,
              'failure',
              'Transaction not found',
            ),
          ],
        );

        test('updates buffer with transaction amount for editing', () {
          when(
            () => transactionRepository.findTransactionById(1),
          ).thenReturn(Right(transaction));

          cubit.find(1);

          cubit.deleteAmount();
          expect(cubit.state.form.amount, 100.0);

          cubit.appendAmount('7');
          expect(cubit.state.form.amount, 100.7);
        });
      });

      group('save', () {
        blocTest<TransactionCubit, TransactionState>(
          'emits Loading then Success when save succeeds',
          build: () => cubit,
          setUp: () {
            when(
              () => transactionRepository.saveTransactionByModel(any()),
            ).thenReturn(const Right(null));
          },
          act: (cubit) => cubit.save(transaction),
          expect: () => [
            isA<TransactionLoading>(),
            isA<TransactionSuccess>().having(
              (s) => s.transaction,
              'transaction',
              isNull,
            ),
          ],
          verify: (_) {
            verify(
              () => transactionRepository.saveTransactionByModel(transaction),
            ).called(1);
          },
        );

        blocTest<TransactionCubit, TransactionState>(
          'emits Loading then Failure when save fails',
          build: () => cubit,
          setUp: () {
            when(
              () => transactionRepository.saveTransactionByModel(any()),
            ).thenReturn(const Left('Failed to save'));
          },
          act: (cubit) => cubit.save(transaction),
          expect: () => [
            isA<TransactionLoading>(),
            isA<TransactionFailure>().having(
              (s) => s.failure,
              'failure',
              'Failed to save',
            ),
          ],
        );

        blocTest<TransactionCubit, TransactionState>(
          'preserves form data through save operation',
          build: () => cubit,
          seed: () => TransactionIdle(
            form: TransactionFormDto(
              amount: 50.0,
              date: DateTime(2024, 1, 15),
              formattedDate: '15/01/2024',
              category: CategoryModel.food,
            ),
          ),
          setUp: () {
            when(
              () => transactionRepository.saveTransactionByModel(any()),
            ).thenReturn(const Right(null));
          },
          act: (cubit) => cubit.save(transaction),
          expect: () => [
            isA<TransactionLoading>().having(
              (s) => s.form.amount,
              'amount',
              50.0,
            ),
            isA<TransactionSuccess>().having(
              (s) => s.form.amount,
              'amount',
              50.0,
            ),
          ],
        );
      });

      group('delete', () {
        blocTest<TransactionCubit, TransactionState>(
          'emits Loading then Success when delete succeeds',
          build: () => cubit,
          setUp: () {
            when(
              () => transactionRepository.deleteTransactionById(1),
            ).thenReturn(const Right(null));
          },
          act: (cubit) => cubit.delete(1),
          expect: () => [isA<TransactionLoading>(), isA<TransactionSuccess>()],
          verify: (_) {
            verify(
              () => transactionRepository.deleteTransactionById(1),
            ).called(1);
          },
        );

        blocTest<TransactionCubit, TransactionState>(
          'emits Loading then Failure when delete fails',
          build: () => cubit,
          setUp: () {
            when(
              () => transactionRepository.deleteTransactionById(1),
            ).thenReturn(const Left('Failed to delete'));
          },
          act: (cubit) => cubit.delete(1),
          expect: () => [
            isA<TransactionLoading>(),
            isA<TransactionFailure>().having(
              (s) => s.failure,
              'failure',
              'Failed to delete',
            ),
          ],
        );
      });
    });

    group('State preservation', () {
      blocTest<TransactionCubit, TransactionState>(
        'preserves form data across multiple operations',
        build: () => cubit,
        act: (cubit) {
          cubit.appendAmount('5');
          cubit.appendAmount('0');
          cubit.selectCategory(.food);
          cubit.selectDate(DateTime(2024, 6, 15));
        },
        expect: () => [
          isA<TransactionIdle>()
              .having((s) => s.form.amount, 'amount', 5.0)
              .having((s) => s.form.category, 'category', CategoryModel.other),
          isA<TransactionIdle>()
              .having((s) => s.form.amount, 'amount', 50.0)
              .having((s) => s.form.category, 'category', CategoryModel.other),
          isA<TransactionIdle>()
              .having((s) => s.form.amount, 'amount', 50.0)
              .having((s) => s.form.category, 'category', CategoryModel.food),
          isA<TransactionIdle>()
              .having((s) => s.form.amount, 'amount', 50.0)
              .having((s) => s.form.category, 'category', CategoryModel.food)
              .having((s) => s.form.date, 'date', DateTime(2024, 6, 15))
              .having(
                (s) => s.form.formattedDate,
                'formattedDate',
                '15/06/2024',
              ),
        ],
      );

      blocTest<TransactionCubit, TransactionState>(
        'maintains state type when updating form',
        build: () => cubit,
        seed: () => TransactionSuccess(
          form: TransactionFormDto(
            amount: 100.0,
            category: .salary,
            date: DateTime(2024, 1, 15),
            formattedDate: '15/01/2024',
          ),
          transaction: transaction,
        ),
        act: (cubit) => cubit.selectCategory(CategoryModel.food),
        expect: () => [
          isA<TransactionSuccess>()
              .having((s) => s.form.category, 'category', CategoryModel.food)
              .having((s) => s.transaction, 'transaction', transaction),
        ],
      );

      blocTest<TransactionCubit, TransactionState>(
        'maintains failure message when updating form after failure',
        build: () => cubit,
        seed: () => TransactionFailure(
          form: TransactionFormDto(
            amount: 100.0,
            category: .salary,
            date: DateTime(2024, 1, 15),
            formattedDate: '15/01/2024',
          ),
          failure: 'Some error',
        ),
        act: (cubit) => cubit.selectCategory(CategoryModel.food),
        expect: () => [
          isA<TransactionFailure>()
              .having((s) => s.form.category, 'category', CategoryModel.food)
              .having((s) => s.failure, 'failure', 'Some error'),
        ],
      );
    });

    group('TransactionFormData', () {
      test('empty factory creates default values', () {
        final form = TransactionFormDto.empty();

        expect(form.amount, 0.0);
        expect(form.formattedDate, '');
        expect(form.category, CategoryModel.other);
      });

      test('copyWith creates new instance with updated values', () {
        final original = TransactionFormDto(
          amount: 100.0,
          category: .salary,
          date: DateTime(2024, 1, 15),
          formattedDate: '15/01/2024',
        );

        final updated = original.copyWith(amount: 200.0);

        expect(updated.amount, 200.0);
        expect(updated.date, original.date);
        expect(updated.category, original.category);
        expect(updated.formattedDate, original.formattedDate);
      });

      test('copyWith preserves values when no arguments passed', () {
        final original = TransactionFormDto(
          amount: 100.0,
          category: .salary,
          date: DateTime(2024, 1, 15),
          formattedDate: '15/01/2024',
        );

        final copy = original.copyWith();

        expect(copy.date, original.date);
        expect(copy.amount, original.amount);
        expect(copy.category, original.category);
        expect(copy.formattedDate, original.formattedDate);
      });

      test('equality works correctly', () {
        final date = DateTime(2024, 1, 15);
        final form1 = TransactionFormDto(
          date: date,
          amount: 100.0,
          category: .salary,
          formattedDate: '15/01/2024',
        );

        final form2 = TransactionFormDto(
          date: date,
          amount: 100.0,
          category: .salary,
          formattedDate: '15/01/2024',
        );

        expect(form1, form2);
      });

      test('inequality works correctly', () {
        final date = DateTime(2024, 1, 15);
        final form1 = TransactionFormDto(
          date: date,
          amount: 100.0,
          category: .salary,
          formattedDate: '15/01/2024',
        );

        final form2 = TransactionFormDto(
          date: date,
          amount: 200.0,
          category: .salary,
          formattedDate: '15/01/2024',
        );

        expect(form1, isNot(equals(form2)));
      });
    });

    group('Edge cases', () {
      blocTest<TransactionCubit, TransactionState>(
        'handles multiple decimal places correctly',
        build: () => cubit,
        act: (cubit) {
          cubit.appendAmount('1');
          cubit.appendAmount(',');
          cubit.appendAmount('2');
          cubit.appendAmount('3');
          cubit.appendAmount('4');
        },
        expect: () => [
          isA<TransactionIdle>().having((s) => s.form.amount, 'amount', 1.0),
          isA<TransactionIdle>().having((s) => s.form.amount, 'amount', 1.2),
          isA<TransactionIdle>().having((s) => s.form.amount, 'amount', 1.23),
          isA<TransactionIdle>().having((s) => s.form.amount, 'amount', 1.234),
        ],
      );

      blocTest<TransactionCubit, TransactionState>(
        'handles leading zeros correctly',
        build: () => cubit,
        act: (cubit) {
          cubit.appendAmount('0');
          cubit.appendAmount(',');
          cubit.appendAmount('5');
        },
        expect: () => [
          isA<TransactionIdle>().having((s) => s.form.amount, 'amount', 0.0),
          isA<TransactionIdle>().having((s) => s.form.amount, 'amount', 0.5),
        ],
      );

      blocTest<TransactionCubit, TransactionState>(
        'handles large numbers correctly',
        build: () => cubit,
        act: (cubit) {
          cubit.appendAmount('9');
          cubit.appendAmount('9');
          cubit.appendAmount('9');
          cubit.appendAmount('9');
          cubit.appendAmount('9');
          cubit.appendAmount('9');
        },
        expect: () => [
          isA<TransactionIdle>().having((s) => s.form.amount, 'amount', 9.0),
          isA<TransactionIdle>().having((s) => s.form.amount, 'amount', 99.0),
          isA<TransactionIdle>().having((s) => s.form.amount, 'amount', 999.0),
          isA<TransactionIdle>().having((s) => s.form.amount, 'amount', 9999.0),
          isA<TransactionIdle>().having(
            (s) => s.form.amount,
            'amount',
            99999.0,
          ),
          isA<TransactionIdle>().having(
            (s) => s.form.amount,
            'amount',
            999999.0,
          ),
        ],
      );
    });
  });
}
