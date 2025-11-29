import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/modules/core/data/dtos/user_dto.dart';
import 'package:trocado/modules/core/data/mapper/user_mapper.dart';

void main() {
  final mapper = UserMapper();

  group('UserMapper', () {
    test('toModel should convert UserDto into UserModel correctly', () {
      final dto = UserDto(id: '1', name: 'Gabriel', image: 'image.webp');

      final data = mapper.toModel(dto);

      expect(data.name, equals('Gabriel'));
      expect(data.image, equals('image.webp'));
    });

    test('toJson should convert UserDto into Map correctly', () {
      final dto = UserDto(id: '1', name: 'Gabriel', image: 'image.webp');

      final data = mapper.toJson(dto);

      expect(data['id'], equals('1'));
      expect(data['name'], equals('Gabriel'));
      expect(data['image'], equals('image.webp'));
    });

    test('fromJson should return Right(UserDto) for valid JSON', () {
      final json = {'id': '1', 'name': 'Gabriel', 'image': 'image.webp'};

      final data = mapper.fromJson(json);

      expect(data.isRight, isTrue);
      expect(data.right, isA<UserDto>());
      expect(data.right.name, equals('Gabriel'));
    });
  });
}
