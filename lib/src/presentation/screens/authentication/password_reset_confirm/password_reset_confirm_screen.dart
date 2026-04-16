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
          (previous, next) => switch (next.status) {
            .success when previous?.status != .success =>
              _onSuccess(context),
            .failure when previous?.status != .failure => showToastWidget(
              context: context,
              title: 'Opps',
              type: .failure,
              description: next.message,
            ),
            _ => null,
          },
        );

        final state = ref.watch(
          passwordResetConfirmProvider(uid: uid, token: token),
        );
        final notifier = ref.read(
          passwordResetConfirmProvider(uid: uid, token: token).notifier,
        );

        return ScaffoldWidget(
          appBar: AppBarWidget(leading: GoBackWidget()),
          child: _buildBody(context: context, state: state, notifier: notifier),
        );
      },
    );
  }

  CustomScrollView _buildBody({
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

              Text(
                'Criar nova senha',
                style: context.typography.headlineMedium?.copyWith(
                  fontWeight: .bold,
                ),
              ),

              const SizedBox(height: 8.0),

              Text(
                'Informe sua nova senha para redefini-la.',
                style: context.typography.bodyMedium?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),

              const SizedBox(height: 28.0),

              TextFieldWidget(
                inputAction: .next,
                hint: 'Nova senha',
                label: 'Nova senha',
                hideTrailingIconWhenEmpty: true,
                failure: state.newPasswordFailure,
                obscureText: state.obscureNewPassword,
                trailingIcon: state.obscureNewPassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                onChanged: (value) =>
                    notifier.dispatch(NewPasswordChanged(value)),
                onTrailingIconTap: () =>
                    notifier.dispatch(const NewPasswordVisibilityToggled()),
              ),

              const SizedBox(height: 12.0),

              TextFieldWidget(
                inputAction: .done,
                hint: 'Confirmar senha',
                label: 'Confirmar senha',
                hideTrailingIconWhenEmpty: true,
                failure: state.confirmPasswordFailure,
                obscureText: state.obscureConfirmPassword,
                trailingIcon: state.obscureConfirmPassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                onChanged: (value) =>
                    notifier.dispatch(ConfirmPasswordChanged(value)),
                onTrailingIconTap: () =>
                    notifier.dispatch(const ConfirmPasswordVisibilityToggled()),
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

  void _onSuccess(BuildContext context) {
    showToastWidget(context: context, type: .success, title: 'Senha redefinida');
    onSuccess();
  }

  void _submit(PasswordResetConfirmNotifier notifier) {
    hideKeyboard();
    notifier.dispatch(const SubmitPressed());
  }
}
