import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/notifiers/data/month_data.dart';
import 'package:trocado/src/presentation/extensions/context_extension.dart';
import 'package:trocado/src/presentation/widgets/buttons/icon_button_widget.dart';

class MonthSelectorWidget extends StatelessWidget {
  final MonthData month;
  final VoidCallback onNext;
  final VoidCallback onPrevious;

  const MonthSelectorWidget({
    super.key,
    required this.month,
    required this.onNext,
    required this.onPrevious,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: .spaceBetween,
      children: [
        _buildIcon(onPress: onPrevious, icon: Icons.chevron_left_rounded),
        Text(
          month.label,
          style: context.typography.titleMedium?.copyWith(fontWeight: .w800),
        ),
        _buildIcon(onPress: onNext, icon: Icons.chevron_right_rounded),
      ],
    );
  }

  IconButtonWidget _buildIcon({
    required IconData icon,
    required VoidCallback onPress,
  }) => IconButtonWidget(
    icon: icon,
    width: 36.0,
    height: 36.0,
    iconSize: 22.0,
    onPress: onPress,
    borderRadius: .circular(12.0),
  );
}
