import 'package:mocktail/mocktail.dart';

import 'package:trocado/src/data/mapper/budget_mapper.dart';
import 'package:trocado/src/data/mapper/expense_mapper.dart';

import 'package:trocado/src/data/datasources/interface_budget_data_source.dart';
import 'package:trocado/src/data/datasources/interface_expense_data_source.dart';

import 'package:trocado/src/presentation/mapper/expense_presentation_mapper.dart';

import 'package:trocado/src/domain/repositories/interface_budget_repository.dart';
import 'package:trocado/src/domain/repositories/interface_expense_repository.dart';

import 'package:trocado/src/application/services/money_service.dart';
import 'package:trocado/src/application/use_cases/get_budget_summary_use_case.dart';

// Services
final class MockMoneyService extends Mock implements IMoneyService {}

// Expense Mappers
final class MockExpenseEntityToModelMapper extends Mock
    implements ExpenseEntityToModelMapper {}

final class MockExpenseModelToEntityMapper extends Mock
    implements ExpenseModelToEntityMapper {}

final class MockExpenseModelToPresentationMapper extends Mock
    implements ExpenseModelToPresentationMapper {}

final class MockExpenseStateToModelMapper extends Mock
    implements ExpenseStateToModelMapper {}

// Budget Mappers
final class MockBudgetEntityToModelMapper extends Mock
    implements BudgetEntityToModelMapper {}

final class MockBudgetModelToEntityMapper extends Mock
    implements BudgetModelToEntityMapper {}

// Data Sources
final class MockExpenseDataSource extends Mock implements IExpenseDataSource {}

final class MockBudgetDataSource extends Mock implements IBudgetDataSource {}

// Repositories
final class MockExpenseRepository extends Mock implements IExpenseRepository {}

final class MockBudgetRepository extends Mock implements IBudgetRepository {}

// Use Cases
final class MockGetBudgetSummary extends Mock
    implements GetBudgetSummaryUseCase {}
