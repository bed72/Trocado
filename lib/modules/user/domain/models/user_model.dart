final class UserModel {
  final String? id;
  final String name;
  final String email;
  final String password;

  UserModel({
    this.id,
    required this.name,
    required this.email,
    required this.password,
  });

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? password,
  }) => UserModel(
    id: id ?? this.id,
    name: name ?? this.name,
    email: email ?? this.email,
    password: password ?? this.password,
  );

  @override
  String toString() =>
      'UserModel(id: $id, name: $name, email: $email, password: $password)';

  @override
  int get hashCode =>
      id.hashCode ^ name.hashCode ^ email.hashCode ^ password.hashCode;

  @override
  bool operator ==(covariant UserModel other) {
    if (identical(this, other)) return true;

    return other.id == id &&
        other.name == name &&
        other.email == email &&
        other.password == password;
  }
}
