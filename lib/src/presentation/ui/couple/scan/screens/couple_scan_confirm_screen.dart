import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:trocado/src/domain/models/couple/invite_lookup_model.dart';

import 'package:trocado/src/presentation/extensions/context_extension.dart';

import 'package:trocado/src/presentation/widgets/toast_widget.dart';
import 'package:trocado/src/presentation/widgets/app_bar_widget.dart';
import 'package:trocado/src/presentation/widgets/go_back_widget.dart';
import 'package:trocado/src/presentation/widgets/scaffold_widget.dart';
import 'package:trocado/src/presentation/widgets/screen_header_widget.dart';
import 'package:trocado/src/presentation/widgets/buttons/button_widget.dart';

import 'package:trocado/src/presentation/ui/couple/scan/notifiers/couple_scan_confirm_intent.dart';
import 'package:trocado/src/presentation/ui/couple/scan/notifiers/couple_scan_confirm_notifier.dart';
import 'package:trocado/src/presentation/ui/couple/scan/widgets/couple_scan_partner_preview_widget.dart';

class CoupleScanConfirmScreen extends StatelessWidget {
  final String code;
  final InviteLookupModel lookup;

  const CoupleScanConfirmScreen({
    super.key,
    required this.code,
    required this.lookup,
  });

  @override
  Widget build(BuildContext context) => ScaffoldWidget(
    appBar: AppBarWidget(leading: GoBackWidget()),
    child: Padding(
      padding: const .all(16.0),
      child: Consumer(
        builder: (_, ref, _) {
          ref.listen(coupleScanConfirmProvider, (previous, next) {
            switch (next.status) {
              case .success when previous?.status != .success:
                _onSuccess(context);
              case .failure when previous?.status != .failure:
                _onFailure(context, next.message);
              default:
            }
          });

          final state = ref.watch(coupleScanConfirmProvider);
          final notifier = ref.read(coupleScanConfirmProvider.notifier);

          return Column(
            spacing: 24.0,
            crossAxisAlignment: .start,
            children: [
              const ScreenHeaderWidget(
                title: 'Confirmar união',
                description:
                    'Confira os dados do seu par e confirme para começar a compartilhar finanças.',
              ),
              CoupleScanPartnerPreviewWidget(partner: lookup.partner),
              const Spacer(),
              SizedBox(
                width: .infinity,
                child: ButtonWidget.elevated(
                  label: 'Aceitar convite',
                  isLoading: state.status == .loading,
                  onTap: state.status == .loading
                      ? null
                      : () => notifier.dispatch(AcceptPressed(code)),
                ),
              ),
            ],
          );
        },
      ),
    ),
  );

  void _onSuccess(BuildContext context) {
    showToastWidget(
      context: context,
      type: .success,
      title: 'Pronto',
      description: 'Vocês estão conectados.',
    );
    context.root();
  }

  void _onFailure(BuildContext context, String message) => showToastWidget(
    context: context,
    title: 'Opps',
    type: .failure,
    description: message,
  );
}
