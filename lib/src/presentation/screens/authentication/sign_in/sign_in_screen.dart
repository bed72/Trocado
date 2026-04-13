import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:trocado/src/presentation/extensions/widget_extension.dart';
import 'package:trocado/src/presentation/extensions/context_extension.dart';

import 'package:trocado/src/presentation/widgets/toast_widget.dart';
import 'package:trocado/src/presentation/widgets/scaffold_widget.dart';
import 'package:trocado/src/presentation/widgets/fields/input_widget.dart';
import 'package:trocado/src/presentation/widgets/buttons/button_widget.dart';

import 'package:trocado/src/presentation/screens/authentication/sign_in/notifiers/sign_in_state.dart';
import 'package:trocado/src/presentation/screens/authentication/sign_in/notifiers/sign_in_intent.dart';
import 'package:trocado/src/presentation/screens/authentication/sign_in/notifiers/sign_in_notifier.dart';

class SignInScreen extends StatelessWidget {
  final VoidCallback onSuccess;

  const SignInScreen({super.key, required this.onSuccess});

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (_, ref, _) {
        ref.listen(signInProvider, (_, next) {
          if (next.status == .success) onSuccess();
          if (next.status == .failure) {
            _showToastWidget(context: context, message: next.message);
          }
        });

        final state = ref.watch(signInProvider);
        final notifier = ref.read(signInProvider.notifier);

        return ScaffoldWidget(
          child: _buildBody(context: context, state: state, notifier: notifier),
        );
      },
    );
  }

  Widget _buildBody({
    required BuildContext context,
    required SignInState state,
    required SignInNotifier notifier,
  }) => LayoutBuilder(
    builder: (_, constraints) => SingleChildScrollView(
      padding: const .symmetric(horizontal: 16.0),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: constraints.maxHeight),
        child: IntrinsicHeight(
          child: Column(
            crossAxisAlignment: .start,
            children: [
              const Spacer(),

              Text(
                'Bem-vindo',
                style: context.typography.headlineLarge?.copyWith(
                  fontWeight: .bold,
                ),
              ),

              Text(
                'Entre na sua conta para continuar',
                style: context.typography.bodyMedium?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),

              const SizedBox(height: 28.0),

              InputWidget(
                label: 'E-mail',
                hint: 'Digite seu e-mail',
                keyboardType: .emailAddress,
                failure: state.emailFailure,
                onChanged: (value) => notifier.dispatch(EmailChanged(value)),
              ),

              const SizedBox(height: 12.0),

              InputWidget(
                label: 'Senha',
                obscureText: true,
                inputAction: .done,
                hint: 'Digite sua senha',
                failure: state.passwordFailure,
                onChanged: (value) => notifier.dispatch(PasswordChanged(value)),
              ),

              Align(
                alignment: .centerRight,
                child: ButtonWidget.text(
                  onTap: () {},
                  label: 'Esqueci minha senha',
                ),
              ),

              const Spacer(),

              SizedBox(
                width: .infinity,
                child: ButtonWidget.elevated(
                  label: 'Entrar',
                  onTap: () => _submit(notifier),
                  isLoading: state.status == .loading,
                ),
              ),

              const SizedBox(height: 8.0),

              Row(
                mainAxisAlignment: .center,
                children: [
                  Text(
                    'Ainda não tem uma conta? ',
                    style: context.typography.bodyMedium,
                  ),
                  ButtonWidget.text(onTap: () {}, label: 'Criar conta'),
                ],
              ),

              const SizedBox(height: 28.0),
            ],
          ),
        ),
      ),
    ),
  );

  void _submit(SignInNotifier notifier) {
    hideKeyboard;

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
