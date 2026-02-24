enum CalculatorPresentationActionData { digit, clear, delete, submit, decimal }

final class CalculatorPresentationData {
  final String? value;
  final CalculatorPresentationActionData action;

  const CalculatorPresentationData.digit(this.value) : action = .digit;
  const CalculatorPresentationData.clear() : action = .clear, value = null;
  const CalculatorPresentationData.delete() : action = .delete, value = null;
  const CalculatorPresentationData.submit() : action = .submit, value = null;
  const CalculatorPresentationData.decimal() : action = .decimal, value = null;
}
