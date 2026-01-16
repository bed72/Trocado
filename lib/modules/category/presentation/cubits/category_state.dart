part of 'category_cubit.dart';

@immutable
final class CategoryState extends Equatable {
  final CategoryData category;

  const CategoryState({required this.category});

  factory CategoryState.empty() => CategoryState(category: CategoryData.other);

  @override
  List<Object> get props => [category];
}
