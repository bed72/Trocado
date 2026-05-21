import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:trocado/src/main/providers/repositories_provider.dart';

import 'package:trocado/src/domain/repositories/interface_couple_repository.dart';

import 'package:trocado/src/presentation/notifiers/user_notifier.dart';
import 'package:trocado/src/presentation/notifiers/couple_notifier.dart';

import 'package:trocado/src/presentation/ui/home/notifiers/insights_notifier.dart';
import 'package:trocado/src/presentation/ui/budgets/notifiers/budgets_notifier.dart';
import 'package:trocado/src/presentation/ui/expenses/notifiers/expenses_notifier.dart';
import 'package:trocado/src/presentation/ui/home/notifiers/active_budget_notifier.dart';
import 'package:trocado/src/presentation/ui/home/notifiers/recent_expenses_notifier.dart';

import 'package:trocado/src/presentation/ui/couple/scan/data/couple_scan_confirm_state.dart';
import 'package:trocado/src/presentation/ui/couple/scan/notifiers/couple_scan_confirm_intent.dart';

part 'couple_scan_confirm_notifier.g.dart';

@Riverpod()
final class CoupleScanConfirmNotifier extends _$CoupleScanConfirmNotifier {
  late ICoupleRepository _repository;

  @override
  CoupleScanConfirmState build() {
    _repository = ref.watch(coupleRepositoryProvider);

    return const CoupleScanConfirmState();
  }

  void dispatch(CoupleScanConfirmIntent intent) => switch (intent) {
    AcceptPressed(:final code) => _accept(code),
  };

  Future<void> _accept(String code) async {
    if (state.status == .loading) return;

    state = state.copyWith(status: .loading);

    final data = await _repository.acceptInvite(code: code);

    data.fold(
      (failure) =>
          state = state.copyWith(status: .failure, message: failure.message),
      (model) {
        ref.invalidate(userProvider);
        ref.invalidate(coupleProvider);
        ref.invalidate(budgetsProvider);
        ref.invalidate(expensesProvider);
        ref.invalidate(insightsProvider);
        ref.invalidate(activeBudgetProvider);
        ref.invalidate(recentExpensesProvider);
        state = state.copyWith(
          status: .success,
          partnerName: model.partner.name,
        );
      },
    );
  }
}
