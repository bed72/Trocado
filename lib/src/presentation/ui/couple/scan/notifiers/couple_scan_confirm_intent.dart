sealed class CoupleScanConfirmIntent {
  const CoupleScanConfirmIntent();
}

final class AcceptPressed extends CoupleScanConfirmIntent {
  final String code;
  const AcceptPressed(this.code);
}
