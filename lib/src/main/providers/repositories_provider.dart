import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:trocado/src/main/providers/storage_provider.dart';
import 'package:trocado/src/main/providers/clients_provider.dart';
import 'package:trocado/src/main/providers/data_sources.provider.dart';

import 'package:trocado/src/data/repositories/user_repository.dart';
import 'package:trocado/src/data/repositories/budget_repository.dart';
import 'package:trocado/src/data/repositories/couple_repository.dart';
import 'package:trocado/src/data/repositories/expense_repository.dart';
import 'package:trocado/src/data/repositories/insights_repository.dart';
import 'package:trocado/src/data/repositories/notification_repository.dart';
import 'package:trocado/src/data/repositories/authentication_repository.dart';

import 'package:trocado/src/domain/repositories/interface_user_repository.dart';
import 'package:trocado/src/domain/repositories/interface_budget_repository.dart';
import 'package:trocado/src/domain/repositories/interface_couple_repository.dart';
import 'package:trocado/src/domain/repositories/interface_expense_repository.dart';
import 'package:trocado/src/domain/repositories/interface_insights_repository.dart';
import 'package:trocado/src/domain/repositories/interface_notification_repository.dart';
import 'package:trocado/src/domain/repositories/interface_authentication_repository.dart';

part 'repositories_provider.g.dart';

@Riverpod()
IAuthenticationRepository authenticationRepository(Ref ref) =>
    AuthenticationRepository(
      tokenDataSource: ref.watch(localTokenDataSourceProvider),
      notificationRepository: ref.watch(notificationRepositoryProvider),
      authenticationDataSource: ref.watch(
        remoteAuthenticationDataSourceProvider,
      ),
    );

@Riverpod()
IUserRepository userRepository(Ref ref) => UserRepository(
  userDataSource: ref.watch(remoteUserDataSourceProvider),
  tokenDataSource: ref.watch(localTokenDataSourceProvider),
);

@Riverpod()
INotificationRepository notificationRepository(Ref ref) =>
    NotificationRepository(
      dataSource: ref.watch(remoteNotificationDataSourceProvider),
    );

@Riverpod()
IBudgetRepository budgetRepository(Ref ref) =>
    BudgetRepository(dataSource: ref.watch(remoteBudgetDataSourceProvider));

@Riverpod()
ICoupleRepository coupleRepository(Ref ref) => CoupleRepository(
  client: ref.watch(shareClientProvider),
  dataSource: ref.watch(remoteCoupleDataSourceProvider),
);

@Riverpod()
IExpenseRepository expenseRepository(Ref ref) =>
    ExpenseRepository(dataSource: ref.watch(remoteExpenseDataSourceProvider));

@Riverpod()
IInsightsRepository insightsRepository(Ref ref) =>
    InsightsRepository(dataSource: ref.watch(remoteInsightsDataSourceProvider));
