// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'forgot_password_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ForgotPasswordNotifier)
final forgotPasswordProvider = ForgotPasswordNotifierProvider._();

final class ForgotPasswordNotifierProvider
    extends $NotifierProvider<ForgotPasswordNotifier, ForgotPasswordState> {
  ForgotPasswordNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'forgotPasswordProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$forgotPasswordNotifierHash();

  @$internal
  @override
  ForgotPasswordNotifier create() => ForgotPasswordNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ForgotPasswordState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ForgotPasswordState>(value),
    );
  }
}

String _$forgotPasswordNotifierHash() =>
    r'842d93e945ffa126b8fce2f6a0da9bfc6349de1d';

abstract class _$ForgotPasswordNotifier extends $Notifier<ForgotPasswordState> {
  ForgotPasswordState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ForgotPasswordState, ForgotPasswordState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ForgotPasswordState, ForgotPasswordState>,
              ForgotPasswordState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
