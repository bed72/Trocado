final class UserResponse {
  final int id;
  final String name;
  final String email;
  final String? avatar;

  const UserResponse({
    required this.id,
    required this.name,
    required this.email,
    this.avatar,
  });

  factory UserResponse.fromJson(Map<String, dynamic> json) => UserResponse(
    id: json['id'] as int,
    name: json['name'] as String,
    email: json['email'] as String,
    avatar: json['avatar'] as String?,
  );
}
