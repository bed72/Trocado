// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'clients_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(loggerClient)
final loggerClientProvider = LoggerClientProvider._();

final class LoggerClientProvider
    extends $FunctionalProvider<ILoggerClient, ILoggerClient, ILoggerClient>
    with $Provider<ILoggerClient> {
  LoggerClientProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'loggerClientProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$loggerClientHash();

  @$internal
  @override
  $ProviderElement<ILoggerClient> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ILoggerClient create(Ref ref) {
    return loggerClient(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ILoggerClient value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ILoggerClient>(value),
    );
  }
}

String _$loggerClientHash() => r'7902ac4aa4ff597bc43fbb1c60899402b7598f8c';

@ProviderFor(httpClient)
final httpClientProvider = HttpClientProvider._();

final class HttpClientProvider
    extends $FunctionalProvider<IHttpClient, IHttpClient, IHttpClient>
    with $Provider<IHttpClient> {
  HttpClientProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'httpClientProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$httpClientHash();

  @$internal
  @override
  $ProviderElement<IHttpClient> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  IHttpClient create(Ref ref) {
    return httpClient(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(IHttpClient value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<IHttpClient>(value),
    );
  }
}

String _$httpClientHash() => r'35887c386298e00b9fcfae9b178572774197a3f6';

@ProviderFor(dio)
final dioProvider = DioProvider._();

final class DioProvider extends $FunctionalProvider<Dio, Dio, Dio>
    with $Provider<Dio> {
  DioProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dioProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dioHash();

  @$internal
  @override
  $ProviderElement<Dio> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Dio create(Ref ref) {
    return dio(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Dio value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Dio>(value),
    );
  }
}

String _$dioHash() => r'6d847db90ac9c4755ee6481d7af5562c88c449d3';
