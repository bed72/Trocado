import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:trocado/src/application/services/money_service.dart';

part 'services_provider.g.dart';

@Riverpod(keepAlive: true)
IMoneyService moneyService(Ref _) => MoneyService();
