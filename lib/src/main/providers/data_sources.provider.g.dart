// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'data_sources.provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(remoteUserDataSource)
final remoteUserDataSourceProvider = RemoteUserDataSourceProvider._();

final class RemoteUserDataSourceProvider
    extends
        $FunctionalProvider<
          IRemoteUserDataSource,
          IRemoteUserDataSource,
          IRemoteUserDataSource
        >
    with $Provider<IRemoteUserDataSource> {
  RemoteUserDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'remoteUserDataSourceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$remoteUserDataSourceHash();

  @$internal
  @override
  $ProviderElement<IRemoteUserDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  IRemoteUserDataSource create(Ref ref) {
    return remoteUserDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(IRemoteUserDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<IRemoteUserDataSource>(value),
    );
  }
}

String _$remoteUserDataSourceHash() =>
    r'8c43a0939a5a98f560c111373497de5db8710e4a';

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

@ProviderFor(remoteBudgetDataSource)
final remoteBudgetDataSourceProvider = RemoteBudgetDataSourceProvider._();

final class RemoteBudgetDataSourceProvider
    extends
        $FunctionalProvider<
          IRemoteBudgetDataSource,
          IRemoteBudgetDataSource,
          IRemoteBudgetDataSource
        >
    with $Provider<IRemoteBudgetDataSource> {
  RemoteBudgetDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'remoteBudgetDataSourceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$remoteBudgetDataSourceHash();

  @$internal
  @override
  $ProviderElement<IRemoteBudgetDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  IRemoteBudgetDataSource create(Ref ref) {
    return remoteBudgetDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(IRemoteBudgetDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<IRemoteBudgetDataSource>(value),
    );
  }
}

String _$remoteBudgetDataSourceHash() =>
    r'90959fbe283f3f237ba29a74143c291de7e63fe8';

@ProviderFor(remoteExpenseDataSource)
final remoteExpenseDataSourceProvider = RemoteExpenseDataSourceProvider._();

final class RemoteExpenseDataSourceProvider
    extends
        $FunctionalProvider<
          IRemoteExpenseDataSource,
          IRemoteExpenseDataSource,
          IRemoteExpenseDataSource
        >
    with $Provider<IRemoteExpenseDataSource> {
  RemoteExpenseDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'remoteExpenseDataSourceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$remoteExpenseDataSourceHash();

  @$internal
  @override
  $ProviderElement<IRemoteExpenseDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  IRemoteExpenseDataSource create(Ref ref) {
    return remoteExpenseDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(IRemoteExpenseDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<IRemoteExpenseDataSource>(value),
    );
  }
}

String _$remoteExpenseDataSourceHash() =>
    r'5b0af3310189d5e554d5b75178d1aebba6c1dfda';
