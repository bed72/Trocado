// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fingerprint_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$FingerprintStore on FingerprintStoreBase, Store {
  late final _$fingerprintAtom = Atom(
    name: 'FingerprintStoreBase.fingerprint',
    context: context,
  );

  @override
  bool get fingerprint {
    _$fingerprintAtom.reportRead();
    return super.fingerprint;
  }

  @override
  set fingerprint(bool value) {
    _$fingerprintAtom.reportWrite(value, super.fingerprint, () {
      super.fingerprint = value;
    });
  }

  late final _$ensureInitializedAsyncAction = AsyncAction(
    'FingerprintStoreBase.ensureInitialized',
    context: context,
  );

  @override
  Future<void> ensureInitialized() {
    return _$ensureInitializedAsyncAction.run(() => super.ensureInitialized());
  }

  late final _$FingerprintStoreBaseActionController = ActionController(
    name: 'FingerprintStoreBase',
    context: context,
  );

  @override
  void onChanged(bool value) {
    final _$actionInfo = _$FingerprintStoreBaseActionController.startAction(
      name: 'FingerprintStoreBase.onChanged',
    );
    try {
      return super.onChanged(value);
    } finally {
      _$FingerprintStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
fingerprint: ${fingerprint}
    ''';
  }
}
