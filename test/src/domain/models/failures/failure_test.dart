import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/src/domain/failures/failure.dart';

void main() {
  group('Failure', () {
    group('default messages', () {
      test('NetworkFailure has non-empty default message', () {
        const failure = NetworkFailure();
        expect(failure.message, isNotEmpty);
      });

      test('NotFoundFailure has non-empty default message', () {
        const failure = NotFoundFailure();
        expect(failure.message, isNotEmpty);
      });

      test('ServerFailure has non-empty default message', () {
        const failure = ServerFailure();
        expect(failure.message, isNotEmpty);
      });

      test('UnknownFailure has non-empty default message', () {
        const failure = UnknownFailure();
        expect(failure.message, isNotEmpty);
      });
    });

    group('custom message', () {
      test('ValidationFailure accepts custom message', () {
        const failure = ValidationFailure('Valor deve ser maior que zero');
        expect(failure.message, 'Valor deve ser maior que zero');
      });

      test('NetworkFailure accepts custom message', () {
        const failure = NetworkFailure('Timeout após 30 segundos');
        expect(failure.message, 'Timeout após 30 segundos');
      });
    });

    group('toString', () {
      test('returns message', () {
        const failure = ValidationFailure('msg de erro');
        expect(failure.toString(), equals(failure.message));
      });

      test('NetworkFailure toString equals message', () {
        const failure = NetworkFailure();
        expect(failure.toString(), equals(failure.message));
      });
    });
  });
}
