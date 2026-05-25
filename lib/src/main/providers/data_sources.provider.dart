import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:trocado/src/main/providers/clients_provider.dart';

import 'package:trocado/src/infrastructure/datasources/remote/remote_user_data_source.dart';
import 'package:trocado/src/infrastructure/datasources/remote/remote_chat_data_source.dart';
import 'package:trocado/src/infrastructure/datasources/remote/remote_budget_data_source.dart';
import 'package:trocado/src/infrastructure/datasources/remote/remote_couple_data_source.dart';
import 'package:trocado/src/infrastructure/datasources/remote/remote_health_data_source.dart';
import 'package:trocado/src/infrastructure/datasources/remote/remote_expense_data_source.dart';
import 'package:trocado/src/infrastructure/datasources/remote/remote_insights_data_source.dart';
import 'package:trocado/src/infrastructure/datasources/remote/remote_notification_data_source.dart';
import 'package:trocado/src/infrastructure/datasources/remote/remote_authentication_data_source.dart';

part 'data_sources.provider.g.dart';

@Riverpod()
IRemoteChatDataSource remoteChatDataSource(Ref ref) =>
    RemoteChatDataSource(client: ref.watch(httpClientProvider));

@Riverpod()
IRemoteUserDataSource remoteUserDataSource(Ref ref) =>
    RemoteUserDataSource(client: ref.watch(httpClientProvider));

@Riverpod()
IRemoteBudgetDataSource remoteBudgetDataSource(Ref ref) =>
    RemoteBudgetDataSource(client: ref.watch(httpClientProvider));

@Riverpod()
IRemoteCoupleDataSource remoteCoupleDataSource(Ref ref) =>
    RemoteCoupleDataSource(client: ref.watch(httpClientProvider));

@Riverpod()
IRemoteHealthDataSource remoteHealthDataSource(Ref ref) =>
    RemoteHealthDataSource(client: ref.watch(httpClientProvider));

@Riverpod()
IRemoteExpenseDataSource remoteExpenseDataSource(Ref ref) =>
    RemoteExpenseDataSource(client: ref.watch(httpClientProvider));

@Riverpod()
IRemoteInsightsDataSource remoteInsightsDataSource(Ref ref) =>
    RemoteInsightsDataSource(client: ref.watch(httpClientProvider));

@Riverpod()
IRemoteAuthenticationDataSource remoteAuthenticationDataSource(Ref ref) =>
    RemoteAuthenticationDataSource(client: ref.watch(httpClientProvider));

@Riverpod()
IRemoteNotificationDataSource remoteNotificationDataSource(Ref ref) =>
    RemoteNotificationDataSource(
      httpClient: ref.watch(httpClientProvider),
      messagingClient: ref.watch(messagingClientProvider),
    );
