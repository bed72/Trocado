import 'package:dio/dio.dart';
import 'package:mocktail/mocktail.dart';

import 'package:trocado/src/domain/services/money_service.dart';
import 'package:trocado/src/domain/services/date_formatter_service.dart';
import 'package:trocado/src/domain/services/quick_action_service.dart';
import 'package:trocado/src/domain/services/camera_permission_service.dart';
import 'package:trocado/src/domain/services/interface_connectivity_service.dart';

import 'package:trocado/src/domain/repositories/interface_user_repository.dart';
import 'package:trocado/src/domain/repositories/interface_theme_repository.dart';
import 'package:trocado/src/domain/repositories/interface_budget_repository.dart';
import 'package:trocado/src/domain/repositories/interface_couple_repository.dart';
import 'package:trocado/src/domain/repositories/interface_health_repository.dart';
import 'package:trocado/src/domain/repositories/interface_expense_repository.dart';
import 'package:trocado/src/domain/repositories/interface_insights_repository.dart';
import 'package:trocado/src/domain/repositories/interface_notification_repository.dart';
import 'package:trocado/src/domain/repositories/interface_authentication_repository.dart';

import 'package:trocado/src/infrastructure/clients/http/http_client.dart';
import 'package:trocado/src/infrastructure/clients/share/share_client.dart';
import 'package:trocado/src/infrastructure/clients/logger/logger_client.dart';
import 'package:trocado/src/infrastructure/clients/storage/storage_client.dart';
import 'package:trocado/src/infrastructure/clients/app_check/app_check_client.dart';
import 'package:trocado/src/infrastructure/clients/messaging/messaging_client.dart';
import 'package:trocado/src/infrastructure/datasources/local/local_theme_data_source.dart';
import 'package:trocado/src/infrastructure/datasources/local/local_token_data_source.dart';
import 'package:trocado/src/infrastructure/datasources/remote/remote_couple_data_source.dart';
import 'package:trocado/src/infrastructure/datasources/remote/remote_notification_data_source.dart';

final class MockDio extends Mock implements Dio {}

final class MockHttpClient extends Mock implements IHttpClient {}

final class MockShareClient extends Mock implements IShareClient {}

final class MockLoggerClient extends Mock implements ILoggerClient {}

final class MockMoneyService extends Mock implements IMoneyService {}

final class MockStorageClient extends Mock implements IStorageClient {}

final class MockAppCheckClient extends Mock implements IAppCheckClient {}

final class MockUserRepository extends Mock implements IUserRepository {}

final class MockThemeRepository extends Mock implements IThemeRepository {}

final class MockMessagingClient extends Mock implements IMessagingClient {}

final class MockCoupleRepository extends Mock implements ICoupleRepository {}

final class MockBudgetRepository extends Mock implements IBudgetRepository {}

final class MockHealthRepository extends Mock implements IHealthRepository {}

final class MockHttpClientAdapter extends Mock implements HttpClientAdapter {}

final class MockExpenseRepository extends Mock implements IExpenseRepository {}

final class MockTokenDataSource extends Mock implements ILocalTokenDataSource {}

final class MockInsightsRepository extends Mock
    implements IInsightsRepository {}

final class MockDateFormatterService extends Mock
    implements IDateFormatterService {}

final class MockLocalThemeDataSource extends Mock
    implements ILocalThemeDataSource {}

final class MockRemoteCoupleDataSource extends Mock
    implements IRemoteCoupleDataSource {}

final class MockNotificationRepository extends Mock
    implements INotificationRepository {}

final class MockCameraPermissionService extends Mock
    implements ICameraPermissionService {}

final class MockQuickActionService extends Mock
    implements IQuickActionService {}

final class MockConnectivityService extends Mock
    implements IConnectivityService {}

final class MockAuthenticationRepository extends Mock
    implements IAuthenticationRepository {}

final class MockRemoteNotificationDataSource extends Mock
    implements IRemoteNotificationDataSource {}
