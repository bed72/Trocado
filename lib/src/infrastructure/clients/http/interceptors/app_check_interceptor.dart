import 'package:dio/dio.dart';

import 'package:trocado/src/infrastructure/clients/app_check/app_check_client.dart';

final class AppCheckInterceptor extends Interceptor {
  final IAppCheckClient _client;

  AppCheckInterceptor({required this._client});

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      final token = await _client.getToken();
      if (token != null) options.headers['X-Firebase-AppCheck'] = token;
    } catch (_) {}

    handler.next(options);
  }
}
