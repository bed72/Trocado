import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/modules/core/domain/either/either.dart';

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
      final data = either.mapRight((number) => number * 2);

      expect(data.isRight, isTrue);
      expect(data.right, equals(4));
    });

    test('map should not affect Left', () {
      final either = Left<String, int>('fail');
      final data = either.mapRight((number) => number * 2);

      expect(data.isLeft, isTrue);
      expect(data.left, equals('fail'));
    });

    test('mapLeft should transform Left value', () {
      final either = Left<String, int>('fail');
      final data = either.mapLeft((message) => message.toUpperCase());

      expect(data.isLeft, isTrue);
      expect(data.left, equals('FAIL'));
    });

    test('mapLeft should not affect Right', () {
      final either = Right<String, int>(10);
      final data = either.mapLeft((message) => message.toUpperCase());

      expect(data.isRight, isTrue);
      expect(data.right, equals(10));
    });

    test('flatMap should chain Right values', () {
      final either = Right<String, int>(2);
      final data = either.flatMap(
        (number) => Right<String, String>('value: $number'),
      );

      expect(data.isRight, isTrue);
      expect(data.right, equals('value: 2'));
    });

    test('flatMap should propagate Left', () {
      final either = Left<String, int>('error');
      final data = either.flatMap((_) => Right<String, String>('ok'));

      expect(data.isLeft, isTrue);
      expect(data.left, equals('error'));
    });

    test('either should transform both sides', () {
      final left = Left<int, String>(
        10,
      ).either((left) => left * 2, (right) => right.length);
      final right = Right<int, String>(
        'abc',
      ).either((left) => left * 2, (right) => right.length);

      expect(left.left, equals(20));
      expect(right.right, equals(3));
    });

    test('swap should convert Left to Right and Right to Left', () {
      final right = Right<String, int>(42).swap();
      final left = Left<String, int>('fail').swap();

      expect(right.isLeft, isTrue);
      expect(right.left, equals(42));

      expect(left.isRight, isTrue);
      expect(left.right, equals('fail'));
    });

    test('tryCatch should return Right on success', () {
      final data = Either.tryCatch<String, int, FormatException>(
        (exception) => exception.toString(),
        () => int.parse('123'),
      );

      expect(data.isRight, isTrue);
      expect(data.right, equals(123));
    });

    test('tryCatch should return Left on exception', () {
      final data = Either.tryCatch<String, int, FormatException>(
        (_) => 'bad format',
        () => int.parse('abc'),
      );

      expect(data.isLeft, isTrue);
      expect(data.left, equals('bad format'));
    });

    test('tryExcept should return Right on success', () {
      final data = Either.tryExcept<FormatException, int>(
        () => int.parse('42'),
      );

      expect(data.isRight, isTrue);
      expect(data.right, equals(42));
    });

    test('tryExcept should return Left on exception', () {
      final data = Either.tryExcept<FormatException, int>(
        () => int.parse('abc'),
      );

      expect(data.isLeft, isTrue);
      expect(data.left, isA<FormatException>());
    });

    test('cond should return Right when condition is true', () {
      final data = Either.cond(true, 'fail', 42);

      expect(data.isRight, isTrue);
      expect(data.right, equals(42));
    });

    test('cond should return Left when condition is false', () {
      final data = Either.cond(false, 'fail', 42);

      expect(data.isLeft, isTrue);
      expect(data.left, equals('fail'));
    });

    test('condLazy should lazily evaluate values', () {
      bool called = false;

      final data = Either.condLazy(true, () {
        called = true;
        return 'fail';
      }, () => 99);

      expect(called, isFalse);
      expect(data.isRight, isTrue);
      expect(data.right, equals(99));
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
