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
        ? _buildItemOption(
            context: context,
            title: 'Galeria',
            onTap: onGalleryTap,
            isFirst: index == 0,
            icon: LucideIcons.image,
          )
        : _buildItemOption(
            context: context,
            title: 'Câmera',
            onTap: onCameraTap,
            isFirst: index == 0,
            icon: LucideIcons.camera,
          ),
  );

  Padding _buildItemOption({
    required BuildContext context,
    required String title,
    required bool isFirst,
    required IconData icon,
    required VoidCallback onTap,
  }) => Padding(
    padding: EdgeInsets.only(
      top: isFirst ? 16.0 : 0.0,
      bottom: !isFirst ? 32.0 : 0.0,
    ),
    child: BounceWidget.withoutTap(
      child: ListTile(
        leading: Icon(icon),
        contentPadding: EdgeInsets.zero,
        onTap: () {
          hideKeyboard;
          onTap();
        },
        title: Text(
          title,
          style: context.typography.bodyLarge?.copyWith(
            fontWeight: .w600,
            color: context.colors.onSurface.withValues(alpha: .60),
          ),
        ),
      ),
    ),
  );
}
