// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'theme_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$ThemeStore on ThemeStoreBase, Store {
  Computed<bool>? _$isDarkComputed;

  @override
  bool get isDark => (_$isDarkComputed ??= Computed<bool>(
    () => super.isDark,
    name: 'ThemeStoreBase.isDark',
  )).value;

  late final _$themeAtom = Atom(name: 'ThemeStoreBase.theme', context: context);

  @override
  ThemeMode get theme {
    _$themeAtom.reportRead();
    return super.theme;
  }

  @override
  set theme(ThemeMode value) {
    _$themeAtom.reportWrite(value, super.theme, () {
      super.theme = value;
    });
  }

  late final _$ensureInitializedAsyncAction = AsyncAction(
    'ThemeStoreBase.ensureInitialized',
    context: context,
  );

  @override
  Future<void> ensureInitialized() {
    return _$ensureInitializedAsyncAction.run(() => super.ensureInitialized());
  }

  late final _$ThemeStoreBaseActionController = ActionController(
    name: 'ThemeStoreBase',
    context: context,
  );

  @override
  void onChanged(bool value) {
    final _$actionInfo = _$ThemeStoreBaseActionController.startAction(
      name: 'ThemeStoreBase.onChanged',
    );
    try {
      return super.onChanged(value);
    } finally {
      _$ThemeStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
theme: ${theme},
isDark: ${isDark}
    ''';
  }
}
