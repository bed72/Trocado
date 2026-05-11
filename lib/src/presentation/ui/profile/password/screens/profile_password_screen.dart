import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:trocado/src/domain/failures/failure.dart';

import 'package:trocado/src/presentation/extensions/widget_extension.dart';

import 'package:trocado/src/presentation/widgets/toast_widget.dart';
import 'package:trocado/src/presentation/widgets/app_bar_widget.dart';
import 'package:trocado/src/presentation/widgets/go_back_widget.dart';
import 'package:trocado/src/presentation/widgets/scaffold_widget.dart';
import 'package:trocado/src/presentation/widgets/screen_header_widget.dart';
import 'package:trocado/src/presentation/widgets/buttons/button_widget.dart';
import 'package:trocado/src/presentation/widgets/fields/password_field_widget.dart';
import 'package:trocado/src/presentation/widgets/circular_progress_indicator_widget.dart';

import 'package:trocado/src/presentation/ui/profile/password/notifiers/profile_password_state.dart';
import 'package:trocado/src/presentation/ui/profile/password/notifiers/profile_password_intent.dart';
import 'package:trocado/src/presentation/ui/profile/password/notifiers/profile_password_notifier.dart';

class ProfilePasswordScreen extends StatelessWidget {
  final VoidCallback onSuccess;

  const ProfilePasswordScreen({super.key, required this.onSuccess});

  @override
  Widget build(BuildContext context) => ScaffoldWidget(
    appBar: AppBarWidget(leading: GoBackWidget()),
    child: Consumer(
      builder: (_, ref, _) {
        ref.listen(profilePasswordProvider, (previous, next) {
          final previousStatus = previous?.value?.status;
          final nextStatus = next.value?.status;

          if (nextStatus == .failure && previousStatus != .failure) {
            showToastWidget(
              context: context,
              title: 'Opps',
              type: .failure,
              description: next.value?.message ?? '',
            );
          }

          if (nextStatus == .success && previousStatus != .success) {
            onSuccess();
          }
        });

        return switch (ref.watch(profilePasswordProvider)) {
          AsyncData(:final value) => _buildBody(
            state: value,
            notifier: ref.read(profilePasswordProvider.notifier),
          ),
          AsyncError(:final error) => _buildError(
            failure: error is Failure ? error : const UnknownFailure(),
            onRetry: () => ref.invalidate(profilePasswordProvider),
          ),
          _ => const Center(child: CircularProgressIndicatorWidget()),
        };
      },
    ),
  );

  CustomScrollView _buildBody({
    required ProfilePasswordState state,
    required ProfilePasswordNotifier notifier,
  }) => CustomScrollView(
    slivers: [
      SliverFillRemaining(
        hasScrollBody: false,
        child: Padding(
          padding: const .all(16.0),
          child: Column(
            spacing: 24.0,
            crossAxisAlignment: .start,
            children: [
              const ScreenHeaderWidget(
                title: 'Senha',
                description: 'Crie uma nova senha para sua conta.',
              ),
              Column(
                spacing: 12.0,
                crossAxisAlignment: .start,
                children: [
                  PasswordFieldWidget(
                    inputAction: .next,
                    label: 'Senha atual',
                    hint: 'Digite sua senha atual',
                    failure: state.currentPasswordFailure,
                    obscure: state.obscureCurrentPassword,
                    onChanged: (value) =>
                        notifier.dispatch(CurrentPasswordChanged(value)),
                    onToggle: () => notifier.dispatch(
                      const CurrentPasswordVisibilityToggled(),
                    ),
                  ),
                  PasswordFieldWidget(
                    inputAction: .done,
                    label: 'Nova senha',
                    hint: 'Digite a nova senha',
                    failure: state.newPasswordFailure,
                    obscure: state.obscureNewPassword,
                    onChanged: (value) =>
                        notifier.dispatch(NewPasswordChanged(value)),
                    onToggle: () => notifier.dispatch(
                      const NewPasswordVisibilityToggled(),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              SizedBox(
                width: .infinity,
                child: ButtonWidget.elevated(
                  label: 'Atualizar',
                  isLoading: state.status == .loading,
                  onTap: () {
                    hideKeyboard();
                    notifier.dispatch(const SubmitPressed());
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );

  Widget _buildError({
    required Failure failure,
    required VoidCallback onRetry,
  }) => Center(
    child: Column(
      spacing: 16.0,
      mainAxisSize: .min,
      children: [
        Text(failure.message, textAlign: .center),
        ButtonWidget.outlined(label: 'Tentar novamente', onTap: onRetry),
      ],
    ),
  );
}
