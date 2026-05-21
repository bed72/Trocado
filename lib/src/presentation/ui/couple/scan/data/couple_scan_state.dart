import 'package:equatable/equatable.dart';

import 'package:trocado/src/domain/models/couple/invite_lookup_model.dart';

enum CoupleScanStatus {
  ready,
  lookup,
  failure,
  initial,
  lookedUp,
  permissionDenied,
  cameraUnavailable,
}

final class CoupleScanState extends Equatable {
  final String code;
  final String message;
  final String manualCode;
  final bool canAskAgain;
  final CoupleScanStatus status;
  final String? manualCodeFailure;
  final InviteLookupModel? lookup;

  const CoupleScanState({
    this.code = '',
    this.lookup,
    this.message = '',
    this.manualCode = '',
    this.manualCodeFailure,
    this.status = .initial,
    this.canAskAgain = true,
  });

  CoupleScanState copyWith({
    String? code,
    String? message,
    String? manualCode,
    bool? canAskAgain,
    CoupleScanStatus? status,
    String? manualCodeFailure,
    InviteLookupModel? lookup,
    bool clearManualCodeFailure = false,
  }) => CoupleScanState(
    code: code ?? this.code,
    lookup: lookup ?? this.lookup,
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
    lookup,
    message,
    manualCode,
    canAskAgain,
    manualCodeFailure,
  ];
}
