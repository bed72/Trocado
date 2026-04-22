import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:trocado/src/main/providers/storage_provider.dart';
import 'package:trocado/src/main/providers/data_sources.provider.dart';

import 'package:trocado/src/data/repositories/user_repository.dart';
import 'package:trocado/src/data/repositories/budget_repository.dart';
import 'package:trocado/src/data/repositories/expense_repository.dart';
import 'package:trocado/src/data/repositories/insights_repository.dart';
import 'package:trocado/src/data/repositories/authentication_repository.dart';

import 'package:trocado/src/domain/repositories/interface_user_repository.dart';
import 'package:trocado/src/domain/repositories/interface_budget_repository.dart';
import 'package:trocado/src/domain/repositories/interface_expense_repository.dart';
import 'package:trocado/src/domain/repositories/interface_insights_repository.dart';
import 'package:trocado/src/domain/repositories/interface_authentication_repository.dart';

part 'repositories_provider.g.dart';

@Riverpod()
IAuthenticationRepository authenticationRepository(Ref ref) =>
    AuthenticationRepository(
      tokenDataSource: ref.watch(localTokenDataSourceProvider),
      authenticationDataSource: ref.watch(
        remoteAuthenticationDataSourceProvider,
      ),
    );

@Riverpod()
IUserRepository userRepository(Ref ref) =>
    UserRepository(dataSource: ref.watch(remoteUserDataSourceProvider));

@Riverpod()
IBudgetRepository budgetRepository(Ref ref) =>
    BudgetRepository(dataSource: ref.watch(remoteBudgetDataSourceProvider));

@Riverpod()
IExpenseRepository expenseRepository(Ref ref) =>
    ExpenseRepository(dataSource: ref.watch(remoteExpenseDataSourceProvider));

@Riverpod()
IInsightsRepository insightsRepository(Ref ref) =>
    InsightsRepository(dataSource: ref.watch(remoteInsightsDataSourceProvider));
