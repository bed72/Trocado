import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

import 'package:trocado/src/presentation/extensions/context_extension.dart';

class SettingsCoupleLoadingWidget extends StatelessWidget {
  static const double _avatarSize = 40.0;

  const SettingsCoupleLoadingWidget({super.key});

  @override
  Widget build(BuildContext context) => Skeletonizer(
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
            Container(
              width: _avatarSize,
              height: _avatarSize,
              alignment: .center,
              decoration: BoxDecoration(
                borderRadius: context.radius.cornerRadius100,
                color: context.colors.primary,
              ),
              child: Text(
                'G',
                style: context.typography.titleMedium?.copyWith(
                  fontWeight: .w800,
                  color: context.colors.onPrimary,
                ),
              ),
            ),
            Expanded(
              child: Column(
                spacing: 2.0,
                mainAxisSize: .min,
                crossAxisAlignment: .start,
                children: [
                  Text(
                    'Gabriel & Marina',
                    maxLines: 1,
                    overflow: .ellipsis,
                    style: context.typography.bodyMedium?.copyWith(
                      fontWeight: .bold,
                      color: context.colors.onSecondaryContainer,
                    ),
                  ),
                  Text(
                    'Conectados há 4 meses',
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
