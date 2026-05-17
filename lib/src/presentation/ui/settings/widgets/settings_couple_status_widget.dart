import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:trocado/src/presentation/widgets/cards/inline_failure_card_widget.dart';

import 'package:trocado/src/presentation/ui/settings/data/couple_card_state.dart';
import 'package:trocado/src/presentation/ui/settings/notifiers/couple_notifier.dart';
import 'package:trocado/src/presentation/ui/settings/widgets/settings_invite_partner_widget.dart';
import 'package:trocado/src/presentation/ui/settings/widgets/settings_couple_connected_widget.dart';
import 'package:trocado/src/presentation/ui/settings/widgets/settings_couple_loading_widget.dart';

class SettingsCoupleStatusWidget extends StatelessWidget {
  final VoidCallback onInvitePartner;
  final VoidCallback onCoupleDetails;

  const SettingsCoupleStatusWidget({
    super.key,
    required this.onInvitePartner,
    required this.onCoupleDetails,
  });

  @override
  Widget build(BuildContext context) => Consumer(
    builder: (_, ref, _) {
      final state = ref.watch(coupleProvider);

      return switch (state) {
        AsyncData(value: CoupleConnectedState(:final data)) =>
          SettingsCoupleConnectedWidget(data: data, onTap: onCoupleDetails),
        AsyncData(value: CoupleNoneState()) => SettingsInvitePartnerWidget(
          onTap: onInvitePartner,
        ),
        AsyncData(value: CoupleFailureState(:final message)) =>
          InlineFailureCardWidget(
            message: message,
            onRetry: () => ref.invalidate(coupleProvider),
          ),
        _ => const SettingsCoupleLoadingWidget(),
      };
    },
  );
}
