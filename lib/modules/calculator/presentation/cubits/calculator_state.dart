part of 'calculator_cubit.dart';

@immutable
final class CalculatorState extends Equatable {
  final double amount;
  final String preview;

  const CalculatorState({required this.amount, required this.preview});

  factory CalculatorState.empty() =>
      const CalculatorState(amount: 0.0, preview: '...');

  CalculatorState copyWith({double? amount, String? preview}) =>
      CalculatorState(
        amount: amount ?? this.amount,
        preview: preview ?? this.preview,
      );

  @override
  List<Object?> get props => [amount, preview];
}
