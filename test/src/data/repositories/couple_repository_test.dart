import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/src/domain/either/either.dart';
import 'package:trocado/src/domain/failures/failure.dart';
import 'package:trocado/src/domain/repositories/interface_couple_repository.dart';

import 'package:trocado/src/data/repositories/couple_repository.dart';

import 'package:trocado/src/infrastructure/datasources/remote/remote_couple_data_source.dart';

import 'package:trocado/src/infrastructure/clients/http/responses/couple/invite_response.dart';
import 'package:trocado/src/infrastructure/clients/http/responses/failure/failure_response.dart';

import '../../../mocks/mocks.dart';

FailureResponse _failure(String code, String message) => FailureResponse(
  errors: [
    FailureItemResponse(
      code: code,
      message: message,
      field: 'non_field_errors',
    ),
  ],
);

void main() {
  late ICoupleRepository repository;
  late IRemoteCoupleDataSource dataSource;

  setUp(() {
    dataSource = MockRemoteCoupleDataSource();
    repository = CoupleRepository(dataSource: dataSource);
  });

  group('createInvite', () {
    test('returns Right with InviteModel on success', () async {
      when(() => dataSource.createInvite()).thenAnswer(
        (_) async => Right(
          InviteResponse(
            code: 'A3K7FN',
            qrData: 'trocado://invite/A3K7FN',
            expiresAt: '2026-03-18T14:30:00Z',
          ),
        ),
      );

      final data = await repository.createInvite();

      expect(data.isRight, isTrue);
      expect(data.right.code, 'A3K7FN');
      expect(data.right.qrData, 'trocado://invite/A3K7FN');
      expect(
        data.right.expiresAt,
        DateTime.parse('2026-03-18T14:30:00Z').millisecondsSinceEpoch,
      );
    });

    test('returns Left NetworkFailure on network error', () async {
      when(() => dataSource.createInvite()).thenAnswer(
        (_) async => Left(_failure('network_error', 'Network error')),
      );

      final data = await repository.createInvite();

      expect(data.isLeft, isTrue);
      expect(data.left, isA<NetworkFailure>());
    });

    test('returns Left ServerFailure on server error', () async {
      when(() => dataSource.createInvite()).thenAnswer(
        (_) async => Left(_failure('server_error', 'Internal server error')),
      );

      final data = await repository.createInvite();

      expect(data.isLeft, isTrue);
      expect(data.left, isA<ServerFailure>());
    });

    test('returns Left NotFoundFailure on not found', () async {
      when(
        () => dataSource.createInvite(),
      ).thenAnswer((_) async => Left(_failure('not_found', 'Not found.')));

      final data = await repository.createInvite();

      expect(data.isLeft, isTrue);
      expect(data.left, isA<NotFoundFailure>());
    });

    test('returns Left ValidationFailure on unknown code', () async {
      when(() => dataSource.createInvite()).thenAnswer(
        (_) async =>
            Left(_failure('already_has_couple', 'Você já tem um parceiro.')),
      );

      final data = await repository.createInvite();

      expect(data.isLeft, isTrue);
      expect(data.left, isA<ValidationFailure>());
      expect(data.left.message, 'Você já tem um parceiro.');
    });
  });
}
