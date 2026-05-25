import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/extensions/context_extension.dart';
import 'package:trocado/src/presentation/ui/splash/notifiers/splash_state.dart';

import 'package:trocado/src/presentation/widgets/buttons/button_widget.dart';
import 'package:trocado/src/presentation/widgets/icons/background_icon_widget.dart';

class SplashErrorWidget extends StatelessWidget {
  final SplashStatus status;
  final VoidCallback onRetry;

  const SplashErrorWidget({
    super.key,
    required this.status,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const .symmetric(horizontal: 32.0),
      child: Column(
        spacing: 8.0,
        mainAxisSize: .min,
        children: [
          BackgroundIconWidget(
            icon: _icon,
            width: 96.0,
            height: 96.0,
            iconSize: 54.0,
            color: context.colors.inversePrimary,
          ),
          const SizedBox(height: 16.0),
          Text(
            _title,
            textAlign: .center,
            style: context.typography.titleMedium?.copyWith(
              fontWeight: .w700,
              color: context.colors.onSurface,
            ),
          ),
          Text(
            _message,
            textAlign: .center,
            style: context.typography.bodyMedium?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24.0),
          ButtonWidget.elevated(onTap: onRetry, label: 'Tentar novamente'),
        ],
      ),
    ),
  );

  IconData get _icon => switch (status) {
    .noConnection => Icons.wifi_off_rounded,
    _ => Icons.construction_rounded,
  };

  String get _title => switch (status) {
    .noConnection => 'Sem conexão',
    _ => 'Servidor em manutenção',
  };

  String get _message => switch (status) {
    .noConnection => 'Verifique sua conexão com a internet e tente novamente.',
    _ =>
      'Estamos trabalhando para melhorar o Trocado. Tente novamente em alguns minutos.',
  };
}
