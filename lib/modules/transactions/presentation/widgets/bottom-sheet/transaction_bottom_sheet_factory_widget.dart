import 'package:flutter/material.dart';

import 'package:trocado/modules/core/core.dart';

import 'package:trocado/modules/transactions/presentation/widgets/bottom-sheet/menu/bottom_bar_menu_widget.dart';

Future<T?> transactionBottomSheetFactoryWidget<T>({
  required BuildContext context,
  required String type,
}) => bottomSheetScaffoldWidget<T>(
  context: context,
  title: 'Transações 💰',
  subtitle: 'Escolha o tipo de movimentação.',
  child: BottomBarMenuWidget(type: type),
);
