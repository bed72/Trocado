import 'package:flutter/material.dart';

import 'package:trocado/modules/core/core.dart';

class OnboardingScreen extends StatelessWidget {
  final VoidCallback onTap;

  const OnboardingScreen({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Center(
            child: Column(
              spacing: 16.0,
              mainAxisSize: .max,
              mainAxisAlignment: .center,
              children: [
                _buildLogo(context),
                _buildTitle(context),
                _buildDescription(context),
                _buildButton(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  ShimmerAnimation _buildLogo(BuildContext context) => ShimmerAnimation(
    pause: Duration(seconds: 6),
    duration: Duration(seconds: 4),
    radius: context.radius.cornerRadiusFull,
    child: Container(
      width: 172.0,
      height: 172.0,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: context.colors.inverseSurface.withValues(alpha: 0.10),
      ),
      child: ImageWidget(
        source: AssetsConstant.logo.source,
        alt: 'Logo do Trocado, aplicativo de finanças compartilhadas.',
      ),
    ),
  );

  Text _buildTitle(BuildContext context) => Text(
    'Trocado',
    style: context.typography.headlineMedium?.copyWith(
      height: 1.2,
      fontSize: 22.0,
      fontWeight: .w800,
    ),
  );

  Text _buildDescription(BuildContext context) => Text(
    'Organize sua vida financeira de um jeito simples, inteligente e compartilhado.',
    textAlign: .center,
    style: context.typography.bodyLarge?.copyWith(
      height: 1.4,
      fontWeight: .w500,
      color: context.colors.inverseSurface.withValues(alpha: 0.72),
    ),
  );

  SizedBox _buildButton(BuildContext context) => SizedBox(
    width: double.infinity,
    child: ButtonWidget.elevated(
      onTap: onTap,
      label: 'Vamos tornar isso um hábito.',
    ),
  );
}
