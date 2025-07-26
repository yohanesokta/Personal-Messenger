class ChatMessage {
  final String id;
  final String deviceId;
  final String messageText;
  final String? messageMedia; // <-- WAJIB ADA
  final DateTime createAt;
  final bool isMe;
  final bool isSending;
  final String? replyId;
  final String? replyText;

  ChatMessage({
    required this.id,
    required this.deviceId,
    required this.messageText,
    this.messageMedia, // <-- WAJIB ADA
    required this.createAt,
    required this.isMe,
    this.isSending = false,
    this.replyId,
    this.replyText,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json, String myDeviceId) {
    return ChatMessage(
      id: json['id'] as String,
      messageText: json['message_text'] as String? ?? '',
      messageMedia: json['message_media'] as String?, // <-- WAJIB ADA
      deviceId: json['device_id'] as String,
      createAt: DateTime.parse(json['createAt']),
      isMe: json['device_id'] == myDeviceId,
      replyId: json['reply_id'] as String?,
      replyText: json['reply_text'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'device_id': deviceId,
      'message_text': messageText,
      'message_media': messageMedia, // <-- WAJIB ADA
      'reply_id': replyId,
      'reply_text': replyText,
      'createAt': createAt.toIso8601String(),
    };
  }
}