import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:trocado/src/domain/models/user_model.dart';

import 'package:trocado/src/presentation/extensions/context_extension.dart';

import 'package:trocado/src/presentation/widgets/avatar/avatar_widget.dart';

import 'package:trocado/src/presentation/ui/partner/widgets/painters/dashed_line_painter.dart';
import 'package:trocado/src/presentation/ui/partner/widgets/painters/dashed_rounded_rect_painter.dart';

class PartnerPairIndicatorWidget extends StatelessWidget {
  static const double _slotSize = 72.0;
  static const double _connectorWidth = 56.0;
  static const double _connectorHeight = 2.0;

  final AsyncValue<UserModel> userState;

  const PartnerPairIndicatorWidget({super.key, required this.userState});

  @override
  Widget build(BuildContext context) {
    final isLoading = userState is AsyncLoading;
    final user = switch (userState) {
      AsyncData(:final value) => value,
      _ => null,
    };

    return Skeletonizer(
      enabled: isLoading,
      child: Row(
        mainAxisAlignment: .center,
        children: [
          AvatarWidget(size: _slotSize, name: user?.name ?? 'Carregando'),
          SizedBox(
            width: _connectorWidth,
            height: _connectorHeight,
            child: CustomPaint(
              painter: DashedLinePainter(
                dashGap: 4.0,
                dashLength: 6.0,
                strokeWidth: _connectorHeight,
                color: context.colors.outlineVariant,
              ),
            ),
          ),
          _buildEmptySlot(context),
        ],
      ),
    );
  }

  Widget _buildEmptySlot(BuildContext context) => SizedBox(
    width: _slotSize,
    height: _slotSize,
    child: CustomPaint(
      painter: DashedRoundedRectPainter(
        dashGap: 4.0,
        dashLength: 6.0,
        strokeWidth: 1.5,
        color: context.colors.outlineVariant,
        radius: context.radius.cornerRadius100.topLeft,
      ),
      child: Center(
        child: Icon(
          Icons.person_add_alt,
          size: 28.0,
          color: context.colors.onSurfaceVariant,
        ),
      ),
    ),
  );
}
