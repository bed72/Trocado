// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'services_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(now)
final nowProvider = NowProvider._();

final class NowProvider
    extends
        $FunctionalProvider<
          DateTime Function(),
          DateTime Function(),
          DateTime Function()
        >
    with $Provider<DateTime Function()> {
  NowProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'nowProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$nowHash();

  @$internal
  @override
  $ProviderElement<DateTime Function()> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  DateTime Function() create(Ref ref) {
    return now(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DateTime Function() value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DateTime Function()>(value),
    );
  }
}

String _$nowHash() => r'5f40f7a4b9a833d331d8ab27c8048d81f2a494d1';

@ProviderFor(moneyService)
final moneyServiceProvider = MoneyServiceProvider._();

final class MoneyServiceProvider
    extends $FunctionalProvider<IMoneyService, IMoneyService, IMoneyService>
    with $Provider<IMoneyService> {
  MoneyServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'moneyServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$moneyServiceHash();

  @$internal
  @override
  $ProviderElement<IMoneyService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  IMoneyService create(Ref ref) {
    return moneyService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(IMoneyService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<IMoneyService>(value),
    );
  }
}

String _$moneyServiceHash() => r'7693e61bc4f7a5ae79ae2ca17caed59676cebda3';

@ProviderFor(dateFormatterService)
final dateFormatterServiceProvider = DateFormatterServiceProvider._();

final class DateFormatterServiceProvider
    extends
        $FunctionalProvider<
          IDateFormatterService,
          IDateFormatterService,
          IDateFormatterService
        >
    with $Provider<IDateFormatterService> {
  DateFormatterServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dateFormatterServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dateFormatterServiceHash();

  @$internal
  @override
  $ProviderElement<IDateFormatterService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  IDateFormatterService create(Ref ref) {
    return dateFormatterService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(IDateFormatterService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<IDateFormatterService>(value),
    );
  }
}

String _$dateFormatterServiceHash() =>
    r'0bddecd5453ed6ae3c700f5fba8b781e7a4f9d7d';

@ProviderFor(cameraPermissionService)
final cameraPermissionServiceProvider = CameraPermissionServiceProvider._();

final class CameraPermissionServiceProvider
    extends
        $FunctionalProvider<
          ICameraPermissionService,
          ICameraPermissionService,
          ICameraPermissionService
        >
    with $Provider<ICameraPermissionService> {
  CameraPermissionServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cameraPermissionServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cameraPermissionServiceHash();

  @$internal
  @override
  $ProviderElement<ICameraPermissionService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ICameraPermissionService create(Ref ref) {
    return cameraPermissionService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ICameraPermissionService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ICameraPermissionService>(value),
    );
  }
}

String _$cameraPermissionServiceHash() =>
    r'dd64986b0a1beaf35decbdb7a5045ed1d68e3038';
