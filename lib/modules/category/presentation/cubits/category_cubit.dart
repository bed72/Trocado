import 'package:flutter/foundation.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:trocado/modules/category/data/dtos/category_dto.dart';

part 'category_state.dart';

final class CategoryCubit extends Cubit<CategoryState> {
  CategoryCubit() : super(CategoryState.empty());

  void clear() {
    emit(CategoryState.empty());
  }

  void select(CategoryDto category) {
    emit(CategoryState(category: category));
  }
}
