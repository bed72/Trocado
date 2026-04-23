import 'package:equatable/equatable.dart';

final class CalculatorState extends Equatable {
  final String digits;
  final String displayValue;

  const CalculatorState({this.digits = '', this.displayValue = ''});

  int get centValue => digits.isEmpty ? 0 : int.parse(digits);

  CalculatorState copyWith({String? digits, String? displayValue}) =>
      CalculatorState(
        digits: digits ?? this.digits,
        displayValue: displayValue ?? this.displayValue,
      );

  @override
  List<Object?> get props => [digits, displayValue];
}
