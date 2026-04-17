enum CalculatorPresentationActionData { digit, clear, delete, submit }

final class CalculatorPresentationData {
  final String? value;
  final CalculatorPresentationActionData action;

  const CalculatorPresentationData.digit(this.value) : action = .digit;
  const CalculatorPresentationData.clear() : action = .clear, value = null;
  const CalculatorPresentationData.delete() : action = .delete, value = null;
  const CalculatorPresentationData.submit() : action = .submit, value = null;

  factory CalculatorPresentationData.map(String label) => switch (label) {
    '✓' => const .submit(),
    'AC' => const .clear(),
    'DEL' => const .delete(),
    _ => .digit(label),
  };
}
