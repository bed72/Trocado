import 'package:equatable/equatable.dart';

import 'package:trocado/src/domain/models/user_model.dart';

final class InviteLookupModel extends Equatable {
  final int coupleId;
  final UserModel partner;

  const InviteLookupModel({required this.coupleId, required this.partner});

  InviteLookupModel copyWith({int? coupleId, UserModel? partner}) =>
      InviteLookupModel(
        partner: partner ?? this.partner,
        coupleId: coupleId ?? this.coupleId,
      );

  @override
  List<Object?> get props => [coupleId, partner];
}
