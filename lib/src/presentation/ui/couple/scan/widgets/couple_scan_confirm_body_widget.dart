import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:trocado/src/presentation/extensions/context_extension.dart';

import 'package:trocado/src/presentation/widgets/toast_widget.dart';
import 'package:trocado/src/presentation/widgets/buttons/button_widget.dart';

import 'package:trocado/src/presentation/ui/couple/scan/notifiers/couple_scan_confirm_intent.dart';
import 'package:trocado/src/presentation/ui/couple/scan/notifiers/couple_scan_confirm_notifier.dart';

class CoupleScanConfirmBodyWidget extends StatelessWidget {
  final String code;

  const CoupleScanConfirmBodyWidget({super.key, required this.code});

  @override
  Widget build(BuildContext context) => Consumer(
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
      final isLoading = state.status == .loading;

      return PopScope(
        canPop: !isLoading,
        child: Column(
          mainAxisSize: .min,
          crossAxisAlignment: .stretch,
          children: [
            const SizedBox(height: 8.0),
            Center(
              child: Text(
                code,
                style: context.typography.headlineMedium?.copyWith(
                  fontWeight: .w600,
                  letterSpacing: 4.0,
                ),
              ),
            ),
            const SizedBox(height: 24.0),
            ButtonWidget.elevated(
              label: 'Aceitar convite',
              isLoading: isLoading,
              onTap: isLoading
                  ? null
                  : () => notifier.dispatch(AcceptPressed(code)),
            ),
          ],
        ),
      );
    },
  );

  void _onSuccess(BuildContext context, String partnerName) {
    showToastWidget(
      context: context,
      type: .success,
      title: 'Pronto',
      description: 'Você está conectado com $partnerName.',
    );
    Navigator.of(context, rootNavigator: true).pop();
    context.root();
  }

  void _onFailure(BuildContext context, String message) => showToastWidget(
    context: context,
    title: 'Opps',
    type: .failure,
    description: message,
  );
}
