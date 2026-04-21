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
    String? name,
    String? email,
    String? avatar,
    bool clearAvatar = false,
  }) => UserModel(
    id: id ?? this.id,
    name: name ?? this.name,
    email: email ?? this.email,
    avatar: clearAvatar ? null : avatar ?? this.avatar,
  );

  @override
  List<Object?> get props => [id, name, email, avatar];
}
