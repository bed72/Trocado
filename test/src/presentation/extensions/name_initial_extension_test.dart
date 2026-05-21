import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/src/presentation/extensions/name_initial_extension.dart';

void main() {
  group('toInitial', () {
    test('returns uppercase first letter of plain name', () {
      expect('Gabriel'.toInitial(), 'G');
    });

    test('trims whitespace before extracting', () {
      expect('  Marina  '.toInitial(), 'M');
    });

    test('returns empty string when name is empty', () {
      expect(''.toInitial(), '');
    });

    test('returns empty string when name is only whitespace', () {
      expect('   '.toInitial(), '');
    });

    test('returns uppercase of single character', () {
      expect('a'.toInitial(), 'A');
    });

    test('preserves diacritic uppercase', () {
      expect('Ágata'.toInitial(), 'Á');
    });

    test('returns emoji as initial', () {
      expect('🦊 Foxy'.toInitial(), '🦊');
    });
  });
}
