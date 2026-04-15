final class MeResponse {
  final int id;
  final String name;
  final String email;
  final String? avatar;

  const MeResponse({
    required this.id,
    required this.name,
    required this.email,
    this.avatar,
  });

  factory MeResponse.fromJson(Map<String, dynamic> json) => MeResponse(
    id: json['id'] as int,
    name: json['name'] as String,
    email: json['email'] as String,
    avatar: json['avatar'] as String?,
  );
}
