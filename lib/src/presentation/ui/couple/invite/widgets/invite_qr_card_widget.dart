import 'package:flutter/material.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';

import 'package:trocado/src/presentation/extensions/context_extension.dart';

import 'package:trocado/src/presentation/ui/couple/invite/data/invite_qr_code_presentation_data.dart';

class InviteQrCardWidget extends StatelessWidget {
  final InviteQrCodePresentationData data;

  const InviteQrCardWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) => Container(
    padding: const .all(24.0),
    decoration: BoxDecoration(
      borderRadius: context.radius.cornerRadius100,
      color: context.colors.surfaceContainerHighest,
    ),
    child: Column(
      mainAxisSize: .min,
      spacing: 16.0,
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: Container(
            padding: const .all(16.0),
            decoration: BoxDecoration(
              borderRadius: context.radius.cornerRadius100,
              color: context.colors.surface,
            ),
            child: PrettyQrView.data(
              data: data.qrData,
              decoration: PrettyQrDecoration(
                shape: PrettyQrSmoothSymbol(color: context.colors.onSurface),
              ),
            ),
          ),
        ),
        Text(
          data.code,
          style: context.typography.headlineMedium?.copyWith(
            fontWeight: .w600,
            letterSpacing: 4.0,
          ),
        ),
        Text(
          data.formattedExpiration,
          style: context.typography.bodySmall?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
      ],
    ),
  );
}
