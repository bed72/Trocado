// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_delete_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ProfileDeleteNotifier)
final profileDeleteProvider = ProfileDeleteNotifierProvider._();

final class ProfileDeleteNotifierProvider
    extends $NotifierProvider<ProfileDeleteNotifier, ProfileDeleteState> {
  ProfileDeleteNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'profileDeleteProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$profileDeleteNotifierHash();

  @$internal
  @override
  ProfileDeleteNotifier create() => ProfileDeleteNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProfileDeleteState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ProfileDeleteState>(value),
    );
  }
}

String _$profileDeleteNotifierHash() =>
    r'cd9e644ddb56bb4fe15192ba42974e3a6aa4fd18';

abstract class _$ProfileDeleteNotifier extends $Notifier<ProfileDeleteState> {
  ProfileDeleteState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<ProfileDeleteState, ProfileDeleteState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ProfileDeleteState, ProfileDeleteState>,
              ProfileDeleteState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
