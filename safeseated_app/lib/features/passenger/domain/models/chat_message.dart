class ChatMessage {
  final int bookingId;
  final String fromEmail;
  final String text;
  final String time;

  const ChatMessage({
    required this.bookingId,
    required this.fromEmail,
    required this.text,
    required this.time,
  });
}
