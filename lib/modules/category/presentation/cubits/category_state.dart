part of 'category_cubit.dart';

@immutable
final class CategoryState extends Equatable {
  final CategoryDto category;

  const CategoryState({required this.category});

  factory CategoryState.empty() => CategoryState(category: CategoryDto.other);

  @override
  List<Object> get props => [category];
}
