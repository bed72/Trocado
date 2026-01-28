import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import 'package:trocado/modules/core/core.dart';

class CalculatorKeyboard extends StatelessWidget {
  final void Function(String) onKeyTap;

  const CalculatorKeyboard({super.key, required this.onKeyTap});

  @override
  Widget build(BuildContext context) {
    final background = context.colors.secondaryContainer;

    return StaggeredGrid.count(
      crossAxisCount: 4,
      mainAxisSpacing: 4,
      crossAxisSpacing: 4,
      children: [
        _buildTile(context: context, label: '7'),
        _buildTile(context: context, label: '8'),
        _buildTile(context: context, label: '9'),
        _buildTile(context: context, label: 'DEL', background: background),

        _buildTile(context: context, label: '4'),
        _buildTile(context: context, label: '5'),
        _buildTile(context: context, label: '6'),
        _buildTile(context: context, label: 'AC', background: background),

        _buildTile(context: context, label: '1'),
        _buildTile(context: context, label: '2'),
        _buildTile(context: context, label: '3'),
        _buildTile(
          context: context,
          label: '✓',
          background: background,
          rowSpan: 2,
        ),

        _buildTile(context: context, label: '0', columnSpan: 2),
        _buildTile(context: context, label: ','),
      ],
    );
  }

  StaggeredGridTile _buildTile({
    required BuildContext context,
    required String label,
    int rowSpan = 1,
    int columnSpan = 1,
    Color? background,
  }) => StaggeredGridTile.count(
    mainAxisCellCount: rowSpan,
    crossAxisCellCount: columnSpan,
    child: _buildKey(context: context, label: label, background: background),
  );

  BounceWidget _buildKey({
    required BuildContext context,
    required String label,
    Color? background,
  }) => BounceWidget.withTap(
    onTap: () => onKeyTap(label),
    child: Container(
      decoration: BoxDecoration(
        borderRadius: context.radius.cornerRadius300,
        color: background ?? context.colors.outlineVariant,
      ),
      child: Center(
        child: Text(
          label,
          style: context.typography.bodyLarge?.copyWith(
            fontWeight: .w800,
            color: context.colors.onSurfaceVariant.withValues(alpha: 0.8),
          ),
        ),
      ),
    ),
  );
}
