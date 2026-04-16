enum EndpointKey {
  me('/api/v1/me'),
  signIn('/api/v1/token'),
  signUp('/api/v1/auth/register'),
  budgets('/api/v1/budgets'),
  verifyToken('/api/v1/token/verify'),
  refreshToken('/api/v1/token/refresh'),
  passwordResetConfirm('/api/v1/auth/password/reset'),
  passwordResetRequest('/api/v1/auth/password/request');

  const EndpointKey(this.path);

  final String path;

  bool get isPublic => _publicEndpoints.contains(this);

  static bool isPublicPath(String path) =>
      _publicEndpoints.any((key) => path.contains(key.path));

  static const _publicEndpoints = {
    signIn,
    signUp,
    refreshToken,
    passwordResetRequest,
    passwordResetConfirm,
  };
}
