final class UserDto {
  final String? id;
  final String name;
  final String email;
  final String password;

  UserDto({
    this.id,
    required this.name,
    required this.email,
    required this.password,
  });

  UserDto copyWith({
    String? id,
    String? name,
    String? email,
    String? password,
  }) => UserDto(
    id: id ?? this.id,
    name: name ?? this.name,
    email: email ?? this.email,
    password: password ?? this.password,
  );
}
