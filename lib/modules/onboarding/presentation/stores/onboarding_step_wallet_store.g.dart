// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'onboarding_step_wallet_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$OnboardingStepWalletStore on OnboardingStepWalletStoreBase, Store {
  late final _$nameAtom = Atom(
    name: 'OnboardingStepWalletStoreBase.name',
    context: context,
  );

  @override
  String get name {
    _$nameAtom.reportRead();
    return super.name;
  }

  @override
  set name(String value) {
    _$nameAtom.reportWrite(value, super.name, () {
      super.name = value;
    });
  }

  late final _$amountAtom = Atom(
    name: 'OnboardingStepWalletStoreBase.amount',
    context: context,
  );

  @override
  String get amount {
    _$amountAtom.reportRead();
    return super.amount;
  }

  @override
  set amount(String value) {
    _$amountAtom.reportWrite(value, super.amount, () {
      super.amount = value;
    });
  }

  late final _$iconAtom = Atom(
    name: 'OnboardingStepWalletStoreBase.icon',
    context: context,
  );

  @override
  IconData get icon {
    _$iconAtom.reportRead();
    return super.icon;
  }

  @override
  set icon(IconData value) {
    _$iconAtom.reportWrite(value, super.icon, () {
      super.icon = value;
    });
  }

  late final _$OnboardingStepWalletStoreBaseActionController = ActionController(
    name: 'OnboardingStepWalletStoreBase',
    context: context,
  );

  @override
  void setName(String value) {
    final _$actionInfo = _$OnboardingStepWalletStoreBaseActionController
        .startAction(name: 'OnboardingStepWalletStoreBase.setName');
    try {
      return super.setName(value);
    } finally {
      _$OnboardingStepWalletStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setAmount(String value) {
    final _$actionInfo = _$OnboardingStepWalletStoreBaseActionController
        .startAction(name: 'OnboardingStepWalletStoreBase.setAmount');
    try {
      return super.setAmount(value);
    } finally {
      _$OnboardingStepWalletStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setIcon(IconData value) {
    final _$actionInfo = _$OnboardingStepWalletStoreBaseActionController
        .startAction(name: 'OnboardingStepWalletStoreBase.setIcon');
    try {
      return super.setIcon(value);
    } finally {
      _$OnboardingStepWalletStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
name: ${name},
amount: ${amount},
icon: ${icon}
    ''';
  }
}
