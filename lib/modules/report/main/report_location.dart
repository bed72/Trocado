import 'package:duck_router/duck_router.dart';

import 'package:trocado/modules/core/core.dart';
import 'package:trocado/modules/report/presentation/screens/report_screen.dart';

final class ReportLocation extends Location {
  @override
  String get path => RoutesConstant.report.path;

  @override
  LocationBuilder? get builder =>
      (_) => ReportScreen();
}
