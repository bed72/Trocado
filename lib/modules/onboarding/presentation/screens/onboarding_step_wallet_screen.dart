import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:trocado/modules/core/core.dart';

import 'package:trocado/modules/onboarding/presentation/widgets/step_title_widget.dart';
import 'package:trocado/modules/onboarding/presentation/widgets/step_description_widget.dart';
import 'package:trocado/modules/onboarding/presentation/widgets/forms/wallet_form_widget.dart';
import 'package:trocado/modules/onboarding/presentation/widgets/step_box_decoration_widget.dart';
import 'package:trocado/modules/onboarding/presentation/widgets/step_navigation_buttons_widget.dart';

class OnboardingStepWalletScreen extends StatefulWidget {
  final String amount;
  final VoidCallback navigateToCaculator;

  final VoidCallback goBack;
  final VoidCallback goNext;

  const OnboardingStepWalletScreen({
    super.key,
    required this.goBack,
    required this.goNext,
    required this.amount,
    required this.navigateToCaculator,
  });

  @override
  State<OnboardingStepWalletScreen> createState() =>
      _OnboardingStepWalletScreenState();
}

class _OnboardingStepWalletScreenState
    extends State<OnboardingStepWalletScreen> {
  late bool _hideButtons;

  @override
  void initState() {
    super.initState();

    _hideButtons = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const .only(left: 24.0, top: 24.0, right: 24.0, bottom: 8.0),
          child: Column(
            mainAxisSize: .min,
            children: [
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: .only(bottom: context.bottom + 24),
                    child: _buildContent(),
                  ),
                ),
              ),

              AnimatedSlide(
                curve: Curves.decelerate,
                duration: const Duration(milliseconds: 300),
                offset: _hideButtons ? const Offset(0, 1) : .zero,
                child: AnimatedOpacity(
                  opacity: _hideButtons ? 0 : 1,
                  duration: const Duration(milliseconds: 300),
                  child: _buildButtons(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Column _buildContent() => Column(
    spacing: 16.0,
    mainAxisSize: .max,
    children: [
      StepBoxDecorationWidget(
        width: 100,
        height: 100,
        child: Icon(LucideIcons.wallet, size: 50.0),
      ),

      const StepTitleWidget(value: 'Crie sua primeira Carteira?'),
      StepDescriptionWidget(
        value:
            'Criar uma carteira é como abrir um bolso novo só seu, '
            'organizado e pronto pra te ajudar a ver pra onde o dinheiro vai.',
      ),

      WalletFormWidget(
        onSaved: (_) {},
        isLoading: false,
        amount: widget.amount,
        navigateToCaculator: widget.navigateToCaculator,
      ),
    ],
  );

  StepNavigationButtonsWidget _buildButtons() => StepNavigationButtonsWidget(
    goBack: widget.goBack,
    goNext: widget.goNext,
    nextTitle: 'Finalizar',
  );
}
