import 'dart:io';

class UserDto {
  final String? id;
  final String? name;
  final String? image;

  UserDto({required this.name, required this.image, this.id});

  factory UserDto.build({String? name, File? image}) {
    String dafaultName = 'Troqueiro';

    if (name != null) dafaultName = name;

    return UserDto(name: dafaultName, image: image?.path);
  }

  UserDto copyWith({String? id, String? name, String? image}) =>
      UserDto(id: id, name: name ?? this.name, image: image ?? this.image);
}
