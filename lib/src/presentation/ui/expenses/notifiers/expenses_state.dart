import 'package:equatable/equatable.dart';

import 'package:trocado/src/domain/failures/failure.dart';
import 'package:trocado/src/domain/models/expense/expense_filter_model.dart';

import 'package:trocado/src/presentation/data/expense/expense_item_data.dart';
import 'package:trocado/src/presentation/ui/expenses/data/expense_active_filter_chip_data.dart';

final class ExpensesState extends Equatable {
  final String? nextCursor;
  final bool isLoadingMore;
  final Failure? loadMoreFailure;
  final List<ExpenseItemData> items;
  final ExpenseFilterModel filter;
  final List<ExpenseActiveFilterChipData> activeFilterChips;

  const ExpensesState({
    this.nextCursor,
    this.loadMoreFailure,
    this.items = const [],
    this.isLoadingMore = false,
    this.filter = const ExpenseFilterModel.empty(),
    this.activeFilterChips = const [],
  });

  ExpensesState copyWith({
    String? nextCursor,
    bool? isLoadingMore,
    Failure? loadMoreFailure,
    List<ExpenseItemData>? items,
    ExpenseFilterModel? filter,
    List<ExpenseActiveFilterChipData>? activeFilterChips,
    bool clearNextCursor = false,
    bool clearLoadMoreFailure = false,
  }) => ExpensesState(
    items: items ?? this.items,
    filter: filter ?? this.filter,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    activeFilterChips: activeFilterChips ?? this.activeFilterChips,
    nextCursor: clearNextCursor ? null : nextCursor ?? this.nextCursor,
    loadMoreFailure: clearLoadMoreFailure
        ? null
        : loadMoreFailure ?? this.loadMoreFailure,
  );

  @override
  List<Object?> get props => [
    items,
    filter,
    nextCursor,
    isLoadingMore,
    loadMoreFailure,
    activeFilterChips,
  ];
}
