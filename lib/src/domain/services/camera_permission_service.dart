enum CameraPermissionStatus { granted, denied, permanentlyDenied }

abstract interface class ICameraPermissionService {
  Future<void> openSettings();
  Future<CameraPermissionStatus> status();
  Future<CameraPermissionStatus> request();
}
