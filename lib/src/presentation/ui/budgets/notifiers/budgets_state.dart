import 'package:equatable/equatable.dart';

import 'package:trocado/src/domain/failures/failure.dart';

import 'package:trocado/src/presentation/data/budget/budget_card_presentation_data.dart';
import 'package:trocado/src/presentation/ui/budgets/data/budget_item_presentation_data.dart';

final class BudgetsState extends Equatable {
  final bool isLoadingMore;
  final List<BudgetItemPresentationData> items;

  final String? nextCursor;
  final Failure? loadMoreFailure;
  final BudgetCardPresentationData? activeCard;

  const BudgetsState({
    this.activeCard,
    this.nextCursor,
    this.loadMoreFailure,
    this.items = const [],
    this.isLoadingMore = false,
  });

  BudgetsState copyWith({
    String? nextCursor,
    bool? isLoadingMore,
    Failure? loadMoreFailure,
    bool clearActiveCard = false,
    bool clearNextCursor = false,
    bool clearLoadMoreFailure = false,
    BudgetCardPresentationData? activeCard,
    List<BudgetItemPresentationData>? items,
  }) => BudgetsState(
    items: items ?? this.items,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    activeCard: clearActiveCard ? null : activeCard ?? this.activeCard,
    nextCursor: clearNextCursor ? null : nextCursor ?? this.nextCursor,
    loadMoreFailure: clearLoadMoreFailure
        ? null
        : loadMoreFailure ?? this.loadMoreFailure,
  );

  @override
  List<Object?> get props => [
    items,
    activeCard,
    nextCursor,
    isLoadingMore,
    loadMoreFailure,
  ];
}
