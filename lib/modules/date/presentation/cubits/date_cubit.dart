import 'package:intl/intl.dart';
import 'package:flutter/widgets.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'date_state.dart';

final class DateCubit extends Cubit<DateState> {
  DateCubit() : super(DateState.empty());

  void reset() {
    emit(DateState.empty());
  }

  void select(DateTime date) {
    emit(DateState(date: date, formatted: _format(date)));
  }

  String _format(DateTime date) =>
      DateFormat('dd/MM/yyyy', 'pt_BR').format(date);
}
