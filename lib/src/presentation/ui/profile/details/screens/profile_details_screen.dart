import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:trocado/src/domain/failures/failure.dart';
import 'package:trocado/src/domain/models/user_model.dart';

import 'package:trocado/src/presentation/notifiers/user_notifier.dart';

import 'package:trocado/src/presentation/widgets/toast_widget.dart';
import 'package:trocado/src/presentation/widgets/app_bar_widget.dart';
import 'package:trocado/src/presentation/widgets/go_back_widget.dart';
import 'package:trocado/src/presentation/widgets/scaffold_widget.dart';
import 'package:trocado/src/presentation/widgets/screen_header_widget.dart';
import 'package:trocado/src/presentation/widgets/buttons/button_widget.dart';
import 'package:trocado/src/presentation/widgets/dialog/confirm_dialog_widget.dart';

import 'package:trocado/src/presentation/ui/profile/details/notifiers/profile_details_state.dart';
import 'package:trocado/src/presentation/ui/profile/details/notifiers/profile_details_intent.dart';
import 'package:trocado/src/presentation/ui/profile/details/notifiers/profile_details_notifier.dart';

import 'package:trocado/src/presentation/ui/profile/details/widgets/profile_header_widget.dart';
import 'package:trocado/src/presentation/ui/profile/details/widgets/profile_field_item_widget.dart';
import 'package:trocado/src/presentation/ui/profile/details/widgets/profile_fields_card_widget.dart';
import 'package:trocado/src/presentation/ui/profile/details/widgets/profile_account_actions_widget.dart';

class ProfileDetailsScreen extends StatelessWidget {
  final VoidCallback onEditName;
  final VoidCallback onEditPassword;

  const ProfileDetailsScreen({
    super.key,
    required this.onEditName,
    required this.onEditPassword,
  });

  @override
  Widget build(BuildContext context) => ScaffoldWidget(
    appBar: AppBarWidget(leading: GoBackWidget()),
    child: Padding(
      padding: const .all(16.0),
      child: Consumer(
        builder: (_, ref, _) {
          ref.listen(profileDetailsProvider, (previous, next) {
            if (next.status == .failure &&
                previous?.status != .failure) {
              showToastWidget(
                context: context,
                title: 'Opps',
                type: .failure,
                description: next.message,
              );
            }
          });

          final userState = ref.watch(userProvider);
          final detailsState = ref.watch(profileDetailsProvider);
          final notifier = ref.read(profileDetailsProvider.notifier);

          return switch (userState) {
            AsyncData(:final value) => _buildBody(
              user: value,
              detailsState: detailsState,
              onDelete: () => _confirmDelete(context),
              onDeactivate: () => _confirmDeactivate(context, notifier),
            ),
            AsyncError(:final error) => _buildError(
              failure: error is Failure ? error : const UnknownFailure(),
              onRetry: () => ref.invalidate(userProvider),
            ),
            _ => Skeletonizer(
              enabled: true,
              child: _buildBody(
                onDelete: () {},
                onDeactivate: () {},
                detailsState: const ProfileDetailsState(),
                user: UserModel(
                  id: 0,
                  name: 'Carregando',
                  email: 'carregando@trocado.app',
                ),
              ),
            ),
          };
        },
      ),
    ),
  );

  Widget _buildBody({
    required UserModel user,
    required VoidCallback onDelete,
    required VoidCallback onDeactivate,
    required ProfileDetailsState detailsState,
  }) => Column(
    spacing: 24.0,
    crossAxisAlignment: .start,
    children: [
      const ScreenHeaderWidget(
        title: 'Dados pessoais',
        description: 'Gerencie as informações da sua conta.',
      ),
      ProfileHeaderWidget(user: user),
      ProfileFieldsCardWidget(
        children: [
          ProfileFieldItemWidget(label: 'Nome', onTap: onEditName),
          ProfileFieldItemWidget(label: 'E-mail', enabled: false, onTap: () {}),
          ProfileFieldItemWidget(label: 'Senha', onTap: onEditPassword),
        ],
      ),
      const Spacer(),
      ProfileAccountActionsWidget(
        onDelete: onDelete,
        onDeactivate: onDeactivate,
        isDeactivating: detailsState.status == .loading,
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

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showConfirmDialog(
      context: context,
      title: 'Excluir conta',
      confirmLabel: 'Excluir',
      description:
          'Esta ação é irreversível.\n\n - Todos os seus dados financeiros serão apagados e você não poderá recuperá-los.',
    );
    if (!confirmed) return;
  }

  Future<void> _confirmDeactivate(
    BuildContext context,
    ProfileDetailsNotifier notifier,
  ) async {
    final confirmed = await showConfirmDialog(
      context: context,
      title: 'Desativar conta',
      confirmLabel: 'Desativar',
      description:
          'Sua conta ficará desativada e seus dados ficarão preservados.\n\n - Você poderá reativá-la fazendo login novamente.',
    );
    if (!confirmed) return;

    notifier.dispatch(const DeactivatePressed());
  }
}
