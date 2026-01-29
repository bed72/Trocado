import 'package:flutter/material.dart';

import 'package:trocado/modules/core/core.dart';
import 'package:trocado/modules/transaction/transaction.dart';

import 'package:trocado/modules/home/presentation/notifiers/swipe_radius_notifier.dart';

class TransactionWidget extends StatefulWidget {
  final TransactionDto dto;
  final ValueChanged<int> onDelete;
  final ValueChanged<int?> onPress;
  final String Function(double) format;

  const TransactionWidget({
    super.key,
    required this.dto,
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
    final isIncome = widget.dto.type == .income;

    final prefix = isIncome ? '+' : '-';
    final color = isIncome ? context.colors.primary : context.colors.error;

    return BounceWidget.withTap(
      onTap: () => widget.onPress(widget.dto.id),
      child: Padding(
        padding: const .only(bottom: 8.0),
        child: Dismissible(
          direction: .endToStart,
          key: ValueKey(widget.dto.id),
          background: _buildBackground(),
          onDismissed: (_) => widget.onDelete(widget.dto.id!),
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
            name: widget.dto.category.icon,
            color: widget.dto.category.color,
          ),
          title: Text(
            widget.dto.description,
            style: context.typography.bodyLarge?.copyWith(fontWeight: .w600),
          ),
          subtitle: Text(
            widget.dto.category.label,
            style: context.typography.labelSmall?.copyWith(
              fontWeight: .w600,
              letterSpacing: 0.5,
              color: context.colors.onSurfaceVariant.withValues(alpha: 0.8),
            ),
          ),
          trailing: widget.dto.amount == null
              ? null
              : Text(
                  '$prefix ${widget.format(widget.dto.amount!)}',
                  style: context.typography.bodyLarge?.copyWith(
                    color: color,
                    fontWeight: .bold,
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
    child: IconWidget(name: Icons.delete, color: context.colors.error),
  );
}
