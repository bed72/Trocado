import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:trocado/src/presentation/extensions/context_extension.dart';

import 'package:trocado/src/presentation/widgets/toast_widget.dart';
import 'package:trocado/src/presentation/widgets/app_bar_widget.dart';
import 'package:trocado/src/presentation/widgets/go_back_widget.dart';
import 'package:trocado/src/presentation/widgets/scaffold_widget.dart';
import 'package:trocado/src/presentation/widgets/buttons/button_widget.dart';

import 'package:trocado/src/presentation/ui/couple/scan/data/couple_scan_state.dart';
import 'package:trocado/src/presentation/ui/couple/scan/notifiers/couple_scan_intent.dart';
import 'package:trocado/src/presentation/ui/couple/scan/notifiers/couple_scan_notifier.dart';
import 'package:trocado/src/presentation/ui/couple/scan/widgets/couple_scan_top_bar_widget.dart';
import 'package:trocado/src/presentation/ui/couple/scan/widgets/couple_scan_overlay_widget.dart';
import 'package:trocado/src/presentation/ui/couple/scan/widgets/couple_scan_manual_code_sheet.dart';
import 'package:trocado/src/presentation/ui/couple/scan/locations/couple_scan_confirm_location.dart';
import 'package:trocado/src/presentation/ui/couple/scan/widgets/couple_scan_torch_button_widget.dart';
import 'package:trocado/src/presentation/ui/couple/scan/widgets/couple_scan_permission_denied_widget.dart';

class CoupleScanScreen extends StatefulWidget {
  const CoupleScanScreen({super.key});

  @override
  State<CoupleScanScreen> createState() => _CoupleScanScreenState();
}

class _CoupleScanScreenState extends State<CoupleScanScreen> {
  bool _isTorchOn = false;

  late final MobileScannerController _controller;

  @override
  void initState() {
    super.initState();

    _controller = MobileScannerController(
      torchEnabled: false,
      detectionSpeed: .normal,
      formats: const [.qrCode],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _toggleTorch() async {
    await _controller.toggleTorch();
    setState(() => _isTorchOn = !_isTorchOn);
  }

  Future<void> _onStatusChanged(
    CoupleScanStatus? previous,
    CoupleScanState next,
  ) async {
    if (previous == next.status) return;

    switch (next.status) {
      case .detected:
        await _safeStop();
      case .ready when previous == .failure:
        await _safeStart();
      default:
    }

    if (next.status == .detected) {
      if (mounted) _navigateToConfirm(next.code);
    }

    if (next.status == .failure && previous != .failure) {
      if (mounted) _showFailure(next.message);
    }
  }

  Future<void> _safeStop() async {
    try {
      await _controller.stop();
    } on MobileScannerException {
      return;
    }
  }

  Future<void> _safeStart() async {
    try {
      await _controller.start();
    } on MobileScannerException {
      return;
    }
  }

  @override
  Widget build(BuildContext context) => Consumer(
    builder: (_, ref, _) {
      ref.listen(coupleScanProvider, (previous, next) {
        if (next case AsyncData(:final value)) {
          _onStatusChanged(previous?.value?.status, value);
        }
      });

      final asyncState = ref.watch(coupleScanProvider);
      final notifier = ref.read(coupleScanProvider.notifier);

      return switch (asyncState) {
        AsyncData(:final value) => _scaffoldFor(
          state: value,
          notifier: notifier,
        ),
        _ => const Scaffold(body: SizedBox.shrink()),
      };
    },
  );

  Widget _scaffoldFor({
    required CoupleScanState state,
    required CoupleScanNotifier notifier,
  }) => switch (state.status) {
    .permissionDenied || .cameraUnavailable => ScaffoldWidget(
      appBar: AppBarWidget(leading: GoBackWidget()),
      child: CoupleScanPermissionDeniedWidget(
        canAskAgain: state.canAskAgain,
        onManualCode: _openManualSheet,
        onAllow: () => notifier.dispatch(const PermissionRequested()),
        onOpenSettings: () => notifier.dispatch(const OpenSettingsPressed()),
      ),
    ),
    _ => _scannerScaffold(state: state, notifier: notifier),
  };

  Scaffold _scannerScaffold({
    required CoupleScanState state,
    required CoupleScanNotifier notifier,
  }) {
    final isCapturing = state.status == .detected;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black,
      appBar: CoupleScanTopBarWidget(),
      body: Stack(
        children: [
          Positioned.fill(
            child: MobileScanner(
              controller: _controller,
              onDetect: (capture) {
                for (final barcode in capture.barcodes) {
                  final value = barcode.rawValue;
                  if (value != null && value.isNotEmpty) {
                    notifier.dispatch(QrDetected(value));
                    break;
                  }
                }
              },
            ),
          ),
          const Positioned.fill(
            child: IgnorePointer(child: CoupleScanOverlayWidget()),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const .fromLTRB(16.0, 0, 16.0, 24.0),
                child: Column(
                  spacing: 16.0,
                  mainAxisSize: .min,
                  crossAxisAlignment: .stretch,
                  children: [
                    Align(
                      alignment: .centerRight,
                      child: CoupleScanTorchButtonWidget(
                        isOn: _isTorchOn,
                        onPressed: _toggleTorch,
                      ),
                    ),
                    Text(
                      'Aponte a câmera para o QR code do seu par',
                      textAlign: .center,
                      style: context.typography.bodyMedium?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    ButtonWidget.elevated(
                      isLoading: isCapturing,
                      onTap: isCapturing ? null : _openManualSheet,
                      child: const Text('Digitar código manualmente'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToConfirm(String code) =>
      context.navigate(CoupleScanConfirmLocation(code: code));

  void _showFailure(String message) {
    showToastWidget(
      context: context,
      title: 'Opps',
      type: .failure,
      description: message,
    );
    final container = ProviderScope.containerOf(context, listen: false);
    container.read(coupleScanProvider.notifier).dispatch(const RetryPressed());
  }

  Future<void> _openManualSheet() =>
      showCoupleScanManualCodeSheet(context: context);
}
