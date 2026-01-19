import 'dart:ui';
import 'dart:async';

final class DebounceAction {
  Timer? _timer;
  final Duration delay;

  DebounceAction({this.delay = const Duration(milliseconds: 400)});

  void call(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  void dispose() {
    _timer?.cancel();
  }
}
