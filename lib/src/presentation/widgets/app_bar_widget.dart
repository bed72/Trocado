import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/extensions/context_extension.dart';

class AppBarWidget extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? leading;
  final List<Widget>? actions;

  const AppBarWidget({super.key, this.title, this.leading, this.actions});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      actions: actions,
      automaticallyImplyLeading: false,
      title: Row(
        spacing: 16.0,
        children: [
          ?leading,
          if (title != null)
            Text(
              title!,
              style: context.typography.titleLarge?.copyWith(
                fontWeight: .w600,
                color: context.colors.onSurface,
              ),
            ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
