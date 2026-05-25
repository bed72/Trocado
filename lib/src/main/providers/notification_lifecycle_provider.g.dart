// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_lifecycle_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(NotificationLifecycle)
final notificationLifecycleProvider = NotificationLifecycleProvider._();

final class NotificationLifecycleProvider
    extends $NotifierProvider<NotificationLifecycle, void> {
  NotificationLifecycleProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'notificationLifecycleProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$notificationLifecycleHash();

  @$internal
  @override
  NotificationLifecycle create() => NotificationLifecycle();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$notificationLifecycleHash() =>
    r'6835f0519e8106958022e3d100e8ff626b79da97';

abstract class _$NotificationLifecycle extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<void, void>,
              void,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
