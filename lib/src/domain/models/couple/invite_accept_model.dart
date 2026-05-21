import 'package:equatable/equatable.dart';

import 'package:trocado/src/domain/models/user_model.dart';

final class InviteAcceptModel extends Equatable {
  final int coupleId;
  final UserModel partner;

  const InviteAcceptModel({required this.coupleId, required this.partner});

  InviteAcceptModel copyWith({int? coupleId, UserModel? partner}) =>
      InviteAcceptModel(
        partner: partner ?? this.partner,
        coupleId: coupleId ?? this.coupleId,
      );

  @override
  List<Object?> get props => [coupleId, partner];
}
