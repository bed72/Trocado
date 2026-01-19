import 'package:mocktail/mocktail.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/modules/core/domain/either/either.dart';

import 'package:trocado/modules/transaction/data/dtos/transaction_dto.dart';

import 'package:trocado/modules/transaction/presentation/cubits/transaction_cubit.dart';

import 'package:trocado/modules/transaction/domain/models/transaction_model.dart';
import 'package:trocado/modules/transaction/domain/repositories/interface_transaction_repository.dart';

import '../../mocks/mocks.dart';

void main() {
  late TransactionCubit cubit;
  late ITransactionRepository repository;

  setUp(() {
    repository = MockTransactionRepository();
    cubit = TransactionCubit(repository: repository);
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
          when(() => repository.find(1)).thenReturn(Right(transaction));
          return cubit;
        },
        expect: () => [
          const TransactionLoading(),
          TransactionSuccess(transaction: transaction),
        ],
        verify: (_) {
          verify(() => repository.find(1)).called(1);
        },
      );

      blocTest<TransactionCubit, TransactionState>(
        'emits [TransactionLoading, TransactionFailure] when find fails',
        act: (cubit) => cubit.find(1),
        build: () {
          when(() => repository.find(1)).thenReturn(const Left('Failure'));
          return cubit;
        },
        expect: () => [
          const TransactionLoading(),
          const TransactionFailure(failure: 'Failure'),
        ],
      );
    });

    group('save', () {
      final dto = TransactionDto.empty();

      blocTest<TransactionCubit, TransactionState>(
        act: (cubit) => cubit.save(dto),
        'emits [TransactionLoading, TransactionSuccess] when save succeeds',
        build: () {
          when(
            () => repository.save(dto),
          ).thenReturn(Right<String, void>(null));
          return cubit;
        },
        expect: () => [const TransactionLoading(), const TransactionSuccess()],
        verify: (_) {
          verify(() => repository.save(dto)).called(1);
        },
      );

      blocTest<TransactionCubit, TransactionState>(
        'emits [TransactionLoading, TransactionFailure] when save fails',
        act: (cubit) => cubit.save(dto),
        build: () {
          when(() => repository.save(dto)).thenReturn(const Left('Failure'));
          return cubit;
        },
        expect: () => [
          const TransactionLoading(),
          const TransactionFailure(failure: 'Failure'),
        ],
      );
    });

    group('delete', () {
      blocTest<TransactionCubit, TransactionState>(
        'emits [TransactionLoading, TransactionSuccess] when delete succeeds',
        act: (cubit) => cubit.delete(1),
        build: () {
          when(
            () => repository.delete(1),
          ).thenReturn(Right<String, void>(null));
          return cubit;
        },
        expect: () => [const TransactionLoading(), const TransactionSuccess()],
        verify: (_) {
          verify(() => repository.delete(1)).called(1);
        },
      );

      blocTest<TransactionCubit, TransactionState>(
        'emits [TransactionLoading, TransactionFailure] when delete fails',
        act: (cubit) => cubit.delete(1),
        build: () {
          when(() => repository.delete(1)).thenReturn(const Left('Failure'));
          return cubit;
        },
        expect: () => [
          const TransactionLoading(),
          const TransactionFailure(failure: 'Failure'),
        ],
      );
    });
  });
}
