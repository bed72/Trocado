import 'package:flutter/widgets.dart';

import 'package:trocado/src/presentation/constants/assets_constant.dart';
import 'package:trocado/src/domain/models/transaction_model.dart';
import 'package:trocado/src/presentation/extensions/context_extension.dart';
import 'package:trocado/src/presentation/widgets/images/image_widget.dart';

class HomeEmptyWidget extends StatelessWidget {
  final TransactionTypeModel? type;

  const HomeEmptyWidget({super.key, this.type});

  @override
  Widget build(BuildContext context) {
    return switch (type) {
      null => _buildTotal(context),
      .income => _buildIncome(context),
      .expense => _buildExpense(context),
    };
  }

  Center _buildTotal(BuildContext context) => Center(
    child: Column(
      spacing: 8.0,
      mainAxisSize: .min,
      children: [
        ImageWidget(height: 220.0, source: AssetsConstant.breaking.source),
        Text(
          'Nenhuma transação por aqui 👀',
          textAlign: .center,
          style: context.typography.titleMedium?.copyWith(
            fontWeight: .w800,
            color: context.colors.onSurface.withValues(alpha: 0.8),
          ),
        ),
        Text(
          'Comece adicionando suas receitas ou despesasque elas vão aparecer aqui rapidinho.',
          textAlign: .center,
          style: context.typography.bodyMedium?.copyWith(
            fontWeight: .w600,
            color: context.colors.onSurfaceVariant.withValues(alpha: 0.6),
          ),
        ),
      ],
    ),
  );

  Center _buildIncome(BuildContext context) => Center(
    child: Column(
      spacing: 8.0,
      mainAxisSize: .min,
      children: [
        ImageWidget(height: 220.0, source: AssetsConstant.scope.source),
        Text(
          'Nada de entradas ainda 💼',
          textAlign: .center,
          style: context.typography.titleMedium?.copyWith(
            fontWeight: .w800,
            color: context.colors.onSurface.withValues(alpha: 0.8),
          ),
        ),
        Text(
          'Quando cair um pix, salário ou qualquer ganho, registre para ele aparecer aqui.',
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
