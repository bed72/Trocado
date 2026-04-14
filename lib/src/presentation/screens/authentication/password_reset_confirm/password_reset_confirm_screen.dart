import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:trocado/src/presentation/extensions/widget_extension.dart';

import 'package:trocado/src/presentation/widgets/toast_widget.dart';
import 'package:trocado/src/presentation/widgets/app_bar_widget.dart';
import 'package:trocado/src/presentation/widgets/go_back_widget.dart';
import 'package:trocado/src/presentation/widgets/scaffold_widget.dart';
import 'package:trocado/src/presentation/widgets/buttons/button_widget.dart';
import 'package:trocado/src/presentation/widgets/fields/text_field_widget.dart';

import 'package:trocado/src/presentation/screens/authentication/password_reset_confirm/notifiers/password_reset_confirm_state.dart';
import 'package:trocado/src/presentation/screens/authentication/password_reset_confirm/notifiers/password_reset_confirm_intent.dart';
import 'package:trocado/src/presentation/screens/authentication/password_reset_confirm/notifiers/password_reset_confirm_notifier.dart';

class PasswordResetConfirmScreen extends StatelessWidget {
  final String uid;
  final String token;
  final VoidCallback onSuccess;

  const PasswordResetConfirmScreen({
    super.key,
    required this.uid,
    required this.token,
    required this.onSuccess,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (_, ref, _) {
        ref.listen(
          passwordResetConfirmProvider(uid: uid, token: token),
          (_, next) {
            if (next.status == .success) {
              showToastWidget(
                context: context,
                type: .success,
                title: 'Senha redefinida',
              );
              onSuccess();
            }
            if (next.status == .failure) {
              showToastWidget(
                context: context,
                title: 'Opps',
                type: .failure,
                description: next.message,
              );
            }
          },
        );

        final state = ref.watch(
          passwordResetConfirmProvider(uid: uid, token: token),
        );
        final notifier = ref.read(
          passwordResetConfirmProvider(uid: uid, token: token).notifier,
        );

        return ScaffoldWidget(
          appBar: AppBarWidget(title: 'Criar nova senha', leading: GoBackWidget()),
          child: _buildBody(context: context, state: state, notifier: notifier),
        );
      },
    );
  }

  Widget _buildBody({
    required BuildContext context,
    required PasswordResetConfirmState state,
    required PasswordResetConfirmNotifier notifier,
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

              TextFieldWidget(
                label: 'Nova senha',
                hint: 'Nova senha',
                obscureText: true,
                failure: state.newPasswordFailure,
                onChanged: (value) =>
                    notifier.dispatch(NewPasswordChanged(value)),
              ),

              const SizedBox(height: 12.0),

              TextFieldWidget(
                label: 'Confirmar senha',
                hint: 'Confirmar senha',
                obscureText: true,
                inputAction: .done,
                failure: state.confirmPasswordFailure,
                onChanged: (value) =>
                    notifier.dispatch(ConfirmPasswordChanged(value)),
              ),

              const Spacer(),

              SizedBox(
                width: .infinity,
                child: ButtonWidget.elevated(
                  label: 'Redefinir senha',
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

  void _submit(PasswordResetConfirmNotifier notifier) {
    hideKeyboard();
    notifier.dispatch(const SubmitPressed());
  }
}
