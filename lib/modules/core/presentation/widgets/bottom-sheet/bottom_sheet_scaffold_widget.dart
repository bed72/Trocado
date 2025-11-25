import 'package:flutter/material.dart';
import 'package:trocado/modules/core/presentation/extensions/context_extension.dart';

class BottomSheetScaffoldWidget extends StatelessWidget {
  final Widget child;
  final String? title;
  final String? subtitle;

  const BottomSheetScaffoldWidget({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: .infinity,
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: const .vertical(top: Radius.circular(20.0)),
      ),
      child: Padding(
        padding: const .only(left: 20.0, top: 20.0, right: 20.0, bottom: 32.0),
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
              Text(
                title!,
                style: context.typography.titleLarge?.copyWith(
                  fontWeight: .w600,
                  color: context.colors.onSurface,
                ),
              ),
              const SizedBox(height: 6.0),
            ],
            if (subtitle != null) ...[
              Text(
                subtitle!,
                style: context.typography.bodyLarge?.copyWith(
                  fontWeight: .w600,
                  color: context.colors.onSurface.withAlpha(960),
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
