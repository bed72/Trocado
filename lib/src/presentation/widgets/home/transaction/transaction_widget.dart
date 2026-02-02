import 'package:flutter/material.dart';

import 'package:trocado/src/domain/models/category_model.dart';
import 'package:trocado/src/domain/models/transaction_model.dart';

import 'package:trocado/src/presentation/extensions/context_extension.dart';
import 'package:trocado/src/presentation/notifiers/swipe_radius_notifier.dart';

import 'package:trocado/src/presentation/widgets/bounce_widget.dart';
import 'package:trocado/src/presentation/widgets/icons/icon_widget.dart';
import 'package:trocado/src/presentation/widgets/icons/background_icon_widget.dart';

class TransactionWidget extends StatefulWidget {
  final TransactionModel model;
  final ValueChanged<int> onDelete;
  final ValueChanged<int?> onPress;
  final String Function(double) format;

  const TransactionWidget({
    super.key,
    required this.model,
    required this.format,
    required this.onPress,
    required this.onDelete,
  });

  @override
  State<TransactionWidget> createState() => _TransactionWidgetState();
}

class _TransactionWidgetState extends State<TransactionWidget> {
  late final SwipeRadiusNotifier _notifier;

  @override
  void initState() {
    super.initState();

    _notifier = SwipeRadiusNotifier();
  }

  @override
  void dispose() {
    _notifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isIncome = widget.model.type == TransactionTypeModel.income.label;
    final prefix = isIncome ? '+' : '-';
    final color = isIncome ? context.colors.primary : context.colors.error;

    return BounceWidget.withOnPress(
      onPress: () => widget.onPress(widget.model.id),
      child: Padding(
        padding: const .only(bottom: 8.0),
        child: Dismissible(
          direction: .endToStart,
          key: ValueKey(widget.model.id),
          background: _buildBackground(),
          onDismissed: (_) => widget.onDelete(widget.model.id!),
          onUpdate: (details) => _notifier.update(details.progress),
          child: ValueListenableBuilder<double>(
            valueListenable: _notifier.progress,
            builder: (_, _, child) => ClipRRect(
              borderRadius: .only(
                topLeft: const .circular(20),
                bottomLeft: const .circular(20),
                topRight: .circular(_notifier.radius),
                bottomRight: .circular(_notifier.radius),
              ),
              child: child,
            ),
            child: _buildContent(color: color, prefix: prefix),
          ),
        ),
      ),
    );
  }

  Container _buildContent({required String prefix, required Color color}) =>
      Container(
        margin: .zero,
        color: context.colors.surfaceContainer,
        child: ListTile(
          leading: BackgroundIconWidget(
            icon: CategoryModel.fromByString(widget.model.category).icon,
            color: CategoryModel.fromByString(widget.model.category).color,
          ),
          title: Text(
            widget.model.description,
            style: context.typography.bodyLarge?.copyWith(fontWeight: .w600),
          ),
          subtitle: Text(
            widget.model.category,
            style: context.typography.labelSmall?.copyWith(
              fontWeight: .w600,
              letterSpacing: 0.5,
              color: context.colors.onSurfaceVariant.withValues(alpha: 0.8),
            ),
          ),
          trailing: Text(
            '$prefix ${widget.format(widget.model.amount)}',
            style: context.typography.titleMedium?.copyWith(
              color: color,
              fontWeight: .bold,
              fontFeatures: const [.tabularFigures()],
            ),
          ),
        ),
      );

  Container _buildBackground() => Container(
    alignment: .centerRight,
    padding: const .only(right: 20.0),
    decoration: BoxDecoration(
      color: context.colors.error.withValues(alpha: 0.2),
      borderRadius: const .only(
        topRight: .circular(20.0),
        bottomRight: .circular(20.0),
      ),
    ),
    child: IconWidget(icon: Icons.delete, color: context.colors.error),
  );
}
