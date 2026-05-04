import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:trocado/src/domain/failures/failure.dart';
import 'package:trocado/src/domain/models/user_model.dart';

import 'package:trocado/src/presentation/notifiers/user_notifier.dart';

import 'package:trocado/src/presentation/widgets/app_bar_widget.dart';
import 'package:trocado/src/presentation/widgets/go_back_widget.dart';
import 'package:trocado/src/presentation/widgets/scaffold_widget.dart';
import 'package:trocado/src/presentation/widgets/buttons/button_widget.dart';
import 'package:trocado/src/presentation/widgets/dialog/confirm_dialog_widget.dart';

import 'package:trocado/src/presentation/ui/profile/widgets/profile_header_widget.dart';
import 'package:trocado/src/presentation/ui/profile/widgets/profile_field_item_widget.dart';
import 'package:trocado/src/presentation/ui/profile/widgets/profile_fields_card_widget.dart';
import 'package:trocado/src/presentation/ui/profile/widgets/profile_delete_account_widget.dart';

const _placeholderUser = UserModel(
  id: 0,
  name: 'Carregando',
  email: 'carregando@trocado.app',
);

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) => ScaffoldWidget(
    appBar: AppBarWidget(leading: GoBackWidget()),
    child: Padding(
      padding: const .all(16.0),
      child: Consumer(
        builder: (_, ref, _) {
          final userState = ref.watch(userProvider);

          return switch (userState) {
            AsyncData(:final value) => _Body(
              user: value,
              onDelete: () => _confirmDelete(context),
            ),
            AsyncError(:final error) => _ErrorView(
              failure: error is Failure ? error : const UnknownFailure(),
              onRetry: () => ref.invalidate(userProvider),
            ),
            _ => Skeletonizer(
              enabled: true,
              child: _Body(user: _placeholderUser, onDelete: () {}),
            ),
          };
        },
      ),
    ),
  );

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showConfirmDialog(
      context: context,
      title: 'Apagar conta',
      confirmLabel: 'Apagar',
      description:
          'Esta ação é irreversível. Todos os seus dados financeiros serão apagados e você não poderá recuperá-los.',
    );
    if (!confirmed) return;
  }
}

class _Body extends StatelessWidget {
  final UserModel user;
  final VoidCallback onDelete;

  const _Body({required this.user, required this.onDelete});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: .start,
    children: [
      const SizedBox(height: 16.0),
      ProfileHeaderWidget(user: user),
      const SizedBox(height: 32.0),
      ProfileFieldsCardWidget(
        children: [
          ProfileFieldItemWidget(label: 'Nome', onTap: () {}),
          ProfileFieldItemWidget(
            label: 'E-mail',
            enabled: false,
            onTap: () {},
          ),
          ProfileFieldItemWidget(label: 'Senha', onTap: () {}),
        ],
      ),
      const Spacer(),
      ProfileDeleteAccountWidget(onTap: onDelete),
    ],
  );
}

class _ErrorView extends StatelessWidget {
  final Failure failure;
  final VoidCallback onRetry;

  const _ErrorView({required this.failure, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: .min,
      children: [
        Text(failure.message, textAlign: .center),
        const SizedBox(height: 16.0),
        ButtonWidget.outlined(label: 'Tentar novamente', onTap: onRetry),
      ],
    ),
  );
}
