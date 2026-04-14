// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'validators_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(signInFormValidator)
final signInFormValidatorProvider = SignInFormValidatorProvider._();

final class SignInFormValidatorProvider
    extends
        $FunctionalProvider<
          SignInFormValidator,
          SignInFormValidator,
          SignInFormValidator
        >
    with $Provider<SignInFormValidator> {
  SignInFormValidatorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'signInFormValidatorProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$signInFormValidatorHash();

  @$internal
  @override
  $ProviderElement<SignInFormValidator> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SignInFormValidator create(Ref ref) {
    return signInFormValidator(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SignInFormValidator value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SignInFormValidator>(value),
    );
  }
}

String _$signInFormValidatorHash() =>
    r'a1c057b0ac2be219f42abcd256f6469c8977d927';
