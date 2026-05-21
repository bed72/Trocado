import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/preview/trocado_preview.dart';

import 'package:trocado/src/presentation/ui/couple/scan/widgets/couple_scan_overlay_widget.dart';

@TrocadoPreview(group: 'Scan', name: 'Overlay')
Widget previewOverlay() => const Scaffold(
  body: Stack(
    children: [
      ColoredBox(color: Colors.black, child: SizedBox.expand()),
      CoupleScanOverlayWidget(),
    ],
  ),
);
