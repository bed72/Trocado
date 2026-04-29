final class UserResponse {
  final int id;
  final String name;
  final String email;

  const UserResponse({
    required this.id,
    required this.name,
    required this.email,
  });

  factory UserResponse.fromJson(Map<String, dynamic> json) => UserResponse(
    id: json['id'] as int,
    name: json['name'] as String,
    email: json['email'] as String,
  );
}
