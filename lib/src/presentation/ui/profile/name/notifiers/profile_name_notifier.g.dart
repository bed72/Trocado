// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_name_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ProfileNameNotifier)
final profileNameProvider = ProfileNameNotifierProvider._();

final class ProfileNameNotifierProvider
    extends $AsyncNotifierProvider<ProfileNameNotifier, ProfileNameState> {
  ProfileNameNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'profileNameProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$profileNameNotifierHash();

  @$internal
  @override
  ProfileNameNotifier create() => ProfileNameNotifier();
}

String _$profileNameNotifierHash() =>
    r'0f8a560ac6f83d14840f5426ac742fcbbd3e37d4';

abstract class _$ProfileNameNotifier extends $AsyncNotifier<ProfileNameState> {
  FutureOr<ProfileNameState> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<ProfileNameState>, ProfileNameState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<ProfileNameState>, ProfileNameState>,
              AsyncValue<ProfileNameState>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
