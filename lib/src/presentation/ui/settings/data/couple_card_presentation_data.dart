import 'package:equatable/equatable.dart';

final class CoupleCardPresentationData extends Equatable {
  final String title;
  final String subtitle;
  final String partnerInitial;
  final String currentUserInitial;

  const CoupleCardPresentationData({
    required this.title,
    required this.subtitle,
    required this.partnerInitial,
    required this.currentUserInitial,
  });

  @override
  List<Object?> get props => [
    title,
    subtitle,
    partnerInitial,
    currentUserInitial,
  ];
}
