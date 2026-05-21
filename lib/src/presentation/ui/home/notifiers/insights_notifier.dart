import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:trocado/src/main/providers/repositories_provider.dart';

import 'package:trocado/src/presentation/notifiers/couple_notifier.dart';

import 'package:trocado/src/domain/models/insight/insights_bundle_model.dart';
import 'package:trocado/src/domain/repositories/interface_insights_repository.dart';

part 'insights_notifier.g.dart';

@Riverpod()
final class InsightsNotifier extends _$InsightsNotifier {
  late bool _isInCouple;
  late IInsightsRepository _repository;

  @override
  Future<InsightsBundleModel> build() async {
    _repository = ref.watch(insightsRepositoryProvider);

    final couple = await ref.watch(coupleProvider.future);
    _isInCouple = couple != null;

    return await _load();
  }

  Future<InsightsBundleModel> _load() async {
    final data = await _repository.findAll(
      scope: _isInCouple ? .couple : .mine,
    );

    return data.fold((failure) => throw failure, (bundle) => bundle);
  }
}
