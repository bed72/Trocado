import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:back_button_interceptor/back_button_interceptor.dart';

import 'package:trocado/modules/core/core.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback onNavigateToExit;
  final VoidCallback onNavigateToTransaction;

  const HomeScreen({
    super.key,
    required this.onNavigateToExit,
    required this.onNavigateToTransaction,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    BackButtonInterceptor.add(_onExit);
  }

  @override
  void dispose() {
    BackButtonInterceptor.remove(_onExit);
    super.dispose();
  }

  bool _onExit(bool stopDefaultButtonEvent, RouteInfo info) {
    widget.onNavigateToExit();

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldWidget(
      appBar: AppBarWidget(),
      floatingActionButton: FloatingActionButton(
        onPressed: widget.onNavigateToTransaction,
        child: IconWidget(name: LucideIcons.plus),
      ),
      child: Center(child: Text('Home')),
    );
  }
}
