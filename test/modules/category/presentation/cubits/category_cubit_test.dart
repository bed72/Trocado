import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/modules/category/data/dtos/category_dto.dart';
import 'package:trocado/modules/category/presentation/cubits/category_cubit.dart';

void main() {
  group('CategoryCubit', () {
    test('initial state should be empty', () {
      final cubit = CategoryCubit();

      expect(cubit.state.category, CategoryDto.other);

      cubit.close();
    });

    blocTest<CategoryCubit, CategoryState>(
      'emits selected category when select is called',
      build: () => CategoryCubit(),
      act: (cubit) => cubit.select(.salary),
      expect: () => [const CategoryState(category: .salary)],
    );

    blocTest<CategoryCubit, CategoryState>(
      'emits empty state when reset is called',
      build: () => CategoryCubit(),
      act: (cubit) {
        cubit.select(.food);
        cubit.reset();
      },
      expect: () => [
        const CategoryState(category: .food),
        const CategoryState(category: .other),
      ],
    );

    blocTest<CategoryCubit, CategoryState>(
      'overwrites previous category when select is called multiple times',
      build: () => CategoryCubit(),
      act: (cubit) {
        cubit.select(.salary);
        cubit.select(.transport);
      },
      expect: () => [
        const CategoryState(category: .salary),
        const CategoryState(category: .transport),
      ],
    );
  });
}
