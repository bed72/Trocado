import 'package:flutter/foundation.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:trocado/modules/category/domain/models/category_model.dart';

part 'category_state.dart';

final class CategoryCubit extends Cubit<CategoryState> {
  CategoryCubit() : super(CategoryState.empty());

  void clear() {
    emit(CategoryState.empty());
  }

  void select(CategoryModel category) {
    emit(CategoryState(category: category));
  }
}
