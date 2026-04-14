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
    r'eb5e3a9027bc58f91277fb163307c112fabed133';

@ProviderFor(signUpFormValidator)
final signUpFormValidatorProvider = SignUpFormValidatorProvider._();

final class SignUpFormValidatorProvider
    extends
        $FunctionalProvider<
          SignUpFormValidator,
          SignUpFormValidator,
          SignUpFormValidator
        >
    with $Provider<SignUpFormValidator> {
  SignUpFormValidatorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'signUpFormValidatorProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$signUpFormValidatorHash();

  @$internal
  @override
  $ProviderElement<SignUpFormValidator> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SignUpFormValidator create(Ref ref) {
    return signUpFormValidator(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SignUpFormValidator value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SignUpFormValidator>(value),
    );
  }
}

String _$signUpFormValidatorHash() =>
    r'b8872e5b617745be6e530c4c8a299d352a79313b';

@ProviderFor(forgotPasswordFormValidator)
final forgotPasswordFormValidatorProvider =
    ForgotPasswordFormValidatorProvider._();

final class ForgotPasswordFormValidatorProvider
    extends
        $FunctionalProvider<
          ForgotPasswordFormValidator,
          ForgotPasswordFormValidator,
          ForgotPasswordFormValidator
        >
    with $Provider<ForgotPasswordFormValidator> {
  ForgotPasswordFormValidatorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'forgotPasswordFormValidatorProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$forgotPasswordFormValidatorHash();

  @$internal
  @override
  $ProviderElement<ForgotPasswordFormValidator> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ForgotPasswordFormValidator create(Ref ref) {
    return forgotPasswordFormValidator(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ForgotPasswordFormValidator value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ForgotPasswordFormValidator>(value),
    );
  }
}

String _$forgotPasswordFormValidatorHash() =>
    r'04116767cab1a37131b96267c262413f221387d2';

@ProviderFor(passwordResetConfirmFormValidator)
final passwordResetConfirmFormValidatorProvider =
    PasswordResetConfirmFormValidatorProvider._();

final class PasswordResetConfirmFormValidatorProvider
    extends
        $FunctionalProvider<
          PasswordResetConfirmFormValidator,
          PasswordResetConfirmFormValidator,
          PasswordResetConfirmFormValidator
        >
    with $Provider<PasswordResetConfirmFormValidator> {
  PasswordResetConfirmFormValidatorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'passwordResetConfirmFormValidatorProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() =>
      _$passwordResetConfirmFormValidatorHash();

  @$internal
  @override
  $ProviderElement<PasswordResetConfirmFormValidator> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PasswordResetConfirmFormValidator create(Ref ref) {
    return passwordResetConfirmFormValidator(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PasswordResetConfirmFormValidator value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PasswordResetConfirmFormValidator>(
        value,
      ),
    );
  }
}

String _$passwordResetConfirmFormValidatorHash() =>
    r'8d985583eace06ce044235ba841d81ed992f10c4';
