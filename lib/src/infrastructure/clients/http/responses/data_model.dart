final class DataModel<T> {
  final T data;
  final Map<String, dynamic>? meta;
  final Map<String, dynamic>? links;

  const DataModel({required this.data, this.meta, this.links});

  factory DataModel.fromJson(
    Map<String, dynamic> json,
    T Function(Object? data) parser,
  ) => DataModel(
    data: parser(json['data']),
    meta: _mapFrom(json['meta']),
    links: _mapFrom(json['links']),
  );
}

Map<String, dynamic>? _mapFrom(Object? value) =>
    value is Map ? Map<String, dynamic>.from(value) : null;
