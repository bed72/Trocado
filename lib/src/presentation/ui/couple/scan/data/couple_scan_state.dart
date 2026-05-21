import 'package:equatable/equatable.dart';

enum CoupleScanStatus {
  ready,
  failure,
  initial,
  detected,
  permissionDenied,
  cameraUnavailable,
}

final class CoupleScanState extends Equatable {
  final String code;
  final String message;
  final bool canAskAgain;
  final String manualCode;
  final CoupleScanStatus status;
  final String? manualCodeFailure;

  const CoupleScanState({
    this.code = '',
    this.message = '',
    this.manualCode = '',
    this.manualCodeFailure,
    this.status = .initial,
    this.canAskAgain = true,
  });

  CoupleScanState copyWith({
    String? code,
    String? message,
    bool? canAskAgain,
    String? manualCode,
    CoupleScanStatus? status,
    String? manualCodeFailure,
    bool clearManualCodeFailure = false,
  }) => CoupleScanState(
    code: code ?? this.code,
    status: status ?? this.status,
    message: message ?? this.message,
    manualCode: manualCode ?? this.manualCode,
    manualCodeFailure: clearManualCodeFailure
        ? null
        : manualCodeFailure ?? this.manualCodeFailure,
    canAskAgain: canAskAgain ?? this.canAskAgain,
  );

  @override
  List<Object?> get props => [
    code,
    status,
    message,
    manualCode,
    canAskAgain,
    manualCodeFailure,
  ];
}
