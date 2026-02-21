import 'package:equatable/equatable.dart';

final class MonthPresentationData extends Equatable {
  final int year;
  final int month;

  const MonthPresentationData({required this.year, required this.month});

  MonthPresentationData get next => month == 12
      ? MonthPresentationData(month: 1, year: year + 1)
      : MonthPresentationData(month: month + 1, year: year);

  MonthPresentationData get previous => month == 1
      ? MonthPresentationData(month: 12, year: year - 1)
      : MonthPresentationData(month: month - 1, year: year);

  int get startAt => DateTime(year, month, 1).millisecondsSinceEpoch;
  int get endAt =>
      DateTime(year, month + 1, 0, 23, 59, 59, 999).millisecondsSinceEpoch;

  factory MonthPresentationData.now() {
    final now = DateTime.now();
    return MonthPresentationData(month: now.month, year: now.year);
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
