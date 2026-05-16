import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:trocado/src/main/providers/services_provider.dart';
import 'package:trocado/src/main/providers/repositories_provider.dart';

import 'package:trocado/src/domain/models/user_model.dart';
import 'package:trocado/src/domain/models/couple/couple_model.dart';
import 'package:trocado/src/domain/services/date_formatter_service.dart';
import 'package:trocado/src/domain/repositories/interface_couple_repository.dart';

import 'package:trocado/src/presentation/notifiers/user_notifier.dart';
import 'package:trocado/src/presentation/ui/settings/data/couple_card_presentation_data.dart';

part 'couple_notifier.g.dart';

@Riverpod()
final class CoupleNotifier extends _$CoupleNotifier {
  late ICoupleRepository _repository;
  late IDateFormatterService _dateFormatter;

  @override
  Future<CoupleCardPresentationData?> build() async {
    _repository = ref.watch(coupleRepositoryProvider);
    _dateFormatter = ref.watch(dateFormatterServiceProvider);

    final data = await _repository.findActive();
    final user = await ref.watch(userProvider.future);

    return data.fold(
      (_) => null,
      (couple) => _toPresentationData(user, couple),
    );
  }

  CoupleCardPresentationData _toPresentationData(
    UserModel user,
    CoupleModel couple,
  ) => CoupleCardPresentationData(
    currentUserInitial: _initial(user.name),
    partnerInitial: _initial(couple.partner.name),
    title: '${user.name} & ${couple.partner.name}',
    subtitle:
        'Conectados há ${_dateFormatter.formatRelativePast(couple.createdAt)}',
  );

  String _initial(String name) {
    final trimmed = name.trim();
    return trimmed.isEmpty ? '' : trimmed.substring(0, 1).toUpperCase();
  }
}
