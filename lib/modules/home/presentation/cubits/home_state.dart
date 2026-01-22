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

  const HomeSuccess({required this.home});

  @override
  List<Object> get props => [home];
}
