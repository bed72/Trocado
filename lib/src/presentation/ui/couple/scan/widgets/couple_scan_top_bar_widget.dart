import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/widgets/go_back_widget.dart';

class CoupleScanTopBarWidget extends StatelessWidget
    implements PreferredSizeWidget {
  const CoupleScanTopBarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      leadingWidth: 64.0,
      automaticallyImplyLeading: false,
      backgroundColor: Colors.transparent,
      leading: Padding(
        padding: const .only(left: 16.0),
        child: Align(alignment: .centerLeft, child: GoBackWidget()),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
