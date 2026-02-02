part of 'date_cubit.dart';

@immutable
final class DateState extends Equatable {
  final DateTime date;
  final String formatted;

  const DateState({required this.date, required this.formatted});

  factory DateState.empty() => DateState(date: DateTime.now(), formatted: '');

  @override
  List<Object?> get props => [date, formatted];
}
