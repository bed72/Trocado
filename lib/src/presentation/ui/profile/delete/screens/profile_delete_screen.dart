import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:trocado/src/presentation/notifiers/user_notifier.dart';
import 'package:trocado/src/presentation/extensions/widget_extension.dart';

import 'package:trocado/src/presentation/widgets/toast_widget.dart';
import 'package:trocado/src/presentation/widgets/app_bar_widget.dart';
import 'package:trocado/src/presentation/widgets/go_back_widget.dart';
import 'package:trocado/src/presentation/widgets/scaffold_widget.dart';
import 'package:trocado/src/presentation/widgets/screen_header_widget.dart';
import 'package:trocado/src/presentation/widgets/buttons/button_widget.dart';
import 'package:trocado/src/presentation/widgets/fields/text_field_widget.dart';
import 'package:trocado/src/presentation/widgets/fields/password_field_widget.dart';
import 'package:trocado/src/presentation/widgets/dialog/confirm_dialog_widget.dart';

import 'package:trocado/src/presentation/ui/profile/delete/notifiers/profile_delete_state.dart';
import 'package:trocado/src/presentation/ui/profile/delete/notifiers/profile_delete_intent.dart';
import 'package:trocado/src/presentation/ui/profile/delete/notifiers/profile_delete_notifier.dart';

class ProfileDeleteScreen extends StatelessWidget {
  const ProfileDeleteScreen({super.key});

  @override
  Widget build(BuildContext context) => ScaffoldWidget(
    appBar: AppBarWidget(leading: GoBackWidget()),
    child: Consumer(
      builder: (_, ref, _) {
        ref.listen(profileDeleteProvider, (previous, next) {
          if (next.status == .failure && previous?.status != .failure) {
            showToastWidget(
              context: context,
              title: 'Opps',
              type: .failure,
              description: next.message,
            );
          }
        });

        final state = ref.watch(profileDeleteProvider);
        final notifier = ref.read(profileDeleteProvider.notifier);
        final email = switch (ref.watch(userProvider)) {
          AsyncData(:final value) => value.email,
          _ => '',
        };

        return _buildBody(
          context: context,
          ref: ref,
          email: email,
          state: state,
          notifier: notifier,
        );
      },
    ),
  );

  CustomScrollView _buildBody({
    required BuildContext context,
    required WidgetRef ref,
    required String email,
    required ProfileDeleteState state,
    required ProfileDeleteNotifier notifier,
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
                title: 'Excluir conta',
                description:
                    'Esta ação é irreversível.\nConfirme com sua senha para excluir definitivamente sua conta e todos os dados associados.',
              ),
              TextFieldWidget(
                hint: '',
                enabled: false,
                readOnly: true,
                label: 'E-mail',
                initialValue: email,
              ),
              PasswordFieldWidget(
                label: 'Senha',
                inputAction: .done,
                hint: 'Digite sua senha',
                failure: state.passwordFailure,
                obscure: state.obscurePassword,
                onChanged: (value) => notifier.dispatch(PasswordChanged(value)),
                onToggle: () =>
                    notifier.dispatch(const PasswordVisibilityToggled()),
              ),
              const Spacer(),
              SizedBox(
                width: .infinity,
                child: ButtonWidget.danger(
                  label: 'Excluir',
                  isLoading: state.status == .loading,
                  onTap: () => _submit(context, ref, notifier),
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );

  Future<void> _submit(
    BuildContext context,
    WidgetRef ref,
    ProfileDeleteNotifier notifier,
  ) async {
    hideKeyboard();

    notifier.dispatch(const ValidatePressed());

    if (ref.read(profileDeleteProvider).passwordFailure != null) return;

    final confirmed = await showConfirmDialog(
      context: context,
      title: 'Excluir conta',
      confirmLabel: 'Excluir',
      description:
          'Esta ação é irreversível.\n\n - Todos os seus dados serão apagados;\n - Você não poderá recuperar sua conta.',
    );
    if (!confirmed) return;

    notifier.dispatch(const SubmitPressed());
  }
}
