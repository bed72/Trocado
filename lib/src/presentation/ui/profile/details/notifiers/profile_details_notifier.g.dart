// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_details_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ProfileDetailsNotifier)
final profileDetailsProvider = ProfileDetailsNotifierProvider._();

final class ProfileDetailsNotifierProvider
    extends $NotifierProvider<ProfileDetailsNotifier, ProfileDetailsState> {
  ProfileDetailsNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'profileDetailsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$profileDetailsNotifierHash();

  @$internal
  @override
  ProfileDetailsNotifier create() => ProfileDetailsNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProfileDetailsState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ProfileDetailsState>(value),
    );
  }
}

String _$profileDetailsNotifierHash() =>
    r'd3ff8fa4512d72d73286f72090456219d04c8cf3';

abstract class _$ProfileDetailsNotifier extends $Notifier<ProfileDetailsState> {
  ProfileDetailsState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<ProfileDetailsState, ProfileDetailsState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ProfileDetailsState, ProfileDetailsState>,
              ProfileDetailsState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
