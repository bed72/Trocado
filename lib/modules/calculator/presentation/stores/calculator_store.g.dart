// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calculator_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$CalculatorStore on CalculatorStoreBase, Store {
  late final _$previewAtom = Atom(
    name: 'CalculatorStoreBase.preview',
    context: context,
  );

  @override
  String get preview {
    _$previewAtom.reportRead();
    return super.preview;
  }

  @override
  set preview(String value) {
    _$previewAtom.reportWrite(value, super.preview, () {
      super.preview = value;
    });
  }

  late final _$amountAtom = Atom(
    name: 'CalculatorStoreBase.amount',
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

  late final _$CalculatorStoreBaseActionController = ActionController(
    name: 'CalculatorStoreBase',
    context: context,
  );

  @override
  void onKeyTap(String key) {
    final _$actionInfo = _$CalculatorStoreBaseActionController.startAction(
      name: 'CalculatorStoreBase.onKeyTap',
    );
    try {
      return super.onKeyTap(key);
    } finally {
      _$CalculatorStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void clear() {
    final _$actionInfo = _$CalculatorStoreBaseActionController.startAction(
      name: 'CalculatorStoreBase.clear',
    );
    try {
      return super.clear();
    } finally {
      _$CalculatorStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void delete() {
    final _$actionInfo = _$CalculatorStoreBaseActionController.startAction(
      name: 'CalculatorStoreBase.delete',
    );
    try {
      return super.delete();
    } finally {
      _$CalculatorStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void append(String value) {
    final _$actionInfo = _$CalculatorStoreBaseActionController.startAction(
      name: 'CalculatorStoreBase.append',
    );
    try {
      return super.append(value);
    } finally {
      _$CalculatorStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void toggleParenthesis() {
    final _$actionInfo = _$CalculatorStoreBaseActionController.startAction(
      name: 'CalculatorStoreBase.toggleParenthesis',
    );
    try {
      return super.toggleParenthesis();
    } finally {
      _$CalculatorStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void applyresponse() {
    final _$actionInfo = _$CalculatorStoreBaseActionController.startAction(
      name: 'CalculatorStoreBase.applyresponse',
    );
    try {
      return super.applyresponse();
    } finally {
      _$CalculatorStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void updatePreview() {
    final _$actionInfo = _$CalculatorStoreBaseActionController.startAction(
      name: 'CalculatorStoreBase.updatePreview',
    );
    try {
      return super.updatePreview();
    } finally {
      _$CalculatorStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
preview: ${preview},
amount: ${amount}
    ''';
  }
}
