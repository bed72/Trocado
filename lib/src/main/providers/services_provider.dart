import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:trocado/src/domain/services/interface_money_service.dart';
import 'package:trocado/src/domain/services/interface_quick_action_service.dart';
import 'package:trocado/src/domain/services/interface_date_formatter_service.dart';
import 'package:trocado/src/domain/services/interface_camera_permission_service.dart';
import 'package:trocado/src/domain/services/interface_connectivity_service.dart';

import 'package:trocado/src/infrastructure/services/money_service.dart';
import 'package:trocado/src/infrastructure/services/quick_action_service.dart';
import 'package:trocado/src/infrastructure/services/date_formatter_service.dart';
import 'package:trocado/src/infrastructure/services/camera_permission_service.dart';
import 'package:trocado/src/infrastructure/services/connectivity_service.dart';

part 'services_provider.g.dart';

@Riverpod(keepAlive: true)
DateTime Function() now(Ref _) => DateTime.now;

@Riverpod(keepAlive: true)
IMoneyService moneyService(Ref _) => MoneyService();

@Riverpod(keepAlive: true)
IDateFormatterService dateFormatterService(Ref ref) =>
    DateFormatterService(now: ref.watch(nowProvider));

@Riverpod(keepAlive: true)
ICameraPermissionService cameraPermissionService(Ref _) =>
    CameraPermissionService();

@Riverpod(keepAlive: true)
IQuickActionService quickActionService(Ref _) => QuickActionService();

@Riverpod()
IConnectivityService connectivityService(Ref _) => ConnectivityService();
