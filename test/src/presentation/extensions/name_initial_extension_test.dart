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

  group('toFirstName', () {
    test('returns full name when there is no whitespace', () {
      expect('Gabriel'.toFirstName(), 'Gabriel');
    });

    test('returns only first token when name has multiple parts', () {
      expect('Gabriel Ramos'.toFirstName(), 'Gabriel');
    });

    test('returns only first token when name has many parts', () {
      expect('Maria Eduarda Silva Santos'.toFirstName(), 'Maria');
    });

    test('trims whitespace before extracting first token', () {
      expect('  Gabriel Ramos  '.toFirstName(), 'Gabriel');
    });

    test('returns empty string when name is empty', () {
      expect(''.toFirstName(), '');
    });

    test('returns empty string when name is only whitespace', () {
      expect('   '.toFirstName(), '');
    });

    test('preserves diacritics in first name', () {
      expect('Ágata Souza'.toFirstName(), 'Ágata');
    });
  });
}
