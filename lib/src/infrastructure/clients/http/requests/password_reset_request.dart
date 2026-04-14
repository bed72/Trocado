final class PasswordResetRequest {
  final String email;

  const PasswordResetRequest({required this.email});

  Map<String, dynamic> toJson() => {'email': email};
}
