import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:trocado/src/main/providers/repositories_provider.dart';

import 'package:trocado/src/domain/failures/failure.dart';
import 'package:trocado/src/domain/models/couple/couple_model.dart';
import 'package:trocado/src/domain/repositories/interface_couple_repository.dart';

part 'couple_notifier.g.dart';

@Riverpod(keepAlive: true)
final class CoupleNotifier extends _$CoupleNotifier {
  late ICoupleRepository _repository;

  @override
  Future<CoupleModel?> build() async {
    _repository = ref.watch(coupleRepositoryProvider);

    return await _findActive();
  }

  Future<CoupleModel?> _findActive() async {
    final data = await _repository.findActive();

    return data.fold(
      (failure) => switch (failure) {
        NotFoundFailure() => null,
        _ => throw failure,
      },
      (couple) => couple,
    );
  }
}
