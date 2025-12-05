import 'package:flutter/material.dart';
import 'package:flutter_solidart/flutter_solidart.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:trocado/modules/core/core.dart';

class HeaderProfileWidget extends StatelessWidget {
  final VoidCallback onEdit;

  const HeaderProfileWidget({super.key, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final store = context.get<ImageStore>();

    return SignalBuilder(
      builder: (_, _) => store.resource.state.when(
        error: (_, _) => UserImageWidget.empty(onEdit: onEdit),
        loading: () =>
            SkeletonWidget(child: UserImageWidget.empty(onEdit: onEdit)),
        ready: (source) => UserImageWidget(
          source: source,
          onEdit: onEdit,
          iconOnEdit: LucideIcons.pencil,
        ),
      ),
    );
  }
}
