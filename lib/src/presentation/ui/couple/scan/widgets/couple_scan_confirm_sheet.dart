import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/widgets/bottom-sheets/bottom_sheet_widget.dart';

import 'package:trocado/src/presentation/ui/couple/scan/widgets/couple_scan_confirm_body_widget.dart';

Future<void> showCoupleScanConfirmSheet({
  required BuildContext context,
  required String code,
}) => bottomSheetScaffoldWidget<void>(
  context: context,
  title: 'Confirmar união',
  subtitle: 'Confira o código do convite antes de aceitar.',
  child: CoupleScanConfirmBodyWidget(code: code),
);
