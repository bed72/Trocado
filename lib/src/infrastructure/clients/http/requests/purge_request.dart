final class PurgeRequest {
  final String email;
  final String password;

  const PurgeRequest({required this.email, required this.password});

  Map<String, dynamic> toJson() => {'email': email, 'password': password};
}
