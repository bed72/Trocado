// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'insights_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(InsightsNotifier)
final insightsProvider = InsightsNotifierProvider._();

final class InsightsNotifierProvider
    extends $AsyncNotifierProvider<InsightsNotifier, InsightsBundleModel> {
  InsightsNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'insightsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$insightsNotifierHash();

  @$internal
  @override
  InsightsNotifier create() => InsightsNotifier();
}

String _$insightsNotifierHash() => r'6b5f2636d096e26450793bb0346a3fb94878d97f';

abstract class _$InsightsNotifier extends $AsyncNotifier<InsightsBundleModel> {
  FutureOr<InsightsBundleModel> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<InsightsBundleModel>, InsightsBundleModel>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<InsightsBundleModel>, InsightsBundleModel>,
              AsyncValue<InsightsBundleModel>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
