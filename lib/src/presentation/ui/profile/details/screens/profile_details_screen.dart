import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:trocado/src/domain/failures/failure.dart';
import 'package:trocado/src/domain/models/user_model.dart';

import 'package:trocado/src/presentation/notifiers/user_notifier.dart';

import 'package:trocado/src/presentation/widgets/app_bar_widget.dart';
import 'package:trocado/src/presentation/widgets/go_back_widget.dart';
import 'package:trocado/src/presentation/widgets/scaffold_widget.dart';
import 'package:trocado/src/presentation/widgets/screen_header_widget.dart';
import 'package:trocado/src/presentation/widgets/buttons/button_widget.dart';

import 'package:trocado/src/presentation/ui/profile/details/widgets/profile_header_widget.dart';
import 'package:trocado/src/presentation/ui/profile/details/widgets/profile_field_item_widget.dart';
import 'package:trocado/src/presentation/ui/profile/details/widgets/profile_fields_card_widget.dart';
import 'package:trocado/src/presentation/ui/profile/details/widgets/profile_delete_account_widget.dart';

class ProfileDetailsScreen extends StatelessWidget {
  final VoidCallback onPurge;
  final VoidCallback onEditName;
  final VoidCallback onEditPassword;

  const ProfileDetailsScreen({
    super.key,
    required this.onPurge,
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
          final userState = ref.watch(userProvider);

          return switch (userState) {
            AsyncData(:final value) => _buildBody(
              user: value,
              onDelete: onPurge,
            ),
            AsyncError(:final error) => _buildError(
              failure: error is Failure ? error : const UnknownFailure(),
              onRetry: () => ref.invalidate(userProvider),
            ),
            _ => Skeletonizer(
              enabled: true,
              child: _buildBody(
                onDelete: () {},
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
      ProfileDeleteAccountWidget(onTap: onDelete),
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
