import 'dart:io';

class UserDto {
  final int? id;
  final String? name;
  final String? image;

  UserDto({this.id, this.name, this.image});

  factory UserDto.empty({String? name, File? image}) =>
      UserDto(name: 'Troqueiro', image: null);

  UserDto copyWith({int? id, String? name, String? image}) =>
      UserDto(id: id, name: name ?? this.name, image: image ?? this.image);
}
