import 'package:trocado/src/domain/models/user_model.dart';
import 'package:trocado/src/domain/models/couple/invite_accept_model.dart';

InviteAcceptModel inviteAcceptMock({
  int coupleId = 1,
  int partnerId = 2,
  String partnerName = 'Jane Doe',
  String partnerEmail = 'jane@trocado.app',
}) => InviteAcceptModel(
  coupleId: coupleId,
  partner: UserModel(id: partnerId, name: partnerName, email: partnerEmail),
);
