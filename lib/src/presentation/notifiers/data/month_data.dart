import 'package:equatable/equatable.dart';

final class MonthData extends Equatable {
  final int year;
  final int month;

  const MonthData({required this.year, required this.month});

  MonthData get next => month == 12
      ? MonthData(month: 1, year: year + 1)
      : MonthData(month: month + 1, year: year);

  MonthData get previous => month == 1
      ? MonthData(month: 12, year: year - 1)
      : MonthData(month: month - 1, year: year);

  int get startAt => DateTime(year, month, 1).millisecondsSinceEpoch;
  int get endAt =>
      DateTime(year, month + 1, 0, 23, 59, 59, 999).millisecondsSinceEpoch;

  factory MonthData.now() {
    final now = DateTime.now();
    return MonthData(month: now.month, year: now.year);
  }

  String get label {
    const months = [
      'Janeiro',
      'Fevereiro',
      'Março',
      'Abril',
      'Maio',
      'Junho',
      'Julho',
      'Agosto',
      'Setembro',
      'Outubro',
      'Novembro',
      'Dezembro',
    ];

    return '${months[month - 1]} $year';
  }

  @override
  List<Object?> get props => [month, year];
}
