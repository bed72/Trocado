import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/modules/user/data/dtos/user_dto.dart';
import 'package:trocado/modules/user/data/mappers/user_mapper.dart';

void main() {
  final mapper = UserMapper();

  group('UserMapper', () {
    test('toModel should convert UserDto into UserModel correctly', () {
      final dto = UserDto(
        id: '1',
        name: 'Gabriel',
        password: '123456',
        email: 'gabriel@example.com',
      );

      final data = mapper.toModel(dto);

      expect(data.name, equals('Gabriel'));
      expect(data.password, equals('123456'));
      expect(data.email, equals('gabriel@example.com'));
    });

    test('toJson should convert UserDto into Map correctly', () {
      final dto = UserDto(
        id: '1',
        name: 'Gabriel',
        password: '123456',
        email: 'gabriel@example.com',
      );

      final data = mapper.toJson(dto);

      expect(data['id'], equals('1'));
      expect(data['name'], equals('Gabriel'));
      expect(data['password'], equals('123456'));
      expect(data['email'], equals('gabriel@example.com'));
    });

    test('fromJson should return Right(UserDto) for valid JSON', () {
      final json = {
        'id': '1',
        'name': 'Gabriel',
        'password': '123456',
        'email': 'gabriel@example.com',
      };

      final data = mapper.fromJson(json);

      expect(data.isRight, isTrue);
      expect(data.right, isA<UserDto>());
      expect(data.right.name, equals('Gabriel'));
    });

    test('fromJsons should return Right(List<UserDto>) for a valid list', () {
      final jsons = [
        {
          'id': '1',
          'name': 'Gabriel',
          'password': '123456',
          'email': 'gabriel@example.com',
        },
        {
          'id': '2',
          'name': 'Kelly',
          'password': 'abcdef',
          'email': 'kelly@example.com',
        },
      ];

      final data = mapper.fromJsons(jsons);

      expect(data.isRight, isTrue);
      expect(data.right, hasLength(2));
      expect(data.right.first.name, equals('Gabriel'));
    });

    test('fromJsons should return Right(Dto) when any item is invalid', () {
      final jsons = [
        {
          'id': '1',
          'name': 'Gabriel',
          'password': '123456',
          'email': 'gabriel@example.com',
        },
        {'id': '2', 'name': 'A', 'email': 'wrong', 'password': '123'},
      ];

      final data = mapper.fromJsons(jsons);

      expect(data.isRight, isTrue);
      expect(data.right.length, 2);
    });
  });
}
