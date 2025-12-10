// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$UserStore on UserStoreBase, Store {
  late final _$isLoadingAtom = Atom(
    name: 'UserStoreBase.isLoading',
    context: context,
  );

  @override
  bool get isLoading {
    _$isLoadingAtom.reportRead();
    return super.isLoading;
  }

  @override
  set isLoading(bool value) {
    _$isLoadingAtom.reportWrite(value, super.isLoading, () {
      super.isLoading = value;
    });
  }

  late final _$userAtom = Atom(name: 'UserStoreBase.user', context: context);

  @override
  UserDto get user {
    _$userAtom.reportRead();
    return super.user;
  }

  @override
  set user(UserDto value) {
    _$userAtom.reportWrite(value, super.user, () {
      super.user = value;
    });
  }

  late final _$toggleAsyncAction = AsyncAction(
    'UserStoreBase.toggle',
    context: context,
  );

  @override
  Future<void> toggle(ImagesConstant type) {
    return _$toggleAsyncAction.run(() => super.toggle(type));
  }

  late final _$findAsyncAction = AsyncAction(
    'UserStoreBase.find',
    context: context,
  );

  @override
  Future<void> find() {
    return _$findAsyncAction.run(() => super.find());
  }

  late final _$insertAsyncAction = AsyncAction(
    'UserStoreBase.insert',
    context: context,
  );

  @override
  Future<void> insert(UserDto data) {
    return _$insertAsyncAction.run(() => super.insert(data));
  }

  late final _$updateAsyncAction = AsyncAction(
    'UserStoreBase.update',
    context: context,
  );

  @override
  Future<void> update(UserDto data) {
    return _$updateAsyncAction.run(() => super.update(data));
  }

  late final _$deleteAsyncAction = AsyncAction(
    'UserStoreBase.delete',
    context: context,
  );

  @override
  Future<void> delete(UserDto data) {
    return _$deleteAsyncAction.run(() => super.delete(data));
  }

  late final _$UserStoreBaseActionController = ActionController(
    name: 'UserStoreBase',
    context: context,
  );

  @override
  Future<void> ensureInitialized() {
    final _$actionInfo = _$UserStoreBaseActionController.startAction(
      name: 'UserStoreBase.ensureInitialized',
    );
    try {
      return super.ensureInitialized();
    } finally {
      _$UserStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
isLoading: ${isLoading},
user: ${user}
    ''';
  }
}
