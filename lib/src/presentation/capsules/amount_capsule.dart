import 'package:rearch/rearch.dart';

import 'package:trocado/src/main/capsules/capsules.dart';
import 'package:trocado/src/presentation/data/calculator_presentation_data.dart';

(String, void Function(CalculatorPresentationData)) amountCapsule(
  CapsuleHandle use,
) {
  final service = use(moneyServiceCapsule);
  final (cents, setCents) = use.state<int>(0);

  void onInput(CalculatorPresentationData data) {
    switch (data.action) {
      case .digit:
        final digit = int.parse(data.value!);
        setCents(cents * 10 + digit);
        break;

      case .delete:
        setCents(cents ~/ 10);
        break;

      case .clear:
        setCents(0);
        break;

      case .decimal:
      case .submit:
        break;
    }
  }

  final formatted = service.format(cents / 100);

  return (formatted, onInput);
}
