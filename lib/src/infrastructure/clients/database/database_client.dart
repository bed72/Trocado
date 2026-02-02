import 'package:trocado/objectbox.g.dart';

import 'package:trocado/src/infrastructure/clients/logger/logger_client.dart';

abstract interface class IDatabaseClient {
  Store get store;

  void dispose();
  Future<void> ensureInitialized();
}

final class DatabaseClient implements IDatabaseClient {
  Admin? _admin;
  Store? _instance;

  final ILoggerClient _client;

  DatabaseClient({required ILoggerClient client}) : _client = client;

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

    _client.debug('[DATABSE] Opening store');

    _instance = await openStore();
    _startAdminIfAvailable();

    _client.debug('[DATABSE] Store initialized');
  }

  void _startAdminIfAvailable() {
    assert(() {
      if (Admin.isAvailable()) {
        _admin = Admin(store);
        _client.debug('[DATABASE] ObjectBox Admin started');
      }

      return true;
    }());
  }
}
