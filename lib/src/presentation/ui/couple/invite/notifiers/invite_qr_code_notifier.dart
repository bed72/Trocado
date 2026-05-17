import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:trocado/src/main/providers/services_provider.dart';
import 'package:trocado/src/main/providers/repositories_provider.dart';

import 'package:trocado/src/domain/models/couple/invite_model.dart';
import 'package:trocado/src/domain/services/date_formatter_service.dart';
import 'package:trocado/src/domain/repositories/interface_couple_repository.dart';

import 'package:trocado/src/presentation/ui/couple/invite/data/invite_qr_code_presentation_data.dart';

part 'invite_qr_code_notifier.g.dart';

@Riverpod()
final class InviteQrCodeNotifier extends _$InviteQrCodeNotifier {
  late ICoupleRepository _repository;
  late IDateFormatterService _dateFormatter;

  @override
  Future<InviteQrCodePresentationData> build() async {
    _repository = ref.watch(coupleRepositoryProvider);
    _dateFormatter = ref.watch(dateFormatterServiceProvider);

    return await _create();
  }

  Future<InviteQrCodePresentationData> _create() async {
    final data = await _repository.createInvite();

    return data.fold((failure) => throw failure, _toPresentation);
  }

  InviteQrCodePresentationData _toPresentation(InviteModel invite) =>
      InviteQrCodePresentationData(
        code: invite.code,
        qrData: invite.qrData,
        formattedExpiration: _dateFormatter.formatInviteExpiration(
          invite.expiresAt,
        ),
      );

  Future<void> retry() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_create);
  }

  Future<void> share() async {
    if (state case AsyncData(value: final current)) {
      await _repository.shareInvite(qrData: current.qrData);
    }
  }
}
