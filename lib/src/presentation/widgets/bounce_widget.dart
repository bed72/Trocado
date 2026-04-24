import 'package:flutter/material.dart';

final _upScale = 1.0;
final _downScale = 0.97;

abstract base class BounceWidget extends StatefulWidget {
  final Widget child;

  const BounceWidget({super.key, required this.child});

  factory BounceWidget.withOnPress({
    Key? key,
    required Widget child,
    required VoidCallback? onPress,
  }) => _BounceWithOnTapWidget(key: key, onPress: onPress, child: child);

  factory BounceWidget.withoutOnPress({Key? key, required Widget child}) =>
      _BounceWithoutTapWidget(key: key, child: child);
}

final class _BaseBounceWidget extends BounceWidget {
  final double scale;
  const _BaseBounceWidget({required super.child, required this.scale});

  @override
  State<_BaseBounceWidget> createState() => _BaseBounceWidgetState();
}

final class _BaseBounceWidgetState extends State<_BaseBounceWidget> {
  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: widget.scale,
      curve: Curves.easeOutBack,
      duration: const Duration(milliseconds: 80),
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

final class _BounceWithoutTapWidgetState extends State<_BounceWithoutTapWidget>
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
  final VoidCallback? onPress;

  const _BounceWithOnTapWidget({super.key, required super.child, this.onPress});

  @override
  State<_BounceWithOnTapWidget> createState() => _BounceWithOnTapWidgetState();
}

final class _BounceWithOnTapWidgetState extends State<_BounceWithOnTapWidget> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () async => await Future.delayed(
        const Duration(milliseconds: 30),
        widget.onPress,
      ),
      child: _BounceWithoutTapWidget(child: widget.child),
    );
  }
}
