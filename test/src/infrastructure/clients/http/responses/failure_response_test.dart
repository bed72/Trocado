import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/src/infrastructure/clients/http/responses/failure/failure_response.dart';

void main() {
  group('FailureResponse.fromJson', () {
    test('deserializes status and source field', () {
      final data = FailureResponse.fromJson(const {
        'errors': [
          {
            'status': '422',
            'code': 'INVALID_AMOUNT',
            'message': 'O valor informado é inválido.',
            'source': {'field': 'email'},
          },
        ],
      });

      expect(data.errors, hasLength(1));
      expect(data.errors.first.status, '422');
      expect(data.errors.first.code, 'INVALID_AMOUNT');
      expect(data.errors.first.source?.field, 'email');
      expect(data.errors.first.message, 'O valor informado é inválido.');
    });

    test('preserves every error item', () {
      final data = FailureResponse.fromJson(const {
        'errors': [
          {'code': 'required', 'message': 'Email is required.'},
          {'code': 'required', 'message': 'Password is required.'},
        ],
      });

      expect(data.errors, hasLength(2));
    });

    test('deserializes an empty errors list', () {
      final data = FailureResponse.fromJson(const {'errors': <dynamic>[]});

      expect(data.errors, isEmpty);
    });
  });
}
