import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:trocado/src/presentation/notifiers/user_notifier.dart';

import 'package:trocado/src/presentation/widgets/app_bar_widget.dart';
import 'package:trocado/src/presentation/widgets/go_back_widget.dart';
import 'package:trocado/src/presentation/widgets/scaffold_widget.dart';
import 'package:trocado/src/presentation/widgets/screen_header_widget.dart';

import 'package:trocado/src/presentation/ui/partner/widgets/partner_invite_hero_widget.dart';
import 'package:trocado/src/presentation/ui/partner/widgets/partner_pair_indicator_widget.dart';
import 'package:trocado/src/presentation/ui/partner/widgets/partner_invite_actions_widget.dart';
import 'package:trocado/src/presentation/ui/partner/widgets/partner_invite_security_note_widget.dart';

class PartnerInviteScreen extends StatelessWidget {
  final VoidCallback onGenerate;

  const PartnerInviteScreen({super.key, required this.onGenerate});

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
              PartnerPairIndicatorWidget(userState: userState),
              const PartnerInviteHeroWidget(),
              const Spacer(),
              const PartnerInviteSecurityNoteWidget(),
              PartnerInviteActionsWidget(onGenerate: onGenerate, onScan: () {}),
            ],
          );
        },
      ),
    ),
  );
}
