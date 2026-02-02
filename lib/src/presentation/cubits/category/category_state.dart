part of 'category_cubit.dart';

@immutable
final class CategoryState extends Equatable {
  final CategoryModel category;

  const CategoryState({required this.category});

  factory CategoryState.empty() => CategoryState(category: CategoryModel.other);

  @override
  List<Object> get props => [category];
}
