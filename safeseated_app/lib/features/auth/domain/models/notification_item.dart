class NotificationItem {
  final String id;
  final String toEmail;
  final String title;
  final String body;
  final String time;
  final bool isRead;

  const NotificationItem({
    required this.id,
    required this.toEmail,
    required this.title,
    required this.body,
    required this.time,
    this.isRead = false,
  });

  NotificationItem copyWith({
    String? id,
    String? toEmail,
    String? title,
    String? body,
    String? time,
    bool? isRead,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      toEmail: toEmail ?? this.toEmail,
      title: title ?? this.title,
      body: body ?? this.body,
      time: time ?? this.time,
      isRead: isRead ?? this.isRead,
    );
  }
}
