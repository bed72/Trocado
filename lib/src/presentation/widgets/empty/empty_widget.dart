import 'package:flutter/widgets.dart';

import 'package:trocado/src/presentation/constants/assets_constant.dart';
import 'package:trocado/src/presentation/widgets/images/image_widget.dart';
import 'package:trocado/src/presentation/extensions/context_extension.dart';

enum EmptyWidgetType { budget, expense }

class EmptyWidget extends StatelessWidget {
  final EmptyWidgetType? type;

  const EmptyWidget({super.key, this.type});

  @override
  Widget build(BuildContext context) {
    return switch (type) {
      .budget => _buildBudget(context),
      .expense => _buildExpense(context),
      null => const SizedBox.shrink(),
    };
  }

  Center _buildBudget(BuildContext context) => Center(
    child: Column(
      spacing: 8.0,
      mainAxisSize: .min,
      children: [
        ImageWidget(height: 220.0, source: AssetsConstant.breaking.source),
        Text(
          'Nenhum orcamento por aqui 👀',
          textAlign: .center,
          style: context.typography.titleMedium?.copyWith(
            fontWeight: .w800,
            color: context.colors.onSurface.withValues(alpha: 0.8),
          ),
        ),
        Text(
          'Comece adicionando seu orçamento mensal é rapidinho.',
          textAlign: .center,
          style: context.typography.bodyMedium?.copyWith(
            fontWeight: .w600,
            color: context.colors.onSurfaceVariant.withValues(alpha: 0.6),
          ),
        ),
      ],
    ),
  );

  Center _buildExpense(BuildContext context) => Center(
    child: Column(
      spacing: 8.0,
      mainAxisSize: .min,
      children: [
        ImageWidget(height: 220.0, source: AssetsConstant.iceberg.source),
        Text(
          'Caramba, zero gastos! 🎉',
          textAlign: .center,
          style: context.typography.titleMedium?.copyWith(
            fontWeight: .w800,
            color: context.colors.onSurface.withValues(alpha: 0.8),
          ),
        ),
        Text(
          'Mandou bem demais! Quando pintar alguma despesa, registre ela para aparecer aqui.',
          textAlign: .center,
          style: context.typography.bodyMedium?.copyWith(
            fontWeight: .w600,
            color: context.colors.onSurfaceVariant.withValues(alpha: 0.6),
          ),
        ),
      ],
    ),
  );
}
