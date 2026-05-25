import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';

import 'package:trocado/src/domain/services/interface_connectivity_service.dart';

final class ConnectivityService implements IConnectivityService {
  final Connectivity _connectivity;

  ConnectivityService({Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity();

  @override
  Future<bool> hasConnection() async {
    final results = await _connectivity.checkConnectivity();

    if (results.contains(ConnectivityResult.none)) return false;

    try {
      final lookup = await InternetAddress.lookup('google.com');
      return lookup.isNotEmpty && lookup.first.rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }
}
