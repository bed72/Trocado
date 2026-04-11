import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/src/infrastructure/clients/http/responses/failure/failure_response.dart';

void main() {
  group('FailureResponse.fromJson', () {
    test('deserializes single validation error', () {
      final json = {
        'errors': [
          {
            'field': 'email',
            'code': 'required',
            'message': 'This field is required.',
          },
        ],
      };

      final data = FailureResponse.fromJson(json);

      expect(data.errors.length, 1);
      expect(data.errors.first.field, 'email');
      expect(data.errors.first.code, 'required');
      expect(data.errors.first.message, 'This field is required.');
    });

    test('deserializes non_field_errors', () {
      final json = {
        'errors': [
          {
            'code': 'invalid',
            'field': 'non_field_errors',
            'message': 'Invalid credentials.',
          },
        ],
      };

      final data = FailureResponse.fromJson(json);

      expect(data.errors.first.code, 'invalid');
      expect(data.errors.first.field, 'non_field_errors');
    });

    test('deserializes multiple errors', () {
      final json = {
        'errors': [
          {
            'field': 'email',
            'code': 'required',
            'message': 'This field is required.',
          },
          {
            'code': 'required',
            'field': 'password',
            'message': 'This field is required.',
          },
        ],
      };

      final data = FailureResponse.fromJson(json);

      expect(data.errors.length, 2);
    });

    test('deserializes empty errors list', () {
      final json = {'errors': <dynamic>[]};

      final data = FailureResponse.fromJson(json);

      expect(data.errors, isEmpty);
    });
  });
}
