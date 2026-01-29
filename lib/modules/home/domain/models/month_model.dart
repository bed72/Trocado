import 'package:equatable/equatable.dart';

final class MonthModel extends Equatable {
  final int year;
  final int month;

  const MonthModel({required this.year, required this.month});

  MonthModel get next => month == 12
      ? MonthModel(month: 1, year: year + 1)
      : MonthModel(month: month + 1, year: year);

  MonthModel get previous => month == 1
      ? MonthModel(month: 12, year: year - 1)
      : MonthModel(month: month - 1, year: year);

  int get startAt => DateTime(year, month, 1).millisecondsSinceEpoch;
  int get endAt =>
      DateTime(year, month + 1, 0, 23, 59, 59, 999).millisecondsSinceEpoch;

  factory MonthModel.now() {
    final now = DateTime.now();
    return MonthModel(month: now.month, year: now.year);
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
