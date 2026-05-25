import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/extensions/context_extension.dart';

import 'package:trocado/src/presentation/widgets/app_bar_widget.dart';
import 'package:trocado/src/presentation/widgets/go_back_widget.dart';
import 'package:trocado/src/presentation/widgets/icons/background_icon_widget.dart';
import 'package:trocado/src/presentation/widgets/scaffold_widget.dart';
import 'package:trocado/src/presentation/widgets/buttons/button_widget.dart';

class ForgotPasswordSuccessScreen extends StatelessWidget {
  final String email;
  final VoidCallback onBackToSignIn;

  const ForgotPasswordSuccessScreen({
    super.key,
    required this.email,
    required this.onBackToSignIn,
  });

  @override
  Widget build(BuildContext context) {
    return ScaffoldWidget(
      appBar: AppBarWidget(leading: GoBackWidget()),
      child: _buildBody(context),
    );
  }

  CustomScrollView _buildBody(BuildContext context) => CustomScrollView(
    slivers: [
      SliverFillRemaining(
        hasScrollBody: false,
        child: Padding(
          padding: const .symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: .center,
            children: [
              const Spacer(),

              _buildIcon(context),

              const SizedBox(height: 20.0),

              Text(
                'Pronto!',
                style: context.typography.headlineMedium?.copyWith(
                  fontWeight: .bold,
                ),
              ),

              const SizedBox(height: 8.0),

              _buildMessage(context),

              const Spacer(flex: 2),

              SizedBox(
                width: double.infinity,
                child: ButtonWidget.elevated(
                  label: 'Voltar pra entrar',
                  onTap: onBackToSignIn,
                ),
              ),

              const SizedBox(height: 28.0),
            ],
          ),
        ),
      ),
    ],
  );

  BackgroundIconWidget _buildIcon(BuildContext context) => BackgroundIconWidget(
    width: 96.0,
    height: 96.0,
    iconSize: 48.0,
    icon: Icons.mark_email_read_outlined,
    color: context.colors.onPrimaryContainer,
  );

  Widget _buildMessage(BuildContext context) => Text.rich(
    TextSpan(
      children: [
        const TextSpan(text: 'Mandamos um link de redefinição pra '),
        TextSpan(
          text: email,
          style: const TextStyle(fontWeight: .bold),
        ),
        const TextSpan(text: '.\nOlha sua caixa.'),
      ],
    ),
    textAlign: .center,
    style: context.typography.bodyMedium?.copyWith(
      color: context.colors.onSurfaceVariant,
    ),
  );
}
