import 'package:rearch/rearch.dart';

import 'package:trocado/src/main/capsules/capsules.dart';
import 'package:trocado/src/presentation/data/ui/amount_presentation_data.dart';

(String, void Function(AmountPresentationData)) amountCapsule(
  CapsuleHandle use,
) {
  final service = use(moneyServiceCapsule);
  final (amount, setAmount) = use.state<int>(0);

  final formatted = service.format(amount / 100);

  void onChange(AmountPresentationData data) {
    switch (data.action) {
      case .digit:
        final digit = int.parse(data.value!);
        setAmount(amount * 10 + digit);
        break;

      case .delete:
        setAmount(amount ~/ 10);
        break;

      case .clear:
        setAmount(0);
        break;

      case .submit:
        break;
    }
  }

  return (formatted, onChange);
}
