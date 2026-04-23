// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sign_up_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SignUpNotifier)
final signUpProvider = SignUpNotifierProvider._();

final class SignUpNotifierProvider
    extends $NotifierProvider<SignUpNotifier, SignUpState> {
  SignUpNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'signUpProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$signUpNotifierHash();

  @$internal
  @override
  SignUpNotifier create() => SignUpNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SignUpState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SignUpState>(value),
    );
  }
}

String _$signUpNotifierHash() => r'bc9cda340378d29a8d15e22c7a3d75a3678acf84';

abstract class _$SignUpNotifier extends $Notifier<SignUpState> {
  SignUpState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<SignUpState, SignUpState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SignUpState, SignUpState>,
              SignUpState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
