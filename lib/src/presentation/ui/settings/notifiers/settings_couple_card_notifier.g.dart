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
    r'3db5cecf956f58b9e9e801c8ca59020858574592';

abstract class _$SettingsCoupleCardNotifier
    extends $AsyncNotifier<CoupleCardState> {
  FutureOr<CoupleCardState> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<CoupleCardState>, CoupleCardState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<CoupleCardState>, CoupleCardState>,
              AsyncValue<CoupleCardState>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
