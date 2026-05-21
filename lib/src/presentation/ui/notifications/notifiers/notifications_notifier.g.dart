// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notifications_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(NotificationsNotifier)
final notificationsProvider = NotificationsNotifierProvider._();

final class NotificationsNotifierProvider
    extends $AsyncNotifierProvider<NotificationsNotifier, NotificationsState> {
  NotificationsNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'notificationsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$notificationsNotifierHash();

  @$internal
  @override
  NotificationsNotifier create() => NotificationsNotifier();
}

String _$notificationsNotifierHash() =>
    r'de66de5b9e6ed6ca06ccecead0edf6570edac671';

abstract class _$NotificationsNotifier
    extends $AsyncNotifier<NotificationsState> {
  FutureOr<NotificationsState> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<NotificationsState>, NotificationsState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<NotificationsState>, NotificationsState>,
              AsyncValue<NotificationsState>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
