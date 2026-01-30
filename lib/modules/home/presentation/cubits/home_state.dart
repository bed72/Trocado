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
  final MonthModel month;
  final bool hasReachedEnd;
  final bool isLoadingMore;
  final TransactionTypeModel? type;

  const HomeSuccess({
    required this.home,
    required this.month,
    this.type,
    this.isLoadingMore = false,
    this.hasReachedEnd = false,
  });

  HomeSuccess copyWith({
    HomeModel? home,
    MonthModel? month,
    bool? hasReachedEnd,
    bool? isLoadingMore,
    TransactionTypeModel? type,
  }) => HomeSuccess(
    home: home ?? this.home,
    type: type ?? this.type,
    month: month ?? this.month,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    hasReachedEnd: hasReachedEnd ?? this.hasReachedEnd,
  );

  @override
  List<Object> get props => [home, month, isLoadingMore, hasReachedEnd];
}
