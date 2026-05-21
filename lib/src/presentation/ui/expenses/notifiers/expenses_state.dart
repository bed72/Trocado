import 'package:equatable/equatable.dart';

import 'package:trocado/src/domain/failures/failure.dart';
import 'package:trocado/src/domain/enums/scope/financial_scope_enum.dart';
import 'package:trocado/src/domain/models/expense/expense_filter_model.dart';

import 'package:trocado/src/presentation/data/expense_item_presentation_data.dart';
import 'package:trocado/src/presentation/ui/expenses/data/expense_group_presentation_data.dart';
import 'package:trocado/src/presentation/ui/expenses/data/expense_active_filter_chip_presentation_data.dart';

final class ExpensesState extends Equatable {
  final bool isInCouple;
  final String? nextCursor;
  final bool isLoadingMore;
  final FinancialScopeEnum scope;
  final Failure? deleteFailure;
  final Failure? loadMoreFailure;
  final ExpenseFilterModel filter;
  final List<ExpenseItemPresentationData> items;
  final List<ExpenseGroupPresentationData> groups;
  final List<ExpenseActiveFilterChipPresentationData> activeFilterChips;

  const ExpensesState({
    this.nextCursor,
    this.deleteFailure,
    this.loadMoreFailure,
    this.items = const [],
    this.groups = const [],
    this.isInCouple = false,
    this.isLoadingMore = false,
    this.scope = FinancialScopeEnum.mine,
    this.filter = const .empty(),
    this.activeFilterChips = const [],
  });

  ExpensesState copyWith({
    bool? isInCouple,
    String? nextCursor,
    bool? isLoadingMore,
    FinancialScopeEnum? scope,
    Failure? deleteFailure,
    Failure? loadMoreFailure,
    ExpenseFilterModel? filter,
    bool clearNextCursor = false,
    bool clearDeleteFailure = false,
    bool clearLoadMoreFailure = false,
    List<ExpenseItemPresentationData>? items,
    List<ExpenseGroupPresentationData>? groups,
    List<ExpenseActiveFilterChipPresentationData>? activeFilterChips,
  }) => ExpensesState(
    items: items ?? this.items,
    groups: groups ?? this.groups,
    filter: filter ?? this.filter,
    scope: scope ?? this.scope,
    isInCouple: isInCouple ?? this.isInCouple,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    activeFilterChips: activeFilterChips ?? this.activeFilterChips,
    nextCursor: clearNextCursor ? null : nextCursor ?? this.nextCursor,
    deleteFailure: clearDeleteFailure
        ? null
        : deleteFailure ?? this.deleteFailure,
    loadMoreFailure: clearLoadMoreFailure
        ? null
        : loadMoreFailure ?? this.loadMoreFailure,
  );

  @override
  List<Object?> get props => [
    items,
    groups,
    scope,
    filter,
    nextCursor,
    isInCouple,
    isLoadingMore,
    deleteFailure,
    loadMoreFailure,
    activeFilterChips,
  ];
}
