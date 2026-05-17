import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/src/data/repositories/couple_repository.dart';

import 'package:trocado/src/domain/either/either.dart';
import 'package:trocado/src/domain/failures/failure.dart';
import 'package:trocado/src/domain/repositories/interface_couple_repository.dart';

import 'package:trocado/src/infrastructure/datasources/remote/remote_couple_data_source.dart';

import 'package:trocado/src/infrastructure/clients/share/share_client.dart';
import 'package:trocado/src/infrastructure/clients/http/responses/user_response.dart';
import 'package:trocado/src/infrastructure/clients/http/responses/couple/couple_response.dart';
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
  late IShareClient shareClient;
  late ICoupleRepository repository;
  late IRemoteCoupleDataSource dataSource;

  setUp(() {
    shareClient = MockShareClient();
    dataSource = MockRemoteCoupleDataSource();
    repository = CoupleRepository(dataSource: dataSource, client: shareClient);
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

  group('findActive', () {
    test('returns Right with CoupleModel on success', () async {
      when(() => dataSource.findActive()).thenAnswer(
        (_) async => Right(
          CoupleResponse(
            id: 1,
            createdAt: '2026-01-12T14:30:00Z',
            partner: const UserResponse(
              id: 2,
              name: 'Marina',
              email: 'partner@trocado.app',
            ),
          ),
        ),
      );

      final data = await repository.findActive();

      expect(data.right.id, 1);
      expect(data.isRight, isTrue);
      expect(data.right.partner.id, 2);
      expect(data.right.partner.name, 'Marina');
      expect(data.right.partner.email, 'partner@trocado.app');
      expect(
        data.right.createdAt,
        DateTime.parse('2026-01-12T14:30:00Z').millisecondsSinceEpoch,
      );
    });

    test('returns Left NotFoundFailure on not_in_couple code', () async {
      when(() => dataSource.findActive()).thenAnswer(
        (_) async =>
            Left(_failure('not_in_couple', 'Você não está em um casal.')),
      );

      final data = await repository.findActive();

      expect(data.isLeft, isTrue);
      expect(data.left, isA<NotFoundFailure>());
    });

    test('returns Left NotFoundFailure on not_found code', () async {
      when(
        () => dataSource.findActive(),
      ).thenAnswer((_) async => Left(_failure('not_found', 'Not found.')));

      final data = await repository.findActive();

      expect(data.isLeft, isTrue);
      expect(data.left, isA<NotFoundFailure>());
    });

    test('returns Left NetworkFailure on network error', () async {
      when(() => dataSource.findActive()).thenAnswer(
        (_) async => Left(_failure('network_error', 'Network error')),
      );

      final data = await repository.findActive();

      expect(data.isLeft, isTrue);
      expect(data.left, isA<NetworkFailure>());
    });

    test('returns Left ServerFailure on server error', () async {
      when(() => dataSource.findActive()).thenAnswer(
        (_) async => Left(_failure('server_error', 'Internal server error')),
      );

      final data = await repository.findActive();

      expect(data.isLeft, isTrue);
      expect(data.left, isA<ServerFailure>());
    });

    test('returns Left ValidationFailure on unknown code', () async {
      when(() => dataSource.findActive()).thenAnswer(
        (_) async =>
            Left(_failure('weird_code', 'Algo aconteceu de inesperado.')),
      );

      final data = await repository.findActive();

      expect(data.isLeft, isTrue);
      expect(data.left, isA<ValidationFailure>());
      expect(data.left.message, 'Algo aconteceu de inesperado.');
    });
  });

  group('dissolve', () {
    test('returns Right when API responds 204', () async {
      when(() => dataSource.dissolve()).thenAnswer((_) async => Right(null));

      final data = await repository.dissolve();

      expect(data.isRight, isTrue);
    });

    test('returns Left NetworkFailure on network error', () async {
      when(() => dataSource.dissolve()).thenAnswer(
        (_) async => Left(_failure('network_error', 'Network error')),
      );

      final data = await repository.dissolve();

      expect(data.isLeft, isTrue);
      expect(data.left, isA<NetworkFailure>());
    });

    test('returns Left ServerFailure on server error', () async {
      when(() => dataSource.dissolve()).thenAnswer(
        (_) async => Left(_failure('server_error', 'Internal server error')),
      );

      final data = await repository.dissolve();

      expect(data.isLeft, isTrue);
      expect(data.left, isA<ServerFailure>());
    });

    test('returns Left NotFoundFailure when no active couple', () async {
      when(() => dataSource.dissolve()).thenAnswer(
        (_) async =>
            Left(_failure('not_in_couple', 'Você não está em um casal.')),
      );

      final data = await repository.dissolve();

      expect(data.isLeft, isTrue);
      expect(data.left, isA<NotFoundFailure>());
    });

    test('returns Left ValidationFailure on unknown code', () async {
      when(() => dataSource.dissolve()).thenAnswer(
        (_) async => Left(_failure('weird_code', 'Algo deu errado.')),
      );

      final data = await repository.dissolve();

      expect(data.isLeft, isTrue);
      expect(data.left, isA<ValidationFailure>());
      expect(data.left.message, 'Algo deu errado.');
    });
  });

  group('shareInvite', () {
    test('delegates formatted invite text to shareClient', () async {
      when(() => shareClient.shareText(any())).thenAnswer((_) async {});

      final data = await repository.shareInvite(
        qrData: 'trocado://invite/A3K7FN',
      );

      expect(data.isRight, isTrue);
      verify(
        () => shareClient.shareText(
          'Vamos juntar nossas finanças no Trocado! Aceite meu convite: trocado://invite/A3K7FN',
        ),
      ).called(1);
    });
  });
}
