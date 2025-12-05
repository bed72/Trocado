import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:trocado/modules/core/core.dart';

class HeaderProfileWidget extends StatelessWidget {
  final VoidCallback onEdit;

  const HeaderProfileWidget({super.key, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final store = context.get<ImageStore>();

    return Observer(
      builder: (_) {
        return UserImageWidget(
          onEdit: onEdit,
          source: store.path,
          iconOnEdit: LucideIcons.pencil,
        );
      },
    );
  }
}
