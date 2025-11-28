import 'package:flutter/material.dart';

abstract class Notifier<T> extends ChangeNotifier {
  T _success;
  T get success => _success;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Object? _failure;
  Object? get failure => _failure;
  bool get hasFailure => _failure != null;

  Notifier(this._success);

  set success(T value) {
    if (_success == value) return;
    _success = value;
    notifyListeners();
  }

  void update(T Function(T) reducer) {
    success = reducer(success);
  }

  Future<void> updateAsync(Future<T> Function(T) reducer) async {
    await guard(() async {
      success = await reducer(success);
      return null;
    });
  }

  set loading(bool value) {
    if (_isLoading == value) return;

    if (value) clearFailure();

    _isLoading = value;
    notifyListeners();
  }

  set failure(Object error) {
    _failure = error;
    notifyListeners();
  }

  void clearFailure() {
    if (_failure == null) return;
    _failure = null;
    notifyListeners();
  }

  Future<R?> guard<R>(Future<R> Function() action) async {
    if (_isLoading) return null;

    loading = true;

    try {
      return await action();
    } catch (exception) {
      failure = exception;
      rethrow;
    } finally {
      loading = false;
    }
  }
}
