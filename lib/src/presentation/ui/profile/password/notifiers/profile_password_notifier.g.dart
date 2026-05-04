// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_password_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ProfilePasswordNotifier)
final profilePasswordProvider = ProfilePasswordNotifierProvider._();

final class ProfilePasswordNotifierProvider
    extends $NotifierProvider<ProfilePasswordNotifier, ProfilePasswordState> {
  ProfilePasswordNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'profilePasswordProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$profilePasswordNotifierHash();

  @$internal
  @override
  ProfilePasswordNotifier create() => ProfilePasswordNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProfilePasswordState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ProfilePasswordState>(value),
    );
  }
}

String _$profilePasswordNotifierHash() =>
    r'7b5d7141fcfe67ecd3217f05474d8003fc6f8db2';

abstract class _$ProfilePasswordNotifier
    extends $Notifier<ProfilePasswordState> {
  ProfilePasswordState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<ProfilePasswordState, ProfilePasswordState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ProfilePasswordState, ProfilePasswordState>,
              ProfilePasswordState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
