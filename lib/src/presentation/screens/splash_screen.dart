import 'dart:async';

import 'package:flutter/material.dart';
import 'package:trocado/src/main/injection.dart';

import 'package:trocado/src/presentation/widgets/scaffold_widget.dart';
import 'package:trocado/src/presentation/widgets/images/image_widget.dart';

import 'package:trocado/src/presentation/actions/callback_action.dart';
import 'package:trocado/src/presentation/constants/assets_constant.dart';
import 'package:trocado/src/presentation/extensions/context_extension.dart';

import 'package:trocado/src/infrastructure/clients/database/database_client.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback navigateTo;

  const SplashScreen({super.key, required this.navigateTo});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Object? _failure;

  @override
  void initState() {
    super.initState();

    addPostFrameCallback(() async {
      try {
        final database = sl<IDatabaseClient>();
        await database.ensureInitialized();

        if (!mounted) return;

        await Future.delayed(Durations.extralong4);

        if (!mounted) return;
        widget.navigateTo();
      } catch (exception) {
        if (!mounted) return;
        setState(() {
          _failure = exception;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_failure != null) {
      return ScaffoldWidget(
        child: Center(child: Text(_failure.toString(), textAlign: .center)),
      );
    }

    return ScaffoldWidget(
      child: Center(
        child: ImageWidget(
          height: 196.0,
          source: AssetsConstant.logo.source,
          color: context.colors.inversePrimary,
        ),
      ),
    );
  }
}
