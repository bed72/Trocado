import 'package:mocktail/mocktail.dart';

import 'package:trocado/src/data/mapper/expense_mapper.dart';

import 'package:trocado/src/data/datasources/interface_expense_data_source.dart';

import 'package:trocado/src/domain/services/interface_money_repository.dart';

import 'package:trocado/src/domain/repositories/interface_expense_repository.dart';

final class MockMoneyRepository extends Mock implements IMoneyService {}

final class MockTransactionToModelMapper extends Mock
    implements ExpenseEntityToModelMapper {}

final class MockTransactionToEntityMapper extends Mock
    implements ExpenseModelToEntityMapper {}

final class MockTransactionDataSource extends Mock
    implements IExpenseDataSource {}

final class MockTransactionRepository extends Mock
    implements IExpenseRepository {}

final class MockPresentationToModelMapper extends Mock
    implements ExpensePresentationToModelMapper {}
