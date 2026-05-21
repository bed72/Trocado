import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/preview/trocado_preview.dart';

import 'package:trocado/src/presentation/ui/couple/scan/widgets/couple_scan_permission_denied_widget.dart';

@TrocadoPreview(group: 'Scan', name: 'Permissão — Primeira negação')
Widget previewFirstDenial() => Scaffold(
  body: CoupleScanPermissionDeniedWidget(
    onAllow: () {},
    canAskAgain: true,
    onManualCode: () {},
    onOpenSettings: () {},
  ),
);

@TrocadoPreview(group: 'Scan', name: 'Permissão — Negada permanente')
Widget previewPermanentDenial() => Scaffold(
  body: CoupleScanPermissionDeniedWidget(
    onAllow: () {},
    canAskAgain: false,
    onManualCode: () {},
    onOpenSettings: () {},
  ),
);
