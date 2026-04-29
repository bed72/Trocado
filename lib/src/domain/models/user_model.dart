import 'package:equatable/equatable.dart';

final class UserModel extends Equatable {
  final int id;
  final String name;
  final String email;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
  });

  UserModel copyWith({int? id, String? name, String? email}) => UserModel(
    id: id ?? this.id,
    name: name ?? this.name,
    email: email ?? this.email,
  );

  @override
  List<Object?> get props => [id, name, email];
}
