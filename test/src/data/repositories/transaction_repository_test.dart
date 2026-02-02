import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/src/domain/either/either.dart';

import 'package:trocado/src/data/mapper/transaction_to_model_mapper.dart';
import 'package:trocado/src/data/mapper/transaction_to_entity_mapper.dart';
import 'package:trocado/src/data/repositories/transaction_repository.dart';

import 'package:trocado/src/domain/repositories/interface_transaction_repository.dart';

import 'package:trocado/src/infrastructure/database/entities/transaction_entity.dart';
import 'package:trocado/src/infrastructure/datasources/local/transaction_local_datasource.dart';

import '../../../mocks/mocks.dart';

void main() {
  late ITransactionRepository repository;
  late ITransactionLocalDatasource datasource;
  late TransactionToModelMapper toModelMapper;
  late TransactionToEntityMapper toEntityMapper;

  setUp(() {
    datasource = MockTransactionLocalDatasource();
    toModelMapper = MockTransactionToModelMapper();
    toEntityMapper = MockTransactionToEntityMapper();

    repository = TransactionRepository(
      datasource: datasource,
      toModelMapper: toModelMapper,
      toEntityMapper: toEntityMapper,
    );

    registerFallbackValue(
      TransactionEntity(
        date: 0,
        amount: 0,
        type: 'type',
        category: 'category',
        description: 'description',
        observation: 'observation',
      ),
    );
  });

  group('TransactionRepository', () {
    test('should return failure when datasource returns error', () {
      when(() => datasource.find(99)).thenReturn(const Left('Not found'));

      final data = repository.find(99);

      expect(data.isLeft, true);
    });

    group('delete', () {
      test('should delegate delete to datasource', () {
        when(() => datasource.delete(1)).thenReturn(const Right(null));

        final data = repository.delete(1);

        expect(data.isRight, true);
        verify(() => datasource.delete(1)).called(1);
      });

      test('should return failure when datasource returns error on delete', () {
        when(() => datasource.delete(1)).thenReturn(const Left('Delete error'));

        final data = repository.delete(1);

        expect(data.isLeft, true);
      });
    });
  });
}
