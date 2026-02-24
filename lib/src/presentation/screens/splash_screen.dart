import 'dart:async';

import 'package:flutter/material.dart';
import 'package:trocado/src/main/capsules/capsules.dart';
import 'package:trocado/src/presentation/widgets/loader_widget.dart';

import 'package:trocado/src/presentation/widgets/scaffold_widget.dart';
import 'package:trocado/src/presentation/widgets/images/image_widget.dart';

import 'package:trocado/src/presentation/actions/callback_action.dart';
import 'package:trocado/src/presentation/constants/assets_constant.dart';
import 'package:trocado/src/presentation/extensions/context_extension.dart';

class SplashScreen extends StatelessWidget {
  final VoidCallback navigateTo;

  const SplashScreen({super.key, required this.navigateTo});

  @override
  Widget build(BuildContext context) {
    return ScaffoldWidget(
      child: LoaderWidget(
        loading: _LoadingWidget(),
        capsule: (use) => use(ensureInitialized),
        success: _SuccessWidget(navigateTo: navigateTo),
        failure: (failure) => _FailureWidget(failure: failure),
      ),
    );
  }
}

class _FailureWidget extends StatelessWidget {
  final Object failure;
  const _FailureWidget({required this.failure});

  @override
  Widget build(BuildContext context) {
    return Text(failure.toString(), textAlign: .center);
  }
}

class _LoadingWidget extends StatelessWidget {
  const _LoadingWidget();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ImageWidget(
        height: 196.0,
        source: AssetsConstant.logo.source,
        color: context.colors.inversePrimary,
      ),
    );
  }
}

class _SuccessWidget extends StatefulWidget {
  final VoidCallback navigateTo;

  const _SuccessWidget({required this.navigateTo});

  @override
  State<_SuccessWidget> createState() => _SuccessWidgetState();
}

class _SuccessWidgetState extends State<_SuccessWidget> {
  @override
  void initState() {
    super.initState();

    addPostFrameCallback(() async {
      if (!mounted) return;

      await Future.delayed(Durations.extralong4);

      widget.navigateTo();
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
