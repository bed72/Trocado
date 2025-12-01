import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/modules/core/core.dart';

import 'package:trocado/modules/core/data/dtos/user_dto.dart';
import 'package:trocado/modules/core/data/mapper/user_mapper.dart';

import '../../../../mocks/mocks.dart';

void main() {
  late UserMapper mapper;
  late IUserRepository repository;
  late IDatabaseDatasource datasource;

  setUp(() {
    mapper = UserMapper();
    datasource = MockDatabaseDatasource();
    repository = UserRepository(mapper: mapper, datasource: datasource);
  });

  group('LocalUserRepository', () {
    final table = DatabaseConstant.userTableName;
    final dto = UserDto(id: '1', name: 'Gabriel', image: 'image.webp');

    group('all', () {
      test('should return first user on success', () async {
        when(
          () => datasource.all(table.name, any()),
        ).thenAnswer((_) async => Right([mapper.toJson(dto)]));

        final response = await repository.find(data: dto);

        expect(response.isRight, isTrue);
        expect(response.right.id, equals('1'));
        expect(response.right.name, equals('Gabriel'));
        verify(() => datasource.all(table.name, any())).called(1);
      });

      test('should return error message on failure', () async {
        when(
          () => datasource.all(table.name, any()),
        ).thenAnswer((_) async => Left(null));

        final result = await repository.find(data: dto);

        expect(result.isLeft, isTrue);
        expect(
          result.left,
          'Opss, não encontramos seus dados, tente mais tarde!',
        );
        verify(() => datasource.all(table.name, any())).called(1);
      });
    });

    group('insert', () {
      test('should call upsert with correct parameters', () async {
        when(
          () => datasource.upsert(table.name, any()),
        ).thenAnswer((_) async {});

        await repository.insert(data: dto);

        verify(
          () => datasource.upsert(table.name, mapper.toJson(dto)),
        ).called(1);
      });
    });

    group('update', () {
      test('should call upsert with correct parameters', () async {
        when(
          () => datasource.upsert(table.name, any()),
        ).thenAnswer((_) async {});

        await repository.update(data: dto);

        verify(
          () => datasource.upsert(table.name, mapper.toJson(dto)),
        ).called(1);
      });
    });

    group('delete', () {
      test('should call delete database', () async {
        when(
          () => datasource.delete(table.name, any()),
        ).thenAnswer((_) async {});

        await repository.delete(data: dto);

        verify(() => datasource.delete(table.name, any())).called(1);
      });
    });
  });
}
