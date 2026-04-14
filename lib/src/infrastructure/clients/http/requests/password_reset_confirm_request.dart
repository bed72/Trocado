final class PasswordResetConfirmRequest {
  final String uid;
  final String token;
  final String newPassword;

  const PasswordResetConfirmRequest({
    required this.uid,
    required this.token,
    required this.newPassword,
  });

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'token': token,
    'new_password': newPassword,
  };
}
