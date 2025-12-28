final class UserModel {
  final int? id;
  final String? name;
  final String? image;

  UserModel({required this.id, required this.name, required this.image});

  UserModel copyWith({int? id, String? name, String? image}) => UserModel(
    id: id ?? this.id,
    name: name ?? this.name,
    image: image ?? this.image,
  );

  @override
  String toString() => 'UserModel(id: $id, name: $name, image: $image)';

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ image.hashCode;

  @override
  bool operator ==(covariant UserModel other) {
    if (identical(this, other)) return true;

    return other.id == id && other.name == name && other.image == image;
  }
}
