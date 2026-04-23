import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:trocado/src/presentation/extensions/widget_extension.dart';
import 'package:trocado/src/presentation/extensions/context_extension.dart';

import 'package:trocado/src/presentation/widgets/toast_widget.dart';
import 'package:trocado/src/presentation/widgets/scaffold_widget.dart';
import 'package:trocado/src/presentation/widgets/buttons/button_widget.dart';
import 'package:trocado/src/presentation/widgets/fields/checkbox_field_widget.dart';
import 'package:trocado/src/presentation/widgets/fields/text_field_widget.dart';

import 'package:trocado/src/presentation/screens/authentication/sign_up/notifiers/sign_up_state.dart';
import 'package:trocado/src/presentation/screens/authentication/sign_up/notifiers/sign_up_intent.dart';
import 'package:trocado/src/presentation/screens/authentication/sign_up/notifiers/sign_up_notifier.dart';

class SignUpScreen extends StatelessWidget {
  final VoidCallback onSuccess;
  final VoidCallback onSignIn;

  const SignUpScreen({
    super.key,
    required this.onSuccess,
    required this.onSignIn,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (_, ref, _) {
        ref.listen(
          signUpProvider,
          (previous, next) => switch (next.status) {
            .success when previous?.status != .success => onSuccess(),
            .failure when previous?.status != .failure => _showToastWidget(
              context: context,
              message: next.message,
            ),
            _ => null,
          },
        );

        final state = ref.watch(signUpProvider);
        final notifier = ref.read(signUpProvider.notifier);

        return ScaffoldWidget(
          child: _buildBody(context: context, state: state, notifier: notifier),
        );
      },
    );
  }

  CustomScrollView _buildBody({
    required BuildContext context,
    required SignUpState state,
    required SignUpNotifier notifier,
  }) => CustomScrollView(
    slivers: [
      SliverFillRemaining(
        hasScrollBody: false,
        child: Padding(
          padding: const .symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: .start,
            children: [
              const Spacer(),

              Text(
                'Criar sua conta',
                style: context.typography.headlineSmall?.copyWith(
                  fontWeight: .bold,
                ),
              ),

              const SizedBox(height: 8.0),

              Text(
                'Preencha os dados abaixo',
                style: context.typography.bodyMedium?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),

              const SizedBox(height: 28.0),

              TextFieldWidget(
                label: 'E-mail',
                inputAction: .next,
                hint: 'Digite seu e-mail',
                keyboardType: .emailAddress,
                failure: state.emailFailure,
                onChanged: (value) => notifier.dispatch(EmailChanged(value)),
              ),

              const SizedBox(height: 12.0),

              TextFieldWidget(
                label: 'Senha',
                inputAction: .done,
                hint: 'Digite sua senha',
                failure: state.passwordFailure,
                obscureText: state.obscurePassword,
                hideTrailingIconWhenEmpty: true,
                trailingIcon: state.obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                onTrailingIconTap: () =>
                    notifier.dispatch(const PasswordVisibilityToggled()),
                onChanged: (value) => notifier.dispatch(PasswordChanged(value)),
              ),

              const SizedBox(height: 16.0),

              CheckboxFieldWidget(
                failure: state.termsFailure,
                checked: state.termsAccepted,
                label: 'Aceito os termos de uso e política de privacidade',
                onChanged: (value) => notifier.dispatch(TermsToggled(value)),
              ),

              const SizedBox(height: 16.0),
              const Spacer(),

              SizedBox(
                width: .infinity,
                child: ButtonWidget.elevated(
                  label: 'Continuar',
                  onTap: () => _submit(notifier),
                  isLoading: state.status == .loading,
                ),
              ),

              const SizedBox(height: 16.0),

              Row(
                mainAxisAlignment: .center,
                children: [
                  Text(
                    'Já possui uma conta? ',
                    style: context.typography.bodyMedium,
                  ),
                  ButtonWidget.text(onTap: onSignIn, label: 'Entrar'),
                ],
              ),

              const SizedBox(height: 28.0),
            ],
          ),
        ),
      ),
    ],
  );

  void _submit(SignUpNotifier notifier) {
    hideKeyboard();

    notifier.dispatch(const SubmitPressed());
  }

  void _showToastWidget({
    required BuildContext context,
    required String message,
  }) {
    showToastWidget(
      context: context,
      title: 'Opps',
      type: .failure,
      description: message,
    );
  }
}
