import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/extensions/context_extension.dart';

import 'package:trocado/src/presentation/widgets/avatar/avatar_widget.dart';
import 'package:trocado/src/presentation/widgets/painters/dashed_line_painter.dart';

class CoupleDissolvePairWidget extends StatelessWidget {
  static const double _badgeGap = 4.0;
  static const double _slotSize = 72.0;
  static const double _iconSize = 16.0;
  static const double _badgeSize = 28.0;
  static const double _segmentWidth = 32.0;
  static const double _connectorHeight = 2.0;

  final String partnerName;
  final String currentUserName;

  const CoupleDissolvePairWidget({
    super.key,
    required this.partnerName,
    required this.currentUserName,
  });

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: .center,
    children: [
      AvatarWidget(size: _slotSize, name: currentUserName),
      _segment(context),
      const SizedBox(width: _badgeGap),
      _badge(context),
      const SizedBox(width: _badgeGap),
      _segment(context),
      AvatarWidget(size: _slotSize, name: partnerName),
    ],
  );

  Widget _segment(BuildContext context) => SizedBox(
    width: _segmentWidth,
    height: _connectorHeight,
    child: CustomPaint(
      painter: DashedLinePainter(
        dashGap: 4.0,
        dashLength: 6.0,
        strokeWidth: _connectorHeight,
        color: context.colors.outlineVariant,
      ),
    ),
  );

  Widget _badge(BuildContext context) => Container(
    width: _badgeSize,
    height: _badgeSize,
    alignment: .center,
    decoration: BoxDecoration(
      shape: .circle,
      color: context.colors.surface,
      border: .all(color: context.colors.error, width: 1.5),
    ),
    child: Icon(Icons.close, size: _iconSize, color: context.colors.error),
  );
}
