import 'package:flutter/material.dart';

import 'package:trocado/modules/core/core.dart';

import 'package:trocado/modules/calculator/presentation/widgets/calculator_keyboard_widget.dart';

class CalculatorScreen extends StatefulWidget {
  final double Function(String) evaluate;

  const CalculatorScreen({super.key, required this.evaluate});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  String? _preview;

  late final FocusNode _focus;
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _focus = FocusNode();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _focus.dispose();
    _controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BottomSheetScaffoldWidget(
      title: 'Continha Rápida',
      subtitle: 'Use a calculadora pra agilizar seus registros.',
      child: _buildContent(),
    );
  }

  Padding _buildContent() => Padding(
    padding: const .only(top: 12.0),
    child: Column(
      spacing: 16.0,
      mainAxisSize: .min,
      crossAxisAlignment: .start,
      children: [
        TextFieldWidget(
          focus: _focus,
          label: 'R\$ 0',
          absorbing: true,
          controller: _controller,
        ),

        _buildPreview(),

        CalculatorKeyboard(onKeyTap: _handleKeyTap),
      ],
    ),
  );

  AnimatedSwitcher _buildPreview() => AnimatedSwitcher(
    switchInCurve: Curves.easeOutCubic,
    switchOutCurve: Curves.easeInCubic,
    duration: const Duration(milliseconds: 300),
    transitionBuilder: (child, animation) =>
        FadeTransition(opacity: animation, child: child),
    child: Text(
      'Valor: ${_preview ?? 0}',
      key: ValueKey(_preview),
      style: context.typography.bodyLarge?.copyWith(
        fontWeight: .w600,
        color: context.colors.outline,
      ),
    ),
  );

  void _handleParenthesis() {
    final text = _controller.text;

    final opens = '('.allMatches(text).length;
    final closes = ')'.allMatches(text).length;

    if (opens == closes) {
      _controller.text += '(';
      return;
    }

    if (opens > closes) {
      _controller.text += ')';
      return;
    }
  }

  void _updatePreview() {
    final text = _controller.text;

    if (text.isEmpty) {
      setState(() => _preview = null);
      return;
    }

    final result = widget.evaluate(text);

    if (result.isNaN) {
      setState(() => _preview = null);
      return;
    }

    setState(() {
      _preview = result.toString().endsWith('.0')
          ? result.toInt().toString()
          : result.toString();
    });
  }

  void _handleKeyTap(String key) {
    String text = _controller.text;

    switch (key) {
      case 'AC':
        _controller.text = '';
        _preview = null;
        setState(() {});
        return;

      case 'DEL':
        if (text.isNotEmpty) {
          _controller.text = text.substring(0, text.length - 1);
        }
        _updatePreview();
        return;

      case '✓':
        _focus.unfocus();
        return;

      case '=':
        if (text.isEmpty) return;

        final result = widget.evaluate(text);

        if (!result.isNaN) {
          _controller.text = result.toString().endsWith('.0')
              ? result.toInt().toString()
              : result.toString();
        }

        _preview = null;
        setState(() {});
        return;

      default:
        if (key == '()') {
          _handleParenthesis();
        } else {
          _controller.text += key;
        }
        _updatePreview();
        return;
    }
  }
}
