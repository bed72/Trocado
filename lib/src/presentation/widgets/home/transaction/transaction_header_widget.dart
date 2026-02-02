import 'package:flutter/material.dart';
import 'package:trocado/src/presentation/extensions/context_extension.dart';

class TransactionHeaderWidget extends SliverPersistentHeaderDelegate {
  final String title;

  const TransactionHeaderWidget({required this.title});

  @override
  double get minExtent => 48.0;

  @override
  double get maxExtent => 48.0;

  @override
  bool shouldRebuild(covariant TransactionHeaderWidget oldDelegate) =>
      title != oldDelegate.title;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => Container(
    alignment: .centerLeft,
    padding: const .symmetric(horizontal: 16.0),
    color: context.colors.surfaceContainerLowest,
    child: Text(
      title,
      style: context.typography.bodyMedium?.copyWith(fontWeight: .w600),
    ),
  );
}
