// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bottom_bar_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$BottomBarStore on BottomBarStoreBase, Store {
  late final _$indexAtom = Atom(
    name: 'BottomBarStoreBase.index',
    context: context,
  );

  @override
  int get index {
    _$indexAtom.reportRead();
    return super.index;
  }

  @override
  set index(int value) {
    _$indexAtom.reportWrite(value, super.index, () {
      super.index = value;
    });
  }

  late final _$visibleAtom = Atom(
    name: 'BottomBarStoreBase.visible',
    context: context,
  );

  @override
  bool get visible {
    _$visibleAtom.reportRead();
    return super.visible;
  }

  @override
  set visible(bool value) {
    _$visibleAtom.reportWrite(value, super.visible, () {
      super.visible = value;
    });
  }

  late final _$BottomBarStoreBaseActionController = ActionController(
    name: 'BottomBarStoreBase',
    context: context,
  );

  @override
  void onChanged(bool value) {
    final _$actionInfo = _$BottomBarStoreBaseActionController.startAction(
      name: 'BottomBarStoreBase.onChanged',
    );
    try {
      return super.onChanged(value);
    } finally {
      _$BottomBarStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void switchChild(int value) {
    final _$actionInfo = _$BottomBarStoreBaseActionController.startAction(
      name: 'BottomBarStoreBase.switchChild',
    );
    try {
      return super.switchChild(value);
    } finally {
      _$BottomBarStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
index: ${index},
visible: ${visible}
    ''';
  }
}
