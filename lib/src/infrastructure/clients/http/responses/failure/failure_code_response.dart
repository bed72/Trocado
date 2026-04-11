enum FailureCodeResponse {
  unknown('unknown'),
  notFound('not_found'),
  serverError('server_error'),
  networkError('network_error');

  const FailureCodeResponse(this.value);

  final String value;

  static FailureCodeResponse fromString(String code) => values.firstWhere(
    (failure) => failure.value == code,
    orElse: () => unknown,
  );
}
