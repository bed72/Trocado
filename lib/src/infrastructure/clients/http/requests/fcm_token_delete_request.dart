final class FcmTokenDeleteRequest {
  final String token;

  const FcmTokenDeleteRequest({required this.token});

  Map<String, dynamic> toJson() => {'token': token};
}
