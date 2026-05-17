import 'package:equatable/equatable.dart';

import 'package:trocado/src/presentation/ui/settings/data/couple_card_presentation_data.dart';

sealed class CoupleCardState extends Equatable {
  const CoupleCardState();

  @override
  List<Object?> get props => const [];
}

final class CoupleConnectedState extends CoupleCardState {
  final CoupleCardPresentationData data;

  const CoupleConnectedState(this.data);

  @override
  List<Object?> get props => [data];
}

final class CoupleNoneState extends CoupleCardState {
  const CoupleNoneState();
}

final class CoupleFailureState extends CoupleCardState {
  final String message;

  const CoupleFailureState(this.message);

  @override
  List<Object?> get props => [message];
}
