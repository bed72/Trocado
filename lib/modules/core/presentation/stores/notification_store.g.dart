// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$NotificationStore on NotificationStoreBase, Store {
  late final _$notificationAtom = Atom(
    name: 'NotificationStoreBase.notification',
    context: context,
  );

  @override
  bool get notification {
    _$notificationAtom.reportRead();
    return super.notification;
  }

  @override
  set notification(bool value) {
    _$notificationAtom.reportWrite(value, super.notification, () {
      super.notification = value;
    });
  }

  late final _$ensureInitializedAsyncAction = AsyncAction(
    'NotificationStoreBase.ensureInitialized',
    context: context,
  );

  @override
  Future<void> ensureInitialized() {
    return _$ensureInitializedAsyncAction.run(() => super.ensureInitialized());
  }

  late final _$NotificationStoreBaseActionController = ActionController(
    name: 'NotificationStoreBase',
    context: context,
  );

  @override
  void onChanged(bool value) {
    final _$actionInfo = _$NotificationStoreBaseActionController.startAction(
      name: 'NotificationStoreBase.onChanged',
    );
    try {
      return super.onChanged(value);
    } finally {
      _$NotificationStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
notification: ${notification}
    ''';
  }
}
