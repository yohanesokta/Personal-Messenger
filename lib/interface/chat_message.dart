class ChatMessage {
  final String id;
  final String deviceId;
  final String messageText;
  final DateTime createAt;
  final bool isMe;
  final bool isSending;

  ChatMessage({
    required this.id,
    required this.deviceId,
    required this.messageText,
    required this.createAt,
    required this.isMe,
    this.isSending = false
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json, String myDeviceId) {
    return ChatMessage(
      id: json['id'],
      deviceId: json['device_id'],
      messageText: json['message_text'],
      createAt: DateTime.parse(json['createAt']),
      isMe: json['device_id'] == myDeviceId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'device_id': deviceId,
      'message_text': messageText,
      'createAt': createAt.toIso8601String(),
    };
  }
}
