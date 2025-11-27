import 'package:flutter/material.dart';

import 'package:trocado/modules/core/core.dart';

class OnboardingStepsScreen extends StatefulWidget {
  final List<Widget> children;

  const OnboardingStepsScreen({super.key, required this.children});

  @override
  State<OnboardingStepsScreen> createState() => _OnboardingStepsScreenState();
}

class _OnboardingStepsScreenState extends State<OnboardingStepsScreen> {
  late int _index;
  late final PageController _controller;

  @override
  void initState() {
    super.initState();

    _index = 0;
    _controller = PageController();
  }

  @override
  void dispose() {
    _controller.dispose();

    super.dispose();
  }

  void _next() {
    if (_index < widget.children.length - 1) {
      _controller.nextPage(
        curve: Curves.easeOut,
        duration: const Duration(milliseconds: 300),
      );
    }
  }

  void _back() {
    if (_index == 0) context.pop();

    if (_index > 0) {
      _controller.previousPage(
        curve: Curves.easeOut,
        duration: const Duration(milliseconds: 300),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(children: [_buildContent(), _buildButtons(context)]),
        ),
      ),
    );
  }

  Expanded _buildContent() => Expanded(
    child: PageView(
      controller: _controller,
      onPageChanged: (index) => setState(() => _index = index),
      children: widget.children,
    ),
  );

  Row _buildButtons(BuildContext context) => Row(
    spacing: 16.0,
    mainAxisAlignment: MainAxisAlignment.end,
    children: [
      ButtonWidget.outlined(onTap: _back, label: 'Anterior'),
      ButtonWidget.elevated(
        onTap: _next,
        icon: FadeSizeSwitcher(
          curve: Curves.linear,
          child: Text(
            _index == widget.children.length - 1
                ? 'Salvar & Finalizar'
                : 'Próximo',
            key: ValueKey(_index == widget.children.length - 1),
          ),
        ),
      ),
    ],
  );
}
