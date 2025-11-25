import 'package:appwrite/appwrite.dart';

abstract interface class IExternalClient {
  Client get client;
  Account get account;
  Databases get databases;
}

final class ExternalClient implements IExternalClient {
  @override
  Client get client => Client()
    ..setEndpoint('http://192.168.1.8/v1')
    ..setProject('68eaa0bd0016aa5a8dc5')
    ..setSelfSigned();

  @override
  Account get account => Account(client);

  @override
  Databases get databases => Databases(client);
}
