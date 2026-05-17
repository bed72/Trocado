import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

import 'package:trocado/src/presentation/ui/settings/data/couple_card_presentation_data.dart';
import 'package:trocado/src/presentation/ui/settings/widgets/settings_couple_connected_widget.dart';

class SettingsCoupleLoadingWidget extends StatelessWidget {
  const SettingsCoupleLoadingWidget({super.key});

  @override
  Widget build(BuildContext context) => Skeletonizer(
    child: SettingsCoupleConnectedWidget(data: _placeholder, onTap: () {}),
  );
}

const _placeholder = CoupleCardPresentationData(
  title: 'Gabriel & Marina',
  subtitle: 'Conectados há 4 meses',
  currentUserInitial: 'G',
  partnerInitial: 'M',
);
