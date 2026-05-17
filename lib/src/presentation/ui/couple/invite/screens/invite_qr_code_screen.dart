import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:trocado/src/presentation/widgets/app_bar_widget.dart';
import 'package:trocado/src/presentation/widgets/go_back_widget.dart';
import 'package:trocado/src/presentation/widgets/scaffold_widget.dart';
import 'package:trocado/src/presentation/widgets/screen_header_widget.dart';

import 'package:trocado/src/presentation/widgets/buttons/button_widget.dart';

import 'package:trocado/src/presentation/ui/couple/invite/widgets/invite_qr_card_widget.dart';
import 'package:trocado/src/presentation/ui/couple/invite/notifiers/invite_qr_code_notifier.dart';
import 'package:trocado/src/presentation/ui/couple/invite/widgets/invite_qr_code_loading_widget.dart';
import 'package:trocado/src/presentation/ui/couple/invite/widgets/invite_qr_code_failure_widget.dart';

class InviteQrCodeScreen extends StatelessWidget {
  const InviteQrCodeScreen({super.key});

  @override
  Widget build(BuildContext context) => ScaffoldWidget(
    appBar: AppBarWidget(leading: GoBackWidget()),
    child: Padding(
      padding: const .all(16.0),
      child: Consumer(
        builder: (_, ref, _) {
          final state = ref.watch(inviteQrCodeProvider);
          final notifier = ref.read(inviteQrCodeProvider.notifier);

          return Column(
            crossAxisAlignment: .stretch,
            spacing: 24.0,
            children: [
              const ScreenHeaderWidget(
                title: 'Convite',
                description: 'Mostre o QR code para seu par escanear.',
              ),
              Expanded(
                child: switch (state) {
                  AsyncLoading() => const Center(
                    child: InviteQrCodeLoadingWidget(),
                  ),
                  AsyncError() => InviteQrCodeFailureWidget(
                    onRetry: notifier.retry,
                  ),
                  AsyncData(:final value) => Center(
                    child: InviteQrCardWidget(data: value),
                  ),
                },
              ),
              ButtonWidget.elevated(
                label: 'Compartilhar',
                onTap: state is AsyncData ? notifier.share : null,
              ),
            ],
          );
        },
      ),
    ),
  );
}
