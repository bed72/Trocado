import 'package:equatable/equatable.dart';

class PageModel<T> extends Equatable {
  final List<T> items;
  final String? nextCursor;
  final String? previousCursor;

  const PageModel({
    this.nextCursor,
    this.previousCursor,
    this.items = const [],
  });

  PageModel<T> copyWith({
    List<T>? items,
    String? nextCursor,
    String? previousCursor,
  }) => PageModel<T>(
    items: items ?? this.items,
    nextCursor: nextCursor ?? this.nextCursor,
    previousCursor: previousCursor ?? this.previousCursor,
  );

  @override
  List<Object?> get props => [items, nextCursor, previousCursor];
}
