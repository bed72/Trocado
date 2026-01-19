import 'package:trocado/main.dart';

import 'package:trocado/modules/core/core.dart';
import 'package:trocado/modules/date/date.dart';
import 'package:trocado/modules/category/category.dart';
import 'package:trocado/modules/calculator/calculator.dart';
import 'package:trocado/modules/transaction/transaction.dart';

Future<void> ensureInitialized() async {
  clientProvider();
  resourceProvider();
  datasourceProvider();
  repositoryProvider();

  dateProvider();
  categoryProvider();
  calculatorProvider();
  transactionProvider();

  await _ensureInitialized();
}

Future<void> _ensureInitialized() async {
  await Future.wait([provider.allReady()]);
}
