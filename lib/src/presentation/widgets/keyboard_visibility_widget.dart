import 'package:flutter/material.dart';

class KeyboardVisibilityWidget extends StatefulWidget {
  final Widget child;
  final ValueChanged<bool> onChanged;

  const KeyboardVisibilityWidget({
    super.key,
    required this.child,
    required this.onChanged,
  });

  @override
  State<KeyboardVisibilityWidget> createState() =>
      _KeyboardVisibilityWidgetState();
}

class _KeyboardVisibilityWidgetState extends State<KeyboardVisibilityWidget>
    with WidgetsBindingObserver {
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    final keyboardVisible = View.of(context).viewInsets.bottom > 0;

    if (_isVisible != keyboardVisible) {
      _isVisible = keyboardVisible;
      widget.onChanged(_isVisible);
    }

    super.didChangeMetrics();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
