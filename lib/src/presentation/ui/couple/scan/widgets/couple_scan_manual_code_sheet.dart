import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/widgets/bottom-sheets/bottom_sheet_widget.dart';

import 'package:trocado/src/presentation/ui/couple/scan/widgets/couple_scan_manual_code_body_widget.dart';

Future<void> showCoupleScanManualCodeSheet({required BuildContext context}) =>
    bottomSheetScaffoldWidget<void>(
      context: context,
      title: 'Código do convite',
      subtitle: 'Digite o código que seu par compartilhou.',
      child: const CoupleScanManualCodeBodyWidget(),
    );
