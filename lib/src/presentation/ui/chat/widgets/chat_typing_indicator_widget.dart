import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/extensions/context_extension.dart';

class ChatTypingIndicatorWidget extends StatefulWidget {
  const ChatTypingIndicatorWidget({super.key});

  @override
  State<ChatTypingIndicatorWidget> createState() =>
      _ChatTypingIndicatorWidgetState();
}

class _ChatTypingIndicatorWidgetState extends State<ChatTypingIndicatorWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: Container(
      margin: const .symmetric(vertical: 4.0),
      padding: const .symmetric(horizontal: 14.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerHighest,
        borderRadius: const .only(
          topLeft: .circular(16.0),
          topRight: .circular(16.0),
          bottomLeft: .circular(4.0),
          bottomRight: .circular(16.0),
        ),
      ),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => Row(
          mainAxisSize: .min,
          children: .generate(3, (index) {
            final delay = index * 0.2;
            final value = ((_controller.value + delay) % 1.0);
            final opacity = (1.0 - (value - 0.5).abs() * 2.0).clamp(0.3, 1.0);

            return Padding(
              padding: .only(right: index < 2 ? 4.0 : 0.0),
              child: Opacity(
                opacity: opacity,
                child: Container(
                  width: 8.0,
                  height: 8.0,
                  decoration: BoxDecoration(
                    shape: .circle,
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    ),
  );
}
