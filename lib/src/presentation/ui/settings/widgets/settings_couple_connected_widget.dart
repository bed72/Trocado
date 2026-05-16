import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/extensions/context_extension.dart';

import 'package:trocado/src/presentation/widgets/bounce_widget.dart';
import 'package:trocado/src/presentation/widgets/avatar/avatar_pair_widget.dart';

import 'package:trocado/src/presentation/ui/settings/data/couple_card_presentation_data.dart';

class SettingsCoupleConnectedWidget extends StatelessWidget {
  final VoidCallback onTap;
  final CoupleCardPresentationData data;

  const SettingsCoupleConnectedWidget({
    super.key,
    required this.data,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => BounceWidget.withOnPress(
    onPress: onTap,
    child: Card(
      margin: .zero,
      elevation: 0.0,
      clipBehavior: .antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: context.radius.cornerRadius100,
      ),
      child: Padding(
        padding: const .all(12.0),
        child: Row(
          spacing: 12.0,
          crossAxisAlignment: .center,
          children: [
            AvatarPairWidget(
              secondInitial: data.partnerInitial,
              firstInitial: data.currentUserInitial,
            ),
            Expanded(
              child: Column(
                spacing: 2.0,
                mainAxisSize: .min,
                crossAxisAlignment: .start,
                children: [
                  Text(
                    data.title,
                    maxLines: 1,
                    overflow: .ellipsis,
                    style: context.typography.bodyMedium?.copyWith(
                      fontWeight: .bold,
                      color: context.colors.onSecondaryContainer,
                    ),
                  ),
                  Text(
                    data.subtitle,
                    maxLines: 1,
                    overflow: .ellipsis,
                    style: context.typography.bodySmall?.copyWith(
                      color: context.colors.onSecondaryContainer,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 24.0,
              color: context.colors.onSecondaryContainer,
            ),
          ],
        ),
      ),
    ),
  );
}
