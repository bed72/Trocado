final class FcmTokenRequest {
  final String token;
  final String platform;

  const FcmTokenRequest({required this.token, required this.platform});

  Map<String, dynamic> toJson() => {'token': token, 'platform': platform};
}
