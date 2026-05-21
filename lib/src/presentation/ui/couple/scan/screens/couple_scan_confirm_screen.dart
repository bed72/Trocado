import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:trocado/src/presentation/extensions/context_extension.dart';

import 'package:trocado/src/presentation/widgets/toast_widget.dart';
import 'package:trocado/src/presentation/widgets/app_bar_widget.dart';
import 'package:trocado/src/presentation/widgets/go_back_widget.dart';
import 'package:trocado/src/presentation/widgets/scaffold_widget.dart';
import 'package:trocado/src/presentation/widgets/screen_header_widget.dart';
import 'package:trocado/src/presentation/widgets/buttons/button_widget.dart';

import 'package:trocado/src/presentation/ui/couple/scan/notifiers/couple_scan_confirm_intent.dart';
import 'package:trocado/src/presentation/ui/couple/scan/notifiers/couple_scan_confirm_notifier.dart';

class CoupleScanConfirmScreen extends StatelessWidget {
  final String code;

  const CoupleScanConfirmScreen({super.key, required this.code});

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
                _onSuccess(context, next.partnerName);
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
                description: 'Confira o código do convite antes de aceitar.',
              ),
              Center(
                child: Text(
                  code,
                  style: context.typography.headlineMedium?.copyWith(
                    fontWeight: .w600,
                    letterSpacing: 4.0,
                  ),
                ),
              ),
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

  void _onSuccess(BuildContext context, String partnerName) {
    showToastWidget(
      context: context,
      type: .success,
      title: 'Pronto',
      description: 'Você está conectado com $partnerName.',
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
