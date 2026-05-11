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
    extends
        $AsyncNotifierProvider<ProfilePasswordNotifier, ProfilePasswordState> {
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
}

String _$profilePasswordNotifierHash() =>
    r'390b68e73794e108cd9cc4b7207006a9d277c389';

abstract class _$ProfilePasswordNotifier
    extends $AsyncNotifier<ProfilePasswordState> {
  FutureOr<ProfilePasswordState> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<ProfilePasswordState>, ProfilePasswordState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<ProfilePasswordState>,
                ProfilePasswordState
              >,
              AsyncValue<ProfilePasswordState>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
