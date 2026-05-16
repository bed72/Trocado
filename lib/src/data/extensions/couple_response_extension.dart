import 'package:trocado/src/domain/models/couple/couple_model.dart';

import 'package:trocado/src/data/extensions/user_response_extension.dart';

import 'package:trocado/src/infrastructure/clients/http/responses/couple/couple_response.dart';

extension CoupleResponseExtension on CoupleResponse {
  CoupleModel toModel() => CoupleModel(
    id: id,
    partner: partner.toModel(),
    createdAt: DateTime.parse(createdAt).millisecondsSinceEpoch,
  );
}
