import 'package:flutter/material.dart';

abstract class Notifier<S> extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Object? _failure;
  Object? get failure => _failure;
  bool get hasFailure => _failure != null;

  S _success;
  S get success => _success;
  bool get hasSuccess => _success != null;

  Notifier(this._success);

  set success(S value) {
    if (_success == value) return;
    _success = value;
    notifyListeners();
  }

  void replace(S Function(S) reducer) {
    success = reducer(success);
  }

  Future<void> replaceAsync(Future<S> Function(S) reducer) async {
    await flow(() async {
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

  Future<R?> flow<R>(Future<R> Function() action) async {
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
