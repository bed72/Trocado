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

String _$insightsNotifierHash() => r'275935702a18eaa9fe9fe337271cf541b5d4ca1c';

abstract class _$InsightsNotifier extends $AsyncNotifier<InsightsBundleModel> {
  FutureOr<InsightsBundleModel> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
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
    return element.handleCreate(ref, build);
  }
}
