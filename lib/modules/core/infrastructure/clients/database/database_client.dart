import 'package:trocado/modules/core/infrastructure/resources/loggers/logger.dart';

import 'package:trocado/objectbox.g.dart';

abstract interface class IDatabaseClient {
  Store get store;

  void dispose();
  Future<void> ensureInitialized();
}

final class DatabaseClient implements IDatabaseClient {
  Admin? _admin;
  Store? _instance;

  final ILogger _logger;

  DatabaseClient({required ILogger logger}) : _logger = logger;

  @override
  Store get store {
    final store = _instance;

    if (store == null) throw Exception('Database not initialized.');

    return store;
  }

  @override
  void dispose() {
    _admin?.close();
    _instance?.close();
  }

  @override
  Future<void> ensureInitialized() async {
    if (_instance != null) return;

    _logger.debug('[DATABSE] Opening store');

    _instance = await openStore();
    _startAdminIfAvailable();

    _logger.debug('[DATABSE] Store initialized');
  }

  void _startAdminIfAvailable() {
    assert(() {
      if (Admin.isAvailable()) {
        _admin = Admin(store);
        _logger.debug('[DATABASE] ObjectBox Admin started');
      }

      return true;
    }());
  }
}
