import 'package:talker_riverpod_logger/talker_riverpod_logger_observer.dart';
import 'package:talker_riverpod_logger/talker_riverpod_logger_settings.dart';
import 'package:trocado/src/infrastructure/clients/logger/logger_client.dart';

final stateObserver = TalkerRiverpodObserver(
  talker: loggerClient,
  settings: const TalkerRiverpodLoggerSettings(
    enabled: true,
    printStateFullData: false,
    printProviderAdded: true,
    printProviderFailed: true,
    printProviderUpdated: true,
    printProviderDisposed: true,
  ),
);
