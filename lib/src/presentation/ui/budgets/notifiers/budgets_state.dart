import 'package:equatable/equatable.dart';

import 'package:trocado/src/domain/failures/failure.dart';

import 'package:trocado/src/presentation/data/budget/budget_card_presentation_data.dart';
import 'package:trocado/src/presentation/ui/budgets/data/budget_item_presentation_data.dart';

final class BudgetsState extends Equatable {
  final BudgetCardPresentationData? activeCard;
  final List<BudgetItemPresentationData> items;
  final String? nextCursor;
  final bool isLoadingMore;
  final Failure? loadMoreFailure;

  const BudgetsState({
    this.activeCard,
    this.items = const [],
    this.nextCursor,
    this.isLoadingMore = false,
    this.loadMoreFailure,
  });

  BudgetsState copyWith({
    BudgetCardPresentationData? activeCard,
    List<BudgetItemPresentationData>? items,
    String? nextCursor,
    bool? isLoadingMore,
    Failure? loadMoreFailure,
    bool clearActiveCard = false,
    bool clearNextCursor = false,
    bool clearLoadMoreFailure = false,
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
    activeCard,
    items,
    nextCursor,
    isLoadingMore,
    loadMoreFailure,
  ];
}
