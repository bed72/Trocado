// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'password_reset_confirm_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(PasswordResetConfirmNotifier)
final passwordResetConfirmProvider = PasswordResetConfirmNotifierFamily._();

final class PasswordResetConfirmNotifierProvider
    extends
        $NotifierProvider<
          PasswordResetConfirmNotifier,
          PasswordResetConfirmState
        > {
  PasswordResetConfirmNotifierProvider._({
    required PasswordResetConfirmNotifierFamily super.from,
    required ({String uid, String token}) super.argument,
  }) : super(
         retry: null,
         name: r'passwordResetConfirmProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$passwordResetConfirmNotifierHash();

  @override
  String toString() {
    return r'passwordResetConfirmProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  PasswordResetConfirmNotifier create() => PasswordResetConfirmNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PasswordResetConfirmState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PasswordResetConfirmState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is PasswordResetConfirmNotifierProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$passwordResetConfirmNotifierHash() =>
    r'b8cfb12ae0e36a1752420ca25aa600a4d4551b82';

final class PasswordResetConfirmNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          PasswordResetConfirmNotifier,
          PasswordResetConfirmState,
          PasswordResetConfirmState,
          PasswordResetConfirmState,
          ({String uid, String token})
        > {
  PasswordResetConfirmNotifierFamily._()
    : super(
        retry: null,
        name: r'passwordResetConfirmProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  PasswordResetConfirmNotifierProvider call({
    required String uid,
    required String token,
  }) => PasswordResetConfirmNotifierProvider._(
    argument: (uid: uid, token: token),
    from: this,
  );

  @override
  String toString() => r'passwordResetConfirmProvider';
}

abstract class _$PasswordResetConfirmNotifier
    extends $Notifier<PasswordResetConfirmState> {
  late final _$args = ref.$arg as ({String uid, String token});
  String get uid => _$args.uid;
  String get token => _$args.token;

  PasswordResetConfirmState build({required String uid, required String token});
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<PasswordResetConfirmState, PasswordResetConfirmState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<PasswordResetConfirmState, PasswordResetConfirmState>,
              PasswordResetConfirmState,
              Object?,
              Object?
            >;
    return element.handleCreate(
      ref,
      () => build(uid: _$args.uid, token: _$args.token),
    );
  }
}
