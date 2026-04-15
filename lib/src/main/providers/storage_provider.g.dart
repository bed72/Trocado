// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'storage_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

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

@ProviderFor(localTokenDataSource)
final localTokenDataSourceProvider = LocalTokenDataSourceProvider._();

final class LocalTokenDataSourceProvider
    extends
        $FunctionalProvider<
          ILocalTokenDataSource,
          ILocalTokenDataSource,
          ILocalTokenDataSource
        >
    with $Provider<ILocalTokenDataSource> {
  LocalTokenDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'localTokenDataSourceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$localTokenDataSourceHash();

  @$internal
  @override
  $ProviderElement<ILocalTokenDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ILocalTokenDataSource create(Ref ref) {
    return localTokenDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ILocalTokenDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ILocalTokenDataSource>(value),
    );
  }
}

String _$localTokenDataSourceHash() =>
    r'e4bd19dcdfc1c778e7c6ddc397c19397d271c1ea';
