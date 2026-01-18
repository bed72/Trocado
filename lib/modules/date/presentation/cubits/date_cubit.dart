import 'package:flutter/widgets.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trocado/modules/core/core.dart';

part 'date_state.dart';

final class DateCubit extends Cubit<DateState> {
  DateCubit() : super(DateState.empty());

  void reset() {
    emit(DateState.empty());
  }

  void select(DateTime date) {
    emit(DateState(date: date, formatted: date.format()));
  }
}
