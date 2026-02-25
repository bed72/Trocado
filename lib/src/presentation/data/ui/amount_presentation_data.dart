enum CalculatorPresentationActionData { digit, clear, delete, submit }

final class AmountPresentationData {
  final String? value;
  final CalculatorPresentationActionData action;

  const AmountPresentationData.digit(this.value) : action = .digit;
  const AmountPresentationData.clear() : action = .clear, value = null;
  const AmountPresentationData.delete() : action = .delete, value = null;
  const AmountPresentationData.submit() : action = .submit, value = null;

  factory AmountPresentationData.map(String label) => switch (label) {
    '✓' => const .submit(),
    'AC' => const .clear(),
    'DEL' => const .delete(),
    _ => .digit(label),
  };
}
