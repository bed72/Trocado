import 'package:rearch/rearch.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/src/presentation/capsules/description_capsule.dart';

void main() {
  late CapsuleContainer container;

  setUp(() {
    container = CapsuleContainer();
  });

  test('descriptionCapsule should start empty and update value', () {
    final (value, setValue) = container.read(descriptionCapsule);
    expect(value, '');

    setValue('Nova descrição');
    final (update, _) = container.read(descriptionCapsule);
    expect(update, 'Nova descrição');
  });
}
