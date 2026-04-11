enum Endpoints {
  signIn('/api/v1/token'),
  signUp('/api/v1/auth/register'),
  verifyToken('/api/v1/token/verify'),
  refreshToken('/api/v1/token/refresh'),
  passwordResetConfirm('/api/v1/auth/password/reset'),
  passwordResetRequest('/api/v1/auth/password/request');

  const Endpoints(this.path);

  final String path;
}
