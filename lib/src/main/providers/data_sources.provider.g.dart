// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'data_sources.provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

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

@ProviderFor(remoteAuthenticationDataSource)
final remoteAuthenticationDataSourceProvider =
    RemoteAuthenticationDataSourceProvider._();

final class RemoteAuthenticationDataSourceProvider
    extends
        $FunctionalProvider<
          IRemoteAuthenticationDataSource,
          IRemoteAuthenticationDataSource,
          IRemoteAuthenticationDataSource
        >
    with $Provider<IRemoteAuthenticationDataSource> {
  RemoteAuthenticationDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'remoteAuthenticationDataSourceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$remoteAuthenticationDataSourceHash();

  @$internal
  @override
  $ProviderElement<IRemoteAuthenticationDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  IRemoteAuthenticationDataSource create(Ref ref) {
    return remoteAuthenticationDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(IRemoteAuthenticationDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<IRemoteAuthenticationDataSource>(
        value,
      ),
    );
  }
}

String _$remoteAuthenticationDataSourceHash() =>
    r'e8ac2f5080ca4fc5fccab6e546157e2b4f69442c';
