import 'package:flutter/material.dart';

abstract class Notifier<T> extends ChangeNotifier {
  Notifier(this._state);

  T _state;
  T get state => _state;

  set state(T newState) {
    if (_state == newState) return;
    _state = newState;
    notifyListeners();
  }

  void update(T Function(T) reducer) {
    state = reducer(state);
  }

  Future<void> updateAsync(Future<T> Function(T) reducer) async {
    state = await reducer(state);
  }
}
