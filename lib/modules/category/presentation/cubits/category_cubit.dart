import 'package:flutter/foundation.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trocado/modules/category/category.dart';

part 'category_state.dart';

final class CategoryCubit extends Cubit<CategoryState> {
  CategoryCubit() : super(CategoryState.empty());

  void reset() {
    emit(CategoryState.empty());
  }

  void select(CategoryData date) {
    emit(CategoryState(category: date));
  }
}
