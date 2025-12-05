// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'onboarding_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$OnboardingStore on OnboardingStoreBase, Store {
  late final _$onboardingAtom = Atom(
    name: 'OnboardingStoreBase.onboarding',
    context: context,
  );

  @override
  bool get onboarding {
    _$onboardingAtom.reportRead();
    return super.onboarding;
  }

  @override
  set onboarding(bool value) {
    _$onboardingAtom.reportWrite(value, super.onboarding, () {
      super.onboarding = value;
    });
  }

  late final _$ensureInitializedAsyncAction = AsyncAction(
    'OnboardingStoreBase.ensureInitialized',
    context: context,
  );

  @override
  Future<void> ensureInitialized() {
    return _$ensureInitializedAsyncAction.run(() => super.ensureInitialized());
  }

  late final _$toggleAsyncAction = AsyncAction(
    'OnboardingStoreBase.toggle',
    context: context,
  );

  @override
  Future<void> toggle(bool value) {
    return _$toggleAsyncAction.run(() => super.toggle(value));
  }

  @override
  String toString() {
    return '''
onboarding: ${onboarding}
    ''';
  }
}
