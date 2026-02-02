import 'package:mocktail/mocktail.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/src/domain/either/either.dart';
import 'package:trocado/src/domain/models/transaction_model.dart';

import 'package:trocado/src/presentation/cubits/transaction/transaction_cubit.dart';

import 'package:trocado/src/domain/repositories/interface_money_repository.dart';
import 'package:trocado/src/domain/repositories/interface_transaction_repository.dart';

import '../../../mocks/mocks.dart';

void main() {
  late TransactionCubit cubit;
  late IMoneyRepository moneyRepository;
  late ITransactionRepository transactionRepository;

  setUp(() {
    moneyRepository = MockMoneyRepository();
    transactionRepository = MockTransactionRepository();

    cubit = TransactionCubit(
      formatter: moneyRepository,
      repository: transactionRepository,
    );
  });

  tearDown(() {
    cubit.close();
  });

  group('TransactionCubit', () {
    group('initial state', () {
      test('should be TransactionIdle', () {
        expect(cubit.state, isA<TransactionIdle>());
      });
    });

    group('find', () {
      final transaction = TransactionModel(
        id: 1,
        date: 123,
        amount: 10.0,
        type: 'expense',
        category: 'food',
        description: 'Lunch',
      );

      blocTest<TransactionCubit, TransactionState>(
        'emits [TransactionLoading, TransactionSuccess] when find succeeds',
        act: (cubit) => cubit.find(1),
        build: () {
          when(
            () => transactionRepository.findTransactionById(1),
          ).thenReturn(Right(transaction));
          return cubit;
        },
        expect: () => [
          TransactionLoading(),
          TransactionSuccess(transaction: transaction),
        ],
        verify: (_) {
          verify(() => transactionRepository.findTransactionById(1)).called(1);
        },
      );

      blocTest<TransactionCubit, TransactionState>(
        'emits [TransactionLoading, TransactionFailure] when find fails',
        act: (cubit) => cubit.find(1),
        build: () {
          when(
            () => transactionRepository.findTransactionById(1),
          ).thenReturn(const Left('Failure'));
          return cubit;
        },
        expect: () => [
          TransactionLoading(),
          TransactionFailure(failure: 'Failure'),
        ],
      );
    });

    group('delete', () {
      blocTest<TransactionCubit, TransactionState>(
        'emits [TransactionLoading, TransactionSuccess] when delete succeeds',
        act: (cubit) => cubit.delete(1),
        build: () {
          when(
            () => transactionRepository.deleteTransactionById(1),
          ).thenReturn(Right<String, void>(null));
          return cubit;
        },
        expect: () => [TransactionLoading(), TransactionSuccess()],
        verify: (_) {
          verify(
            () => transactionRepository.deleteTransactionById(1),
          ).called(1);
        },
      );

      blocTest<TransactionCubit, TransactionState>(
        'emits [TransactionLoading, TransactionFailure] when delete fails',
        act: (cubit) => cubit.delete(1),
        build: () {
          when(
            () => transactionRepository.deleteTransactionById(1),
          ).thenReturn(const Left('Failure'));
          return cubit;
        },
        expect: () => [
          TransactionLoading(),
          TransactionFailure(failure: 'Failure'),
        ],
      );
    });
  });
}
