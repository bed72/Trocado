import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:trocado/src/domain/services/money_service.dart';
import 'package:trocado/src/infrastructure/services/money_service.dart';
import 'package:trocado/src/domain/services/date_formatter_service.dart';
import 'package:trocado/src/domain/services/camera_permission_service.dart';
import 'package:trocado/src/infrastructure/services/date_formatter_service.dart';
import 'package:trocado/src/infrastructure/services/camera_permission_service.dart';

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
