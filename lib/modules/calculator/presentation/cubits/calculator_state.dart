part of 'calculator_cubit.dart';

@immutable
final class CalculatorState extends Equatable {
  final double amount;

  const CalculatorState({required this.amount});

  factory CalculatorState.empty() => const CalculatorState(amount: 0.0);

  CalculatorState copyWith({double? amount}) =>
      CalculatorState(amount: amount ?? this.amount);

  @override
  List<Object?> get props => [amount];
}
