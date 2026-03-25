class AppNotification {
  final String id;
  final String title;
  final String body;
  final int receivedAt;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.receivedAt,
  });

  factory AppNotification.fromMap(String id, Map<dynamic, dynamic> map) {
    return AppNotification(
      id: id,
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      receivedAt: map['receivedAt'] ?? DateTime.now().millisecondsSinceEpoch,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'body': body,
      'receivedAt': receivedAt,
    };
  }
}