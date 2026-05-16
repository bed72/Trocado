import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:trocado/src/presentation/ui/settings/notifiers/couple_notifier.dart';
import 'package:trocado/src/presentation/ui/settings/widgets/settings_invite_partner_widget.dart';
import 'package:trocado/src/presentation/ui/settings/widgets/settings_couple_connected_widget.dart';

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
        AsyncData(:final value) when value != null =>
          SettingsCoupleConnectedWidget(data: value, onTap: onCoupleDetails),
        _ => SettingsInvitePartnerWidget(onTap: onInvitePartner),
      };
    },
  );
}
