// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'image_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$ImageStore on ImageStoreBase, Store {
  late final _$pathAtom = Atom(name: 'ImageStoreBase.path', context: context);

  @override
  String? get path {
    _$pathAtom.reportRead();
    return super.path;
  }

  @override
  set path(String? value) {
    _$pathAtom.reportWrite(value, super.path, () {
      super.path = value;
    });
  }

  late final _$ensureInitializedAsyncAction = AsyncAction(
    'ImageStoreBase.ensureInitialized',
    context: context,
  );

  @override
  Future<void> ensureInitialized() {
    return _$ensureInitializedAsyncAction.run(() => super.ensureInitialized());
  }

  late final _$toggleAsyncAction = AsyncAction(
    'ImageStoreBase.toggle',
    context: context,
  );

  @override
  Future<void> toggle(ImagesConstant type) {
    return _$toggleAsyncAction.run(() => super.toggle(type));
  }

  @override
  String toString() {
    return '''
path: ${path}
    ''';
  }
}
