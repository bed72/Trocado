import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:trocado/src/presentation/notifiers/user_notifier.dart';

import 'package:trocado/src/presentation/widgets/app_bar_widget.dart';
import 'package:trocado/src/presentation/widgets/go_back_widget.dart';
import 'package:trocado/src/presentation/widgets/scaffold_widget.dart';
import 'package:trocado/src/presentation/widgets/screen_header_widget.dart';

import 'package:trocado/src/presentation/ui/couple/widgets/couple_note_widget.dart';
import 'package:trocado/src/presentation/ui/couple/invite/widgets/couple_invite_hero_widget.dart';
import 'package:trocado/src/presentation/ui/couple/invite/widgets/couple_pair_indicator_widget.dart';
import 'package:trocado/src/presentation/ui/couple/invite/widgets/couple_invite_actions_widget.dart';

class CoupleInviteScreen extends StatelessWidget {
  final VoidCallback onScan;
  final VoidCallback onGenerate;

  const CoupleInviteScreen({
    super.key,
    required this.onScan,
    required this.onGenerate,
  });

  @override
  Widget build(BuildContext context) => ScaffoldWidget(
    appBar: AppBarWidget(leading: GoBackWidget()),
    child: Padding(
      padding: const .all(16.0),
      child: Consumer(
        builder: (_, ref, _) {
          final userState = ref.watch(userProvider);

          return Column(
            spacing: 32.0,
            crossAxisAlignment: .start,
            children: [
              const ScreenHeaderWidget(
                title: 'Casal',
                description: 'Vocês dois, uma única visão.',
              ),
              const Spacer(),
              CouplePairIndicatorWidget(userState: userState),
              const CoupleInviteHeroWidget(),
              const Spacer(),
              const CoupleNoteWidget(
                icon: Icons.shield_outlined,
                message:
                    'Vocês compartilham orçamentos e despesas, mas senhas e dados de login são individuais.',
              ),
              CoupleInviteActionsWidget(onGenerate: onGenerate, onScan: onScan),
            ],
          );
        },
      ),
    ),
  );
}
