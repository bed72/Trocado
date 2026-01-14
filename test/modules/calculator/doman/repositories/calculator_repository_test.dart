import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/modules/calculator/data/repositories/calculator_repository.dart';

void main() {
  late CalculatorRepository repository;

  setUp(() {
    repository = CalculatorRepository();
  });

  group('CalculatorRepository - Success', () {
    test('You must perform simple sums.', () {
      expect(repository.operation('2+2'), equals(4.0));
      expect(repository.operation('10+5+3'), equals(18.0));
    });

    test(
      'Operator precedence must be respected (multiplication before addition).',
      () {
        expect(repository.operation('2+3×4'), equals(14.0));
      },
    );

    test('You must correctly convert the × and ÷ symbols.', () {
      expect(repository.operation('10÷2'), equals(5.0));
      expect(repository.operation('5×5'), equals(25.0));
    });

    test('You must solve expressions with parentheses.', () {
      expect(repository.operation('(2+3)×4'), equals(20.0));
    });

    test('You must deal with decimal numbers.', () {
      expect(repository.operation('2.5+2.5'), equals(5.0));
      expect(repository.operation('10÷4'), equals(2.5));
    });

    test('You must solve mixed complex expressions.', () {
      expect(repository.operation('10+(2×3)-8÷2'), equals(12.0));
    });
  });

  group('CalculatorRepository - Complex Scenarios', () {
    test(
      'You must solve expressions with multiple levels of parentheses and decimals.',
      () {
        const expression = '10+((2×3)-8)÷(2.9+123.09)';
        final response = repository.operation(expression);

        expect(response, closeTo(9.984125, 0.000001));
      },
    );

    test(
      'You must deal with negative numbers responseing from subtractions.',
      () {
        expect(repository.operation('5-10×2'), equals(-15.0));
      },
    );

    test(
      'It must solve long sequences of the same precedence (left associativity).',
      () {
        expect(repository.operation('10-5-2'), equals(3.0));
        expect(repository.operation('20÷5÷2'), equals(2.0));
      },
    );

    test(
      'It should handle decimals without leading zeros (if the tokenizer allows it).',
      () {
        expect(repository.operation('0.5+0.5'), equals(1.0));
      },
    );

    test('Expression with redundant parentheses', () {
      expect(repository.operation('(((10+10)))'), equals(20.0));
    });

    test('Multiplication by zero in nested expressions', () {
      expect(repository.operation('(10+(5×2))×0'), equals(0.0));
    });
  });

  group('Structural Failure Scenarios', () {
    test('Unbalanced parentheses (opening)', () {
      expect(repository.operation('((10+2)').isNaN, isTrue);
    });

    test('Unbalanced parentheses (closing)', () {
      expect(repository.operation('(10+2))').isNaN, isTrue);
    });

    test('Operators without operands', () {
      expect(repository.operation('10+').isNaN, isTrue);
      expect(repository.operation('×10').isNaN, isTrue);
    });
  });

  group('CalculatorRepository - Failure', () {
    test('Should return NaN for mathematically invalid expressions.', () {
      expect(repository.operation('2++2').isNaN, isTrue);
      expect(repository.operation('abc').isNaN, isTrue);
      expect(repository.operation('((2+2)').isNaN, isTrue);
    });

    test(
      'It must handle division by zero (returning Infinity as per Darts default).',
      () {
        expect(repository.operation('10÷0'), equals(double.infinity));
      },
    );

    test('Should return NaN for empty string.', () {
      expect(repository.operation('').isNaN, isTrue);
    });
  });

  group('NaN', () {
    test('should return NaN when expression starts with minus operator', () {
      final response = repository.operation('-3+6');

      expect(response.isNaN, isTrue);
    });

    test('should return NaN when expression starts with plus operator', () {
      final response = repository.operation('+3+6');

      expect(response.isNaN, isTrue);
    });

    test(
      'should return NaN when expression starts with multiplication operator',
      () {
        final response = repository.operation('*3+6');

        expect(response.isNaN, isTrue);
      },
    );

    test('should return NaN when expression starts with division operator', () {
      final response = repository.operation('/3+6');

      expect(response.isNaN, isTrue);
    });

    test('should calculate expression correctly when expression is valid', () {
      final response = repository.operation('3+6');

      expect(response, equals(9));
    });

    test('should calculate expression with precedence correctly', () {
      final response = repository.operation('3+6*2');

      expect(response, equals(15));
    });

    test('should calculate expression with parenthesis correctly', () {
      final response = repository.operation('(3+6)*2');

      expect(response, equals(18));
    });

    test('should return NaN when expression is invalid', () {
      final response = repository.operation('3++6');

      expect(response.isNaN, isTrue);
    });
  });

  group('isInvalidFirstInput', () {
    test('should return true when value is plus operator', () {
      final result = repository.isInvalidFirstInput('+');

      expect(result, isTrue);
    });

    test('should return true when value is minus operator', () {
      final result = repository.isInvalidFirstInput('-');

      expect(result, isTrue);
    });

    test('should return true when value is multiplication operator', () {
      final result = repository.isInvalidFirstInput('*');

      expect(result, isTrue);
    });

    test('should return true when value is division operator', () {
      final result = repository.isInvalidFirstInput('/');

      expect(result, isTrue);
    });

    test('should return false when value is a number', () {
      final result = repository.isInvalidFirstInput('3');

      expect(result, isFalse);
    });

    test('should return false when value is dot', () {
      final result = repository.isInvalidFirstInput('.');

      expect(result, isFalse);
    });
  });
}
