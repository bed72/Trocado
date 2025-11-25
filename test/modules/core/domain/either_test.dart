import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/modules/core/domain/either.dart';

void main() {
  group('Either', () {
    test('Left should be recognized as isLeft and not isRight', () {
      final either = Left<String, int>('error');

      expect(either.isLeft, isTrue);
      expect(either.isRight, isFalse);
      expect(either.left, equals('error'));
      expect(() => either.right, throwsA(isA<StateError>()));
    });

    test('Right should be recognized as isRight and not isLeft', () {
      final either = Right<String, int>(42);

      expect(either.isRight, isTrue);
      expect(either.isLeft, isFalse);
      expect(either.right, equals(42));
      expect(() => either.left, throwsA(isA<StateError>()));
    });

    test('map should transform Right value', () {
      final either = Right<String, int>(2);
      final result = either.mapRight((n) => n * 2);

      expect(result.isRight, isTrue);
      expect(result.right, equals(4));
    });

    test('map should not affect Left', () {
      final either = Left<String, int>('fail');
      final result = either.mapRight((n) => n * 2);

      expect(result.isLeft, isTrue);
      expect(result.left, equals('fail'));
    });

    test('mapLeft should transform Left value', () {
      final either = Left<String, int>('fail');
      final result = either.mapLeft((msg) => msg.toUpperCase());

      expect(result.isLeft, isTrue);
      expect(result.left, equals('FAIL'));
    });

    test('mapLeft should not affect Right', () {
      final either = Right<String, int>(10);
      final result = either.mapLeft((msg) => msg.toUpperCase());

      expect(result.isRight, isTrue);
      expect(result.right, equals(10));
    });

    test('flatMap should chain Right values', () {
      final either = Right<String, int>(2);
      final result = either.flatMap((n) => Right<String, String>('value: $n'));

      expect(result.isRight, isTrue);
      expect(result.right, equals('value: 2'));
    });

    test('flatMap should propagate Left', () {
      final either = Left<String, int>('error');
      final result = either.flatMap((n) => Right<String, String>('ok'));

      expect(result.isLeft, isTrue);
      expect(result.left, equals('error'));
    });

    test('either should transform both sides', () {
      final left = Left<int, String>(10).either((l) => l * 2, (r) => r.length);
      final right = Right<int, String>(
        'abc',
      ).either((l) => l * 2, (r) => r.length);

      expect(left.left, equals(20));
      expect(right.right, equals(3));
    });

    test('swap should convert Left to Right and Right to Left', () {
      final left = Left<String, int>('fail').swap();
      final right = Right<String, int>(42).swap();

      expect(left.isRight, isTrue);
      expect(left.right, equals('fail'));

      expect(right.isLeft, isTrue);
      expect(right.left, equals(42));
    });

    test('tryCatch should return Right on success', () {
      final result = Either.tryCatch<String, int, FormatException>(
        (e) => e.toString(),
        () => int.parse('123'),
      );

      expect(result.isRight, isTrue);
      expect(result.right, equals(123));
    });

    test('tryCatch should return Left on exception', () {
      final result = Either.tryCatch<String, int, FormatException>(
        (e) => 'bad format',
        () => int.parse('abc'),
      );

      expect(result.isLeft, isTrue);
      expect(result.left, equals('bad format'));
    });

    test('tryExcept should return Right on success', () {
      final result = Either.tryExcept<FormatException, int>(
        () => int.parse('42'),
      );

      expect(result.isRight, isTrue);
      expect(result.right, equals(42));
    });

    test('tryExcept should return Left on exception', () {
      final result = Either.tryExcept<FormatException, int>(
        () => int.parse('abc'),
      );

      expect(result.isLeft, isTrue);
      expect(result.left, isA<FormatException>());
    });

    test('cond should return Right when condition is true', () {
      final result = Either.cond(true, 'fail', 42);

      expect(result.isRight, isTrue);
      expect(result.right, equals(42));
    });

    test('cond should return Left when condition is false', () {
      final result = Either.cond(false, 'fail', 42);

      expect(result.isLeft, isTrue);
      expect(result.left, equals('fail'));
    });

    test('condLazy should lazily evaluate values', () {
      var called = false;

      final result = Either.condLazy(true, () {
        called = true;
        return 'fail';
      }, () => 99);

      expect(result.isRight, isTrue);
      expect(result.right, equals(99));
      expect(called, isFalse); // left not evaluated
    });

    test('equality should compare values correctly', () {
      expect(Left('x'), equals(Left('x')));
      expect(Right(42), equals(Right(42)));
      expect(Left('x'), isNot(equals(Right('x'))));
    });

    test('hashCode should match equal objects', () {
      expect(Left('x').hashCode, equals(Left('x').hashCode));
      expect(Right(42).hashCode, equals(Right(42).hashCode));
    });
  });
}
