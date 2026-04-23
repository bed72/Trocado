// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'services_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

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
