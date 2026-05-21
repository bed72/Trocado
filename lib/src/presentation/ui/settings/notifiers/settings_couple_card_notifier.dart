import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:trocado/src/main/providers/services_provider.dart';

import 'package:trocado/src/domain/failures/failure.dart';
import 'package:trocado/src/domain/models/user_model.dart';
import 'package:trocado/src/domain/models/couple/couple_model.dart';
import 'package:trocado/src/domain/services/date_formatter_service.dart';

import 'package:trocado/src/presentation/notifiers/user_notifier.dart';
import 'package:trocado/src/presentation/notifiers/couple_notifier.dart';
import 'package:trocado/src/presentation/extensions/name_initial_extension.dart';

import 'package:trocado/src/presentation/ui/settings/data/couple_card_state.dart';
import 'package:trocado/src/presentation/ui/settings/data/couple_card_presentation_data.dart';

part 'settings_couple_card_notifier.g.dart';

@Riverpod()
final class SettingsCoupleCardNotifier extends _$SettingsCoupleCardNotifier {
  late IDateFormatterService _dateFormatter;

  @override
  Future<CoupleCardState> build() async {
    _dateFormatter = ref.watch(dateFormatterServiceProvider);

    try {
      final couple = await ref.watch(coupleProvider.future);
      if (couple == null) return const CoupleNoneState();

      final user = await ref.watch(userProvider.future);
      return CoupleConnectedState(_toPresentationData(user, couple));
    } on Failure catch (failure) {
      return CoupleFailureState(failure.message);
    }
  }

  CoupleCardPresentationData _toPresentationData(
    UserModel user,
    CoupleModel couple,
  ) => CoupleCardPresentationData(
    currentUserInitial: user.name.toInitial(),
    partnerInitial: couple.partner.name.toInitial(),
    title: '${user.name.toFirstName()} & ${couple.partner.name.toFirstName()}',
    subtitle:
        'Conectados há ${_dateFormatter.formatRelativePast(couple.createdAt)}',
  );
}
