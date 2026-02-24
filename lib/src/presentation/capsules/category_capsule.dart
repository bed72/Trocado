import 'package:rearch/rearch.dart';

import 'package:trocado/src/presentation/data/category_presentation_data.dart';

(CategoryPresentationData, void Function(CategoryPresentationData))
categoryCapsule(CapsuleHandle use) {
  final (value, setValue) = use.state<CategoryPresentationData>(.other);

  return (value, setValue);
}
