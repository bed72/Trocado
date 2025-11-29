class UserDto {
  final String? id;
  final String? name;
  final String? image;

  UserDto({required this.name, required this.image, this.id});

  UserDto copyWith({String? id, String? name, String? image}) =>
      UserDto(id: id, name: name ?? this.name, image: image ?? this.image);
}
