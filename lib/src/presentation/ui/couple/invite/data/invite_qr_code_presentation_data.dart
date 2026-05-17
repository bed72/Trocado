import 'package:equatable/equatable.dart';

final class InviteQrCodePresentationData extends Equatable {
  final String code;
  final String qrData;
  final String formattedExpiration;

  const InviteQrCodePresentationData({
    required this.code,
    required this.qrData,
    required this.formattedExpiration,
  });

  @override
  List<Object?> get props => [code, qrData, formattedExpiration];
}
