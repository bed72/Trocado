// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_couple_card_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SettingsCoupleCardNotifier)
final settingsCoupleCardProvider = SettingsCoupleCardNotifierProvider._();

final class SettingsCoupleCardNotifierProvider
    extends
        $AsyncNotifierProvider<SettingsCoupleCardNotifier, CoupleCardState> {
  SettingsCoupleCardNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'settingsCoupleCardProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$settingsCoupleCardNotifierHash();

  @$internal
  @override
  SettingsCoupleCardNotifier create() => SettingsCoupleCardNotifier();
}

String _$settingsCoupleCardNotifierHash() =>
    r'd2bf2e6d936f922e1ac14024c2fe9759f7a6ce5b';

abstract class _$SettingsCoupleCardNotifier
    extends $AsyncNotifier<CoupleCardState> {
  FutureOr<CoupleCardState> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<CoupleCardState>, CoupleCardState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<CoupleCardState>, CoupleCardState>,
              AsyncValue<CoupleCardState>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
