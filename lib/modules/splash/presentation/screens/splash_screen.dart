import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback navigateTo;

  const SplashScreen({super.key, required this.navigateTo});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    widget.navigateTo();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(child: Center(child: Text('Splash'))),
    );
  }
}
