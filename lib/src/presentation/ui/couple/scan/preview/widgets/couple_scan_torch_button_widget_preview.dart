import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/preview/trocado_preview.dart';

import 'package:trocado/src/presentation/ui/couple/scan/widgets/couple_scan_torch_button_widget.dart';

@TrocadoPreview(group: 'Scan', name: 'Torch — Off')
Widget previewTorchOff() => Scaffold(
  body: Container(
    alignment: .center,
    color: Colors.black,
    child: CoupleScanTorchButtonWidget(isOn: false, onPressed: () {}),
  ),
);

@TrocadoPreview(group: 'Scan', name: 'Torch — On')
Widget previewTorchOn() => Scaffold(
  body: Container(
    alignment: .center,
    color: Colors.black,
    child: CoupleScanTorchButtonWidget(isOn: true, onPressed: () {}),
  ),
);
