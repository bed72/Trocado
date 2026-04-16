import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:trocado/src/presentation/extensions/widget_extension.dart';
import 'package:trocado/src/presentation/extensions/context_extension.dart';

import 'package:trocado/src/presentation/widgets/toast_widget.dart';
import 'package:trocado/src/presentation/widgets/app_bar_widget.dart';
import 'package:trocado/src/presentation/widgets/go_back_widget.dart';
import 'package:trocado/src/presentation/widgets/scaffold_widget.dart';
import 'package:trocado/src/presentation/widgets/buttons/button_widget.dart';
import 'package:trocado/src/presentation/widgets/fields/text_field_widget.dart';

import 'package:trocado/src/presentation/screens/authentication/forgot_password/notifiers/forgot_password_state.dart';
import 'package:trocado/src/presentation/screens/authentication/forgot_password/notifiers/forgot_password_intent.dart';
import 'package:trocado/src/presentation/screens/authentication/forgot_password/notifiers/forgot_password_notifier.dart';

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (_, ref, _) {
        ref.listen(forgotPasswordProvider, (_, next) {
          if (next.status == .success) {
            showToastWidget(
              context: context,
              type: .success,
              title: 'Verifique seu email',
            );
          }
          if (next.status == .failure) {
            showToastWidget(
              context: context,
              title: 'Opps',
              type: .failure,
              description: next.message,
            );
          }
        });

        final state = ref.watch(forgotPasswordProvider);
        final notifier = ref.read(forgotPasswordProvider.notifier);

        return ScaffoldWidget(
          appBar: AppBarWidget(leading: GoBackWidget()),
          child: _buildBody(context: context, state: state, notifier: notifier),
        );
      },
    );
  }

  CustomScrollView _buildBody({
    required BuildContext context,
    required ForgotPasswordState state,
    required ForgotPasswordNotifier notifier,
  }) => CustomScrollView(
    slivers: [
      SliverFillRemaining(
        hasScrollBody: false,
        child: Padding(
          padding: const .symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: .start,
            children: [
              const SizedBox(height: 24.0),

              Text(
                'Esqueceu a senha?',
                style: context.typography.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8.0),

              Text(
                'Informe seu e-mail para receber o link de redefinição.',
                style: context.typography.bodyMedium?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),

              const SizedBox(height: 28.0),

              TextFieldWidget(
                label: 'E-mail',
                hint: 'Digite seu e-mail',
                keyboardType: .emailAddress,
                failure: state.emailFailure,
                onChanged: (value) => notifier.dispatch(EmailChanged(value)),
              ),

              const Spacer(),

              SizedBox(
                width: .infinity,
                child: ButtonWidget.elevated(
                  label: 'Enviar',
                  onTap: () => _submit(notifier),
                  isLoading: state.status == .loading,
                ),
              ),

              const SizedBox(height: 28.0),
            ],
          ),
        ),
      ),
    ],
  );

  void _submit(ForgotPasswordNotifier notifier) {
    hideKeyboard();
    notifier.dispatch(const SubmitPressed());
  }
}
