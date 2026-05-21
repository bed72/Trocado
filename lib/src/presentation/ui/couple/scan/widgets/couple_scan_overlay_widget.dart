import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/extensions/context_extension.dart';

class CoupleScanOverlayWidget extends StatelessWidget {
  const CoupleScanOverlayWidget({super.key});

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      const ColoredBox(color: Color(0xAA000000), child: SizedBox.expand()),
      Center(
        child: Container(
          width: 240.0,
          height: 240.0,
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: .circular(16.0),
            border: .all(width: 3.0, color: context.colors.primary),
          ),
        ),
      ),
    ],
  );
}
