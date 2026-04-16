import 'package:equatable/equatable.dart';

final class CalculatorState extends Equatable {
  final String rawDigits;
  final String displayValue;

  const CalculatorState({
    this.rawDigits = '',
    this.displayValue = '',
  });

  int get centValue => rawDigits.isEmpty ? 0 : int.parse(rawDigits);

  CalculatorState copyWith({
    String? rawDigits,
    String? displayValue,
  }) => CalculatorState(
    rawDigits: rawDigits ?? this.rawDigits,
    displayValue: displayValue ?? this.displayValue,
  );

  @override
  List<Object?> get props => [rawDigits, displayValue];
}
