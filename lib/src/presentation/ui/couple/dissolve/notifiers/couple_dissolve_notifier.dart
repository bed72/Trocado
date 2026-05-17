import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:trocado/src/main/providers/repositories_provider.dart';

import 'package:trocado/src/domain/repositories/interface_couple_repository.dart';

import 'package:trocado/src/presentation/notifiers/user_notifier.dart';

import 'package:trocado/src/presentation/ui/home/notifiers/insights_notifier.dart';
import 'package:trocado/src/presentation/ui/budgets/notifiers/budgets_notifier.dart';
import 'package:trocado/src/presentation/ui/settings/notifiers/couple_notifier.dart';
import 'package:trocado/src/presentation/ui/expenses/notifiers/expenses_notifier.dart';
import 'package:trocado/src/presentation/ui/home/notifiers/active_budget_notifier.dart';
import 'package:trocado/src/presentation/ui/home/notifiers/recent_expenses_notifier.dart';

import 'package:trocado/src/presentation/ui/couple/dissolve/notifiers/couple_dissolve_state.dart';
import 'package:trocado/src/presentation/ui/couple/dissolve/notifiers/couple_dissolve_intent.dart';

part 'couple_dissolve_notifier.g.dart';

@riverpod
final class CoupleDissolveNotifier extends _$CoupleDissolveNotifier {
  late ICoupleRepository _repository;

  @override
  Future<CoupleDissolveState> build() async {
    _repository = ref.watch(coupleRepositoryProvider);

    final user = await ref.watch(userProvider.future);
    final coupleData = await _repository.findActive();

    return coupleData.fold(
      (failure) => throw failure,
      (couple) => CoupleDissolveState(
        currentUserName: user.name,
        partnerName: couple.partner.name,
      ),
    );
  }

  void dispatch(CoupleDissolveIntent intent) => switch (intent) {
    DissolvePressed() => _dissolve(),
  };

  Future<void> _dissolve() async {
    final current = state.value;
    if (current == null || current.status == .loading) return;

    state = AsyncData(current.copyWith(status: .loading));

    final data = await _repository.dissolve();

    data.fold(
      (failure) => state = AsyncData(
        current.copyWith(status: .failure, message: failure.message),
      ),
      (_) {
        ref.invalidate(coupleProvider);
        ref.invalidate(budgetsProvider);
        ref.invalidate(expensesProvider);
        ref.invalidate(insightsProvider);
        ref.invalidate(activeBudgetProvider);
        ref.invalidate(recentExpensesProvider);
        state = AsyncData(current.copyWith(status: .success));
      },
    );
  }
}
