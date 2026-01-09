import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import 'package:trocado/modules/core/core.dart';

import 'package:trocado/modules/home/presentation/screens/home_screen.dart';

@Preview(name: 'Home', group: 'Home')
Widget homePreview() {
  return PreviewWidget(
    withScaffold: false,
    child: HomeScreen(onNavigateToExit: () {}, onNavigateToTransaction: () {}),
  );
}
