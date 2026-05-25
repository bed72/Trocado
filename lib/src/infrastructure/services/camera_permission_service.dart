import 'package:permission_handler/permission_handler.dart';

import 'package:trocado/src/domain/services/interface_camera_permission_service.dart';

final class CameraPermissionService implements ICameraPermissionService {
  @override
  Future<CameraPermissionStatus> status() async =>
      _map(await Permission.camera.status);

  @override
  Future<CameraPermissionStatus> request() async =>
      _map(await Permission.camera.request());

  @override
  Future<void> openSettings() async {
    await openAppSettings();
  }

  CameraPermissionStatus _map(PermissionStatus status) => switch (status) {
    .denied => .denied,
    .granted || .limited || .provisional => .granted,
    .permanentlyDenied || .restricted => .permanentlyDenied,
  };
}
