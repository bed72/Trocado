import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:trocado/src/infrastructure/providers/providers.dart';

import 'package:trocado/src/presentation/notifiers/home/home_data.dart';
import 'package:trocado/src/presentation/notifiers/home/home_state.dart';

import 'package:trocado/src/domain/models/entry_model.dart';
import 'package:trocado/src/domain/models/month_model.dart';

import 'package:trocado/src/domain/repositories/interface_balance_repository.dart';
import 'package:trocado/src/domain/repositories/interface_transaction_repository.dart';

part 'home_notifier.g.dart';

@riverpod
final class HomeNotifier extends _$HomeNotifier {
  int _offset = 0;

  final _pageSize = 20;

  late final IBalanceRepository _balanceRepository;
  late final ITransactionRepository _transactionRepository;

  @override
  HomeState build() {
    _balanceRepository = ref.read(balanceRepositoryProvider);
    _transactionRepository = ref.read(transactionRepositoryProvider);

    _loadInitial();

    return HomeLoading();
  }

  void _loadInitial() {
    final data = _transactionRepository.findByPeriod(
      offset: 0,
      limit: _pageSize,
    );

    data.fold(
      (failure) {
        state = HomeFailure(failure: failure);
      },
      (transactions) {
        final balance = _balanceRepository.calculate(transactions);

        _offset = transactions.length;

        state = HomeSuccess(
          data: HomeContentData(
            filter: null,
            balance: balance,
            isLoadingMore: false,
            month: MonthModel.now(),
            transactions: transactions,
            hasReachedEnd: transactions.length < _pageSize,
          ),
        );
      },
    );
  }

  void changeFilter(EntryModel? filter) {
    final current = state;
    if (current is! HomeSuccess) return;

    state = HomeSuccess(
      data: current.data.copyWith(
        filter: filter,
        isLoadingMore: false,
        hasReachedEnd: false,
        transactions: const [],
      ),
    );

    _offset = 0;

    final data = filter == null
        ? _transactionRepository.findByPeriod(limit: _pageSize, offset: 0)
        : _transactionRepository.findByEntry(filter);

    data.fold(
      (failure) {
        state = HomeFailure(failure: failure);
      },
      (transactions) {
        final balance = _balanceRepository.calculate(transactions);

        _offset = transactions.length;

        state = HomeSuccess(
          data: current.data.copyWith(
            filter: filter,
            balance: balance,
            transactions: transactions,
            hasReachedEnd: transactions.length < _pageSize,
          ),
        );
      },
    );
  }

  void loadMore() {
    final current = state;
    if (current is! HomeSuccess) return;

    if (current.data.isLoadingMore || current.data.hasReachedEnd) return;

    state = HomeSuccess(data: current.data.copyWith(isLoadingMore: true));

    final filter = current.data.filter;

    final data = filter == null
        ? _transactionRepository.findByPeriod(limit: _pageSize, offset: _offset)
        : _transactionRepository.findByEntry(filter);

    data.fold(
      (failure) {
        state = HomeFailure(failure: failure);
      },
      (transactions) {
        _offset += transactions.length;

        state = HomeSuccess(
          data: current.data.copyWith(
            isLoadingMore: false,
            hasReachedEnd: transactions.length < _pageSize,
            transactions: [...current.data.transactions, ...transactions],
          ),
        );
      },
    );
  }
}
