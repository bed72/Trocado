import 'package:equatable/equatable.dart';

sealed class HomeAppBarPresentationData extends Equatable {
  const HomeAppBarPresentationData();

  @override
  List<Object?> get props => const [];
}

final class HomeAppBarSoloPresentationData extends HomeAppBarPresentationData {
  final String name;

  const HomeAppBarSoloPresentationData({required this.name});

  @override
  List<Object?> get props => [name];
}

final class HomeAppBarCouplePresentationData
    extends HomeAppBarPresentationData {
  final String title;
  final String currentInitial;
  final String partnerInitial;

  const HomeAppBarCouplePresentationData({
    required this.title,
    required this.currentInitial,
    required this.partnerInitial,
  });

  @override
  List<Object?> get props => [title, currentInitial, partnerInitial];
}
