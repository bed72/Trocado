// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'clients_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

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

String _$dioHash() => r'b3d9faf84ba5b2d59788ef4eef6c890af216168f';

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

@ProviderFor(storageClient)
final storageClientProvider = StorageClientProvider._();

final class StorageClientProvider
    extends $FunctionalProvider<IStorageClient, IStorageClient, IStorageClient>
    with $Provider<IStorageClient> {
  StorageClientProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'storageClientProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$storageClientHash();

  @$internal
  @override
  $ProviderElement<IStorageClient> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  IStorageClient create(Ref ref) {
    return storageClient(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(IStorageClient value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<IStorageClient>(value),
    );
  }
}

String _$storageClientHash() => r'4dfdbdf68f1668495a6836c3ed672d6fc8ce296a';
