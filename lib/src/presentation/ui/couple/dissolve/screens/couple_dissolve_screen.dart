import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:trocado/src/presentation/extensions/context_extension.dart';

import 'package:trocado/src/presentation/widgets/toast_widget.dart';
import 'package:trocado/src/presentation/widgets/app_bar_widget.dart';
import 'package:trocado/src/presentation/widgets/go_back_widget.dart';
import 'package:trocado/src/presentation/widgets/scaffold_widget.dart';
import 'package:trocado/src/presentation/widgets/screen_header_widget.dart';
import 'package:trocado/src/presentation/widgets/buttons/button_widget.dart';
import 'package:trocado/src/presentation/widgets/dialog/confirm_dialog_widget.dart';
import 'package:trocado/src/presentation/widgets/cards/inline_failure_card_widget.dart';

import 'package:trocado/src/presentation/ui/couple/widgets/couple_note_widget.dart';
import 'package:trocado/src/presentation/ui/couple/dissolve/notifiers/couple_dissolve_state.dart';
import 'package:trocado/src/presentation/ui/couple/dissolve/notifiers/couple_dissolve_intent.dart';
import 'package:trocado/src/presentation/ui/couple/dissolve/notifiers/couple_dissolve_notifier.dart';
import 'package:trocado/src/presentation/ui/couple/dissolve/widgets/couple_dissolve_pair_widget.dart';
import 'package:trocado/src/presentation/ui/couple/dissolve/widgets/couple_dissolve_hero_widget.dart';

class CoupleDissolveScreen extends StatelessWidget {
  const CoupleDissolveScreen({super.key});

  @override
  Widget build(BuildContext context) => ScaffoldWidget(
    appBar: AppBarWidget(leading: GoBackWidget()),
    child: Padding(
      padding: const .all(16.0),
      child: Consumer(
        builder: (_, ref, _) {
          ref.listen(coupleDissolveProvider, (previous, next) {
            final previousStatus = previous?.value?.status;
            final nextStatus = next.value?.status;

            return switch (nextStatus) {
              .success when previousStatus != .success => context.pop(),
              .failure when previousStatus != .failure => showToastWidget(
                context: context,
                title: 'Opps',
                type: .failure,
                description: next.value?.message ?? '',
              ),
              _ => null,
            };
          });

          final state = ref.watch(coupleDissolveProvider);
          final notifier = ref.read(coupleDissolveProvider.notifier);

          return switch (state) {
            AsyncData(:final value) => _buildBody(context, value, notifier),
            AsyncError() => InlineFailureCardWidget(
              message: 'Não conseguimos carregar.',
              onRetry: () => ref.invalidate(coupleDissolveProvider),
            ),
            _ => const Center(child: CircularProgressIndicator()),
          };
        },
      ),
    ),
  );

  Widget _buildBody(
    BuildContext context,
    CoupleDissolveState state,
    CoupleDissolveNotifier notifier,
  ) => Column(
    spacing: 32.0,
    crossAxisAlignment: .start,
    children: [
      const ScreenHeaderWidget(
        title: 'Desfazer casal',
        description: 'Encerre a conexão com seu parceiro.',
      ),
      const Spacer(),
      CoupleDissolvePairWidget(
        currentUserName: state.currentUserName,
        partnerName: state.partnerName,
      ),
      const CoupleDissolveHeroWidget(),
      const Spacer(),
      const CoupleNoteWidget(
        icon: Icons.history,
        message:
            'Vocês podem se reconectar a qualquer momento por um novo convite.',
      ),
      SizedBox(
        width: .infinity,
        child: ButtonWidget.danger(
          label: 'Desfazer casal',
          isLoading: state.status == .loading,
          onTap: () => _submit(context, notifier),
        ),
      ),
    ],
  );

  Future<void> _submit(
    BuildContext context,
    CoupleDissolveNotifier notifier,
  ) async {
    final confirmed = await showConfirmDialog(
      context: context,
      title: 'Desfazer casal',
      confirmLabel: 'Desfazer',
      description:
          'Tem certeza? Vocês deixarão de compartilhar despesas e orçamentos imediatamente.',
    );
    if (!confirmed) return;

    notifier.dispatch(const DissolvePressed());
  }
}
