import 'package:equatable/equatable.dart';

final class InviteModel extends Equatable {
  final String code;
  final String qrData;
  final int expiresAt;

  const InviteModel({
    required this.code,
    required this.qrData,
    required this.expiresAt,
  });

  InviteModel copyWith({String? code, String? qrData, int? expiresAt}) =>
      InviteModel(
        code: code ?? this.code,
        qrData: qrData ?? this.qrData,
        expiresAt: expiresAt ?? this.expiresAt,
      );

  @override
  List<Object?> get props => [code, qrData, expiresAt];
}
