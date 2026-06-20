// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shared_active_budget_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SharedActiveBudgetNotifier)
final sharedActiveBudgetProvider = SharedActiveBudgetNotifierProvider._();

final class SharedActiveBudgetNotifierProvider
    extends
        $AsyncNotifierProvider<
          SharedActiveBudgetNotifier,
          SharedBudgetCardPresentationData?
        > {
  SharedActiveBudgetNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sharedActiveBudgetProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sharedActiveBudgetNotifierHash();

  @$internal
  @override
  SharedActiveBudgetNotifier create() => SharedActiveBudgetNotifier();
}

String _$sharedActiveBudgetNotifierHash() =>
    r'e6d67f6aa09ec051ff7026b82560199edac9da34';

abstract class _$SharedActiveBudgetNotifier
    extends $AsyncNotifier<SharedBudgetCardPresentationData?> {
  FutureOr<SharedBudgetCardPresentationData?> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<SharedBudgetCardPresentationData?>,
              SharedBudgetCardPresentationData?
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<SharedBudgetCardPresentationData?>,
                SharedBudgetCardPresentationData?
              >,
              AsyncValue<SharedBudgetCardPresentationData?>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
