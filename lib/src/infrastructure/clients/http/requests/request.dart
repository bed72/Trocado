final class Request {
  final String path;
  final Map<String, dynamic>? body;
  final Map<String, dynamic>? query;
  final Map<String, dynamic>? headers;

  const Request(this.path, {this.body, this.query, this.headers});

  Request copyWith({
    String? path,
    Map<String, dynamic>? body,
    Map<String, dynamic>? query,
    Map<String, dynamic>? headers,
  }) => Request(
    path ?? this.path,
    body: body ?? this.body,
    query: query ?? this.query,
    headers: headers ?? this.headers,
  );
}
