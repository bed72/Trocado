import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:trocado/src/presentation/extensions/widget_extension.dart';

import 'package:trocado/src/presentation/widgets/app_bar_widget.dart';
import 'package:trocado/src/presentation/widgets/go_back_widget.dart';
import 'package:trocado/src/presentation/widgets/scaffold_widget.dart';
import 'package:trocado/src/presentation/widgets/screen_header_widget.dart';
import 'package:trocado/src/presentation/widgets/buttons/button_widget.dart';
import 'package:trocado/src/presentation/widgets/fields/password_field_widget.dart';

import 'package:trocado/src/presentation/ui/profile/password/notifiers/profile_password_intent.dart';
import 'package:trocado/src/presentation/ui/profile/password/notifiers/profile_password_notifier.dart';

class ProfilePasswordScreen extends StatelessWidget {
  const ProfilePasswordScreen({super.key});

  @override
  Widget build(BuildContext context) => ScaffoldWidget(
    appBar: AppBarWidget(leading: GoBackWidget()),
    child: Consumer(
      builder: (_, ref, _) {
        final state = ref.watch(profilePasswordProvider);
        final notifier = ref.read(profilePasswordProvider.notifier);

        return CustomScrollView(
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
                          hint: 'Nova senha',
                          label: 'Nova senha',
                          inputAction: .next,
                          failure: state.newPasswordFailure,
                          obscure: state.obscureNewPassword,
                          onChanged: (value) =>
                              notifier.dispatch(NewPasswordChanged(value)),
                          onToggle: () => notifier.dispatch(
                            const NewPasswordVisibilityToggled(),
                          ),
                        ),
                        PasswordFieldWidget(
                          inputAction: .done,
                          hint: 'Confirmar senha',
                          label: 'Confirmar senha',
                          failure: state.confirmPasswordFailure,
                          obscure: state.obscureConfirmPassword,
                          onChanged: (value) =>
                              notifier.dispatch(ConfirmPasswordChanged(value)),
                          onToggle: () => notifier.dispatch(
                            const ConfirmPasswordVisibilityToggled(),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    SizedBox(
                      width: .infinity,
                      child: ButtonWidget.elevated(
                        label: 'Atualizar',
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
      },
    ),
  );
}
