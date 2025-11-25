import 'package:provider/provider.dart';

import 'package:trocado/modules/core/infrastructure/resources/loggers/logger.dart';

final resourceProvider = [Provider<ILogger>(create: (_) => Logger())];
