final class NotificationResponse {
  final int id;
  final String type;
  final String title;
  final String createdAt;
  final String description;
  final String? link;

  const NotificationResponse({
    required this.id,
    required this.type,
    required this.title,
    required this.createdAt,
    required this.description,
    this.link,
  });

  factory NotificationResponse.fromJson(Map<String, dynamic> json) =>
      NotificationResponse(
        id: json['id'] as int,
        type: json['type'] as String,
        link: json['link'] as String?,
        title: json['title'] as String,
        createdAt: json['created_at'] as String,
        description: json['description'] as String,
      );
}
