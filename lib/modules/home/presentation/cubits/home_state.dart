part of 'home_cubit.dart';

@immutable
sealed class HomeState extends Equatable {
  const HomeState();

  @override
  List<Object> get props => [];
}

final class HomeIdle extends HomeState {}

final class HomeLoading extends HomeState {}

final class HomeFailure extends HomeState {
  final String failure;

  const HomeFailure({required this.failure});

  @override
  List<Object> get props => [failure];
}

final class HomeSuccess extends HomeState {
  final HomeModel home;
  final bool hasReachedEnd;
  final bool isLoadingMore;
  final TransactionTypeDto? type;

  const HomeSuccess({
    required this.home,
    this.type,
    this.isLoadingMore = false,
    this.hasReachedEnd = false,
  });

  HomeSuccess copyWith({
    HomeModel? home,
    bool? hasReachedEnd,
    bool? isLoadingMore,
    TransactionTypeDto? type,
  }) => HomeSuccess(
    home: home ?? this.home,
    type: type ?? this.type,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    hasReachedEnd: hasReachedEnd ?? this.hasReachedEnd,
  );

  @override
  List<Object> get props => [home, isLoadingMore, hasReachedEnd];
}
