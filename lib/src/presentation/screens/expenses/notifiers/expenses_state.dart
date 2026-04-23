import 'package:equatable/equatable.dart';

import 'package:trocado/src/domain/failures/failure.dart';

import 'package:trocado/src/presentation/data/expense/expense_item_data.dart';

final class ExpensesState extends Equatable {
  final String? nextCursor;
  final bool isLoadingMore;
  final Failure? loadMoreFailure;
  final List<ExpenseItemData> items;

  const ExpensesState({
    this.nextCursor,
    this.loadMoreFailure,
    this.items = const [],
    this.isLoadingMore = false,
  });

  ExpensesState copyWith({
    String? nextCursor,
    bool? isLoadingMore,
    Failure? loadMoreFailure,
    List<ExpenseItemData>? items,
    bool clearNextCursor = false,
    bool clearLoadMoreFailure = false,
  }) => ExpensesState(
    items: items ?? this.items,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    nextCursor: clearNextCursor ? null : nextCursor ?? this.nextCursor,
    loadMoreFailure: clearLoadMoreFailure
        ? null
        : loadMoreFailure ?? this.loadMoreFailure,
  );

  @override
  List<Object?> get props => [
    items,
    nextCursor,
    isLoadingMore,
    loadMoreFailure,
  ];
}
