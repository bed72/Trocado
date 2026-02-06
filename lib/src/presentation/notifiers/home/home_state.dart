import 'package:flutter/foundation.dart';
import 'package:equatable/equatable.dart';

import 'package:trocado/src/presentation/notifiers/data/home_data.dart';

@immutable
sealed class HomeState extends Equatable {
  const HomeState();

  @override
  List<Object> get props => [];
}

final class HomeLoading extends HomeState {}

final class HomeFailure extends HomeState {
  final String failure;

  const HomeFailure({required this.failure});

  @override
  List<Object> get props => [failure];
}

final class HomeSuccess extends HomeState {
  final HomeData data;

  const HomeSuccess({required this.data});

  HomeSuccess copyWith({HomeData? data}) =>
      HomeSuccess(data: data ?? this.data);

  @override
  List<Object> get props => [data];
}
