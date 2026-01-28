import 'package:flutter/material.dart';

import 'package:trocado/modules/core/presentation/extensions/context_extension.dart';

class BottomSheetScaffoldWidget extends StatelessWidget {
  final Widget child;
  final String? title;
  final String? subtitle;
  final bool? withoutPadding;

  const BottomSheetScaffoldWidget({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.withoutPadding,
  });

  bool get _withoutPadding => (withoutPadding ?? false);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: .infinity,
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: const .vertical(top: .circular(20.0)),
      ),
      child: Padding(
        padding: _withoutPadding
            ? .only(left: 0, top: 20.0, right: 0, bottom: 32.0)
            : .only(left: 20.0, top: 20.0, right: 20.0, bottom: 32.0),
        child: Column(
          mainAxisSize: .min,
          crossAxisAlignment: .start,
          children: [
            Center(
              child: Container(
                width: 48.0,
                height: 6.0,
                margin: const .only(bottom: 20.0),
                decoration: BoxDecoration(
                  color: context.colors.primary.withAlpha(70),
                  borderRadius: context.radius.cornerRadiusFull,
                ),
              ),
            ),

            if (title != null) ...[
              Padding(
                padding: .symmetric(horizontal: _withoutPadding ? 16.0 : 0.0),
                child: Text(
                  title!,
                  style: context.typography.titleLarge?.copyWith(
                    fontWeight: .w600,
                    color: context.colors.onSurface,
                  ),
                ),
              ),
              const SizedBox(height: 6.0),
            ],
            if (subtitle != null) ...[
              Padding(
                padding: .symmetric(horizontal: _withoutPadding ? 16.0 : 0.0),
                child: Text(
                  subtitle!,
                  style: context.typography.bodyLarge?.copyWith(
                    fontWeight: .w600,
                    color: context.colors.onSurfaceVariant.withValues(
                      alpha: 0.8,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6.0),
            ],

            Flexible(child: child),
          ],
        ),
      ),
    );
  }
}
