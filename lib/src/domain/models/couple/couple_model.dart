import 'package:equatable/equatable.dart';

import 'package:trocado/src/domain/models/user_model.dart';

final class CoupleModel extends Equatable {
  final int id;
  final int createdAt;
  final UserModel partner;

  const CoupleModel({
    required this.id,
    required this.partner,
    required this.createdAt,
  });

  CoupleModel copyWith({int? id, UserModel? partner, int? createdAt}) =>
      CoupleModel(
        id: id ?? this.id,
        partner: partner ?? this.partner,
        createdAt: createdAt ?? this.createdAt,
      );

  @override
  List<Object?> get props => [id, partner, createdAt];
}
