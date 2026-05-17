// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invite_qr_code_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(InviteQrCodeNotifier)
final inviteQrCodeProvider = InviteQrCodeNotifierProvider._();

final class InviteQrCodeNotifierProvider
    extends
        $AsyncNotifierProvider<
          InviteQrCodeNotifier,
          InviteQrCodePresentationData
        > {
  InviteQrCodeNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'inviteQrCodeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$inviteQrCodeNotifierHash();

  @$internal
  @override
  InviteQrCodeNotifier create() => InviteQrCodeNotifier();
}

String _$inviteQrCodeNotifierHash() =>
    r'63c54d739e6ca30819beee60cb729eea83c23b34';

abstract class _$InviteQrCodeNotifier
    extends $AsyncNotifier<InviteQrCodePresentationData> {
  FutureOr<InviteQrCodePresentationData> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<InviteQrCodePresentationData>,
              InviteQrCodePresentationData
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<InviteQrCodePresentationData>,
                InviteQrCodePresentationData
              >,
              AsyncValue<InviteQrCodePresentationData>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
