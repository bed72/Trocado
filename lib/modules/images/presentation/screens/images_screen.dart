import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:trocado/modules/core/core.dart';

class ImagesScreen extends StatelessWidget {
  final VoidCallback onCameraTap;
  final VoidCallback onGalleryTap;

  const ImagesScreen({
    super.key,
    required this.onCameraTap,
    required this.onGalleryTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomSheetScaffoldWidget(
      title: 'Adicionar imagem',
      subtitle: 'Use a câmera ou selecione uma imagem da galeria.',
      child: _buildOptions(),
    );
  }

  ListView _buildOptions() => ListView.separated(
    itemCount: 2,
    shrinkWrap: true,
    padding: EdgeInsets.zero,
    separatorBuilder: (_, _) => const Divider(height: 1),
    itemBuilder: (context, index) => index == 0
        ? Padding(
            padding: EdgeInsetsGeometry.only(top: 16.0),
            child: _buildItemOption(
              context: context,
              title: 'Galeria',
              onTap: onGalleryTap,
              icon: LucideIcons.image,
            ),
          )
        : _buildItemOption(
            context: context,
            title: 'Câmera',
            onTap: onCameraTap,
            icon: LucideIcons.camera,
          ),
  );

  BounceWidget _buildItemOption({
    required BuildContext context,
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) => BounceWidget.withoutTap(
    child: ListTile(
      onTap: () {
        hideKeyboard;
        onTap();
      },
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(
        title,
        style: context.typography.bodyLarge?.copyWith(
          fontWeight: .w600,
          color: context.colors.onSurface.withValues(alpha: .60),
        ),
      ),
    ),
  );
}
