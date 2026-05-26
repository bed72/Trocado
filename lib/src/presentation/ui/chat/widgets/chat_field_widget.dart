import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/widgets/bounce_widget.dart';
import 'package:trocado/src/presentation/extensions/context_extension.dart';
import 'package:trocado/src/presentation/widgets/icons/icon_widget.dart';

class ChatFieldWidget extends StatefulWidget {
  final bool enabled;
  final VoidCallback onSend;
  final ValueChanged<String> onChanged;

  const ChatFieldWidget({
    super.key,
    required this.onSend,
    required this.enabled,
    required this.onChanged,
  });

  @override
  State<ChatFieldWidget> createState() => _ChatFieldWidgetState();
}

class _ChatFieldWidgetState extends State<ChatFieldWidget> {
  bool _hasText = false;

  late final TextEditingController _controller;

  @override
  initState() {
    super.initState();

    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();

    super.dispose();
  }

  void _handleSend() {
    if (!_hasText || !widget.enabled) return;
    widget.onSend();
    _controller.clear();
    setState(() => _hasText = false);
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const .symmetric(horizontal: 16.0, vertical: 12.0),
    child: Row(
      spacing: 8.0,
      crossAxisAlignment: .end,
      children: [
        Expanded(child: _buildTextField()),
        _buildButton(),
      ],
    ),
  );

  BounceWidget _buildButton() => BounceWidget.withOnPress(
    onPress: _handleSend,
    child: Container(
      width: 48.0,
      height: 48.0,
      decoration: BoxDecoration(
        color: _hasText && widget.enabled
            ? context.colors.primary
            : context.colors.surfaceContainerHighest,
        borderRadius: context.radius.cornerRadius100,
      ),
      child: IconWidget(
        size: 18.0,
        icon: Icons.send,
        color: _hasText && widget.enabled
            ? context.colors.onPrimary
            : context.colors.onSurfaceVariant,
      ),
    ),
  );

  TextField _buildTextField() => TextField(
    minLines: 1,
    maxLines: 3,
    cursorHeight: 16.0,
    textInputAction: .send,
    enabled: widget.enabled,
    controller: _controller,
    textCapitalization: .sentences,
    onSubmitted: (_) => _handleSend(),
    style: context.typography.bodyMedium,
    onChanged: (value) {
      widget.onChanged(value);
      setState(() => _hasText = value.trim().isNotEmpty);
    },
    decoration: InputDecoration(
      hintText: 'Digite sua mensagem...',
      hintStyle: context.typography.bodyMedium?.copyWith(
        color: context.colors.onSurfaceVariant.withValues(alpha: 0.6),
      ),
      contentPadding: const .symmetric(vertical: 14.0, horizontal: 12.0),
      border: OutlineInputBorder(
        borderRadius: context.radius.cornerRadius100,
        borderSide: BorderSide(color: context.colors.onSurfaceVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: context.radius.cornerRadius100,
        borderSide: BorderSide(color: context.colors.onSurfaceVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: context.radius.cornerRadius100,
        borderSide: BorderSide(color: context.colors.primary),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: context.radius.cornerRadius100,
        borderSide: BorderSide(
          color: context.colors.onSurfaceVariant.withValues(alpha: 0.4),
        ),
      ),
    ),
  );
}
