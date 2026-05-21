sealed class CoupleScanIntent {
  const CoupleScanIntent();
}

final class PermissionRequested extends CoupleScanIntent {
  const PermissionRequested();
}

final class OpenSettingsPressed extends CoupleScanIntent {
  const OpenSettingsPressed();
}

final class QrDetected extends CoupleScanIntent {
  final String code;
  const QrDetected(this.code);
}

final class ManualCodeChanged extends CoupleScanIntent {
  final String code;
  const ManualCodeChanged(this.code);
}

final class ManualCodeSubmitted extends CoupleScanIntent {
  const ManualCodeSubmitted();
}

final class RetryPressed extends CoupleScanIntent {
  const RetryPressed();
}
