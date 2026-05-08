// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_purge_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ProfilePurgeNotifier)
final profilePurgeProvider = ProfilePurgeNotifierProvider._();

final class ProfilePurgeNotifierProvider
    extends $NotifierProvider<ProfilePurgeNotifier, ProfilePurgeState> {
  ProfilePurgeNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'profilePurgeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$profilePurgeNotifierHash();

  @$internal
  @override
  ProfilePurgeNotifier create() => ProfilePurgeNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProfilePurgeState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ProfilePurgeState>(value),
    );
  }
}

String _$profilePurgeNotifierHash() =>
    r'ef629bf77c686b43f683d11fd9b32b1aa7aa7f07';

abstract class _$ProfilePurgeNotifier extends $Notifier<ProfilePurgeState> {
  ProfilePurgeState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<ProfilePurgeState, ProfilePurgeState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ProfilePurgeState, ProfilePurgeState>,
              ProfilePurgeState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
