import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:trocado/src/domain/services/money_service.dart';
import 'package:trocado/src/infrastructure/services/money_service.dart';

part 'services_provider.g.dart';

@Riverpod(keepAlive: true)
IMoneyService moneyService(Ref _) => MoneyService();

@Riverpod(keepAlive: true)
DateTime Function() now(Ref _) => DateTime.now;
