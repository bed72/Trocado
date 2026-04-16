sealed class CalculatorIntent {
  const CalculatorIntent();
}

final class DigitPressed extends CalculatorIntent {
  final String digit;
  const DigitPressed(this.digit);
}

final class DeletePressed extends CalculatorIntent {
  const DeletePressed();
}

final class ClearPressed extends CalculatorIntent {
  const ClearPressed();
}
