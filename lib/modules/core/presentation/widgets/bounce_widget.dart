import 'package:flutter/material.dart';

final _upScale = 1.0;
final _downScale = 0.8;

abstract base class BounceWidget extends StatefulWidget {
  final Widget child;

  const BounceWidget({super.key, required this.child});

  factory BounceWidget.withTap({
    Key? key,
    required Widget child,
    required VoidCallback onTap,
  }) => _BounceWithOnTapWidget(key: key, onTap: onTap, child: child);

  factory BounceWidget.withoutTap({Key? key, required Widget child}) =>
      _BounceWithoutTapWidget(key: key, child: child);
}

final class _BaseBounceWidget extends BounceWidget {
  final double scale;
  const _BaseBounceWidget({required super.child, required this.scale});

  @override
  State<_BaseBounceWidget> createState() => _BaseBounceWidgetState();
}

class _BaseBounceWidgetState extends State<_BaseBounceWidget> {
  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: widget.scale,
      curve: Curves.easeOutBack,
      duration: const Duration(milliseconds: 270),
      child: widget.child,
    );
  }
}

final class _BounceWithoutTapWidget extends BounceWidget {
  const _BounceWithoutTapWidget({super.key, required super.child});

  @override
  State<_BounceWithoutTapWidget> createState() =>
      _BounceWithoutTapWidgetState();
}

class _BounceWithoutTapWidgetState extends State<_BounceWithoutTapWidget>
    with SingleTickerProviderStateMixin {
  double _scale = _upScale;

  void _onPointerDown(PointerDownEvent _) {
    setState(() => _scale = _downScale);
  }

  void _onPointerUp(PointerUpEvent _) {
    setState(() => _scale = _upScale);
  }

  void _onPointerCancel(PointerCancelEvent _) {
    setState(() => _scale = _upScale);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerUp: _onPointerUp,
      onPointerDown: _onPointerDown,
      onPointerCancel: _onPointerCancel,
      child: _BaseBounceWidget(scale: _scale, child: widget.child),
    );
  }
}

final class _BounceWithOnTapWidget extends BounceWidget {
  final VoidCallback? onTap;

  const _BounceWithOnTapWidget({super.key, required super.child, this.onTap});

  @override
  State<_BounceWithOnTapWidget> createState() => _BounceWithOnTapWidgetState();
}

class _BounceWithOnTapWidgetState extends State<_BounceWithOnTapWidget>
    with SingleTickerProviderStateMixin {
  double _scale = _upScale;

  void _onTapDown(TapDownDetails _) {
    setState(() => _scale = _downScale);
  }

  void _onTapUp(TapUpDetails _) {
    setState(() => _scale = _upScale);
    widget.onTap?.call();
  }

  void _onTapCancel() {
    setState(() => _scale = _upScale);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapUp: _onTapUp,
      onTapDown: _onTapDown,
      onTapCancel: _onTapCancel,
      child: _BaseBounceWidget(scale: _scale, child: widget.child),
    );
  }
}
