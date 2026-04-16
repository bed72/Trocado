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
