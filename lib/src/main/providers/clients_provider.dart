import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:trocado/app_route.dart';

import 'package:trocado/src/main/config/app_config.dart';
import 'package:trocado/src/main/providers/storage_provider.dart';

import 'package:trocado/src/infrastructure/clients/http/http_client.dart';
import 'package:trocado/src/infrastructure/clients/crash/crash_client.dart';
import 'package:trocado/src/infrastructure/clients/share/share_client.dart';
import 'package:trocado/src/infrastructure/clients/logger/logger_client.dart';
import 'package:trocado/src/infrastructure/clients/firebase/firebase_client.dart';
import 'package:trocado/src/infrastructure/clients/app_check/app_check_client.dart';
import 'package:trocado/src/infrastructure/clients/messaging/messaging_client.dart';
import 'package:trocado/src/infrastructure/clients/http/factories/dio_factory.dart';
import 'package:trocado/src/infrastructure/clients/notification/local_notification_client.dart';

import 'package:trocado/src/presentation/ui/authentication/sign_in/locations/sign_in_location.dart';

part 'clients_provider.g.dart';

@Riverpod(keepAlive: true)
IShareClient shareClient(Ref _) => ShareClient();

@Riverpod(keepAlive: true)
ICrashClient crashClient(Ref _) => CrashClient();

@Riverpod(keepAlive: true)
IFirebaseClient firebaseClient(Ref _) => FirebaseClient();

@Riverpod(keepAlive: true)
IAppCheckClient appCheckClient(Ref _) => AppCheckClient();

@Riverpod(keepAlive: true)
IMessagingClient messagingClient(Ref _) => MessagingClient();

@Riverpod(keepAlive: true)
ILocalNotificationClient localNotificationClient(Ref _) =>
    LocalNotificationClient(plugin: FlutterLocalNotificationsPlugin());

@Riverpod(keepAlive: true)
ILoggerClient loggerClient(Ref ref) =>
    LoggerClient(client: ref.watch(crashClientProvider));

@Riverpod(keepAlive: true)
IHttpClient httpClient(Ref ref) => HttpClient(dio: ref.watch(dioProvider));

@Riverpod(keepAlive: true)
Dio dio(Ref ref) => DioFactory.create(
  baseUrl: AppConfig.url,
  appCheckClient: ref.watch(appCheckClientProvider),
  dataSource: ref.watch(localTokenDataSourceProvider),
  onUnauthenticated: () {
    routerConfig.root();
    routerConfig.navigate(root: true, replace: true, to: SignInLocation());
  },
);
