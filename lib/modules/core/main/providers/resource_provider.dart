import 'package:trocado/main.dart';

import 'package:trocado/modules/core/infrastructure/resources/loggers/logger.dart';
import 'package:trocado/modules/core/infrastructure/resources/formatters/money_formatter.dart';

void resourceProvider() {
  i
    ..registerFactory<ILogger>(Logger.new)
    ..registerFactory<IMoneyFormatter>(MoneyFormatter.new);
}
