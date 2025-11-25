import 'package:flutter/material.dart';
import 'package:duck_router/duck_router.dart';

import 'package:trocado/modules/core/core.dart';

final class TransactionLocation extends Location {
  @override
  String get path => RoutesConstant.transaction.path;

  @override
  LocationBuilder? get builder =>
      (_) => const SizedBox.shrink();
}
