import 'package:equatable/equatable.dart';

final class UserModel extends Equatable {
  final int id;
  final String name;
  final String email;
  final String? avatar;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.avatar,
  });

  UserModel copyWith({
    int? id,
    String? email,
    String? name,
    String? avatar,
    bool clearAvatar = false,
  }) => UserModel(
    id: id ?? this.id,
    name: name ?? this.name,
    email: email ?? this.email,
    avatar: clearAvatar ? null : avatar ?? this.avatar,
  );

  @override
  List<Object?> get props => [id, email, name, avatar];
}
