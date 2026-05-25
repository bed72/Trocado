import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:trocado/src/main/providers/services_provider.dart';
import 'package:trocado/src/main/providers/validators_provider.dart';

import 'package:trocado/src/domain/services/interface_camera_permission_service.dart';

import 'package:trocado/src/presentation/ui/couple/scan/data/couple_scan_state.dart';
import 'package:trocado/src/presentation/ui/couple/scan/notifiers/couple_scan_intent.dart';
import 'package:trocado/src/presentation/ui/couple/scan/validators/couple_scan_form_validator.dart';

part 'couple_scan_notifier.g.dart';

@Riverpod()
final class CoupleScanNotifier extends _$CoupleScanNotifier {
  late ICameraPermissionService _permission;
  late CoupleScanFormValidator _formValidator;

  @override
  Future<CoupleScanState> build() async {
    _permission = ref.watch(cameraPermissionServiceProvider);
    _formValidator = ref.watch(coupleScanFormValidatorProvider);

    return _stateFromPermission(await _permission.status());
  }

  void dispatch(CoupleScanIntent intent) => switch (intent) {
    RetryPressed() => _retry(),
    OpenSettingsPressed() => _openSettings(),
    QrDetected(:final code) => _detect(code),
    PermissionRequested() => _requestPermission(),
    ManualCodeSubmitted() => _onManualCodeSubmitted(),
    ManualCodeChanged(:final code) => _onManualCodeChanged(code),
  };

  Future<void> _requestPermission() async {
    final status = await _permission.request();
    state = AsyncData(_stateFromPermission(status));
  }

  Future<void> _openSettings() async {
    await _permission.openSettings();
  }

  void _onManualCodeChanged(String code) {
    final current = state.value;
    if (current == null) return;

    state = AsyncData(
      current.copyWith(manualCode: code, clearManualCodeFailure: true),
    );
  }

  void _onManualCodeSubmitted() {
    final current = state.value;
    if (current == null) return;

    final validated = _formValidator(current);
    state = AsyncData(validated.state);

    if (validated.code != null) _detect(validated.code!);
  }

  void _detect(String code) {
    final current = state.value;
    if (current == null) return;
    if (current.status != .ready) return;

    final parsed = _parseCode(code);
    if (parsed.isEmpty) return;

    state = AsyncData(current.copyWith(code: parsed, status: .detected));
  }

  String _parseCode(String value) {
    final trimmed = value.trim();
    final uri = Uri.tryParse(trimmed);
    if (uri != null && uri.scheme == 'trocado' && uri.host == 'invite') {
      return uri.pathSegments.isEmpty ? '' : uri.pathSegments.first;
    }
    return trimmed;
  }

  void _retry() => state = const AsyncData(CoupleScanState(status: .ready));

  CoupleScanState _stateFromPermission(CameraPermissionStatus status) =>
      switch (status) {
        .granted => const CoupleScanState(status: .ready),
        .denied => const CoupleScanState(status: .permissionDenied),
        .permanentlyDenied => const CoupleScanState(
          canAskAgain: false,
          status: .permissionDenied,
        ),
      };
}
