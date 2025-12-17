import 'package:flutter_dotenv/flutter_dotenv.dart';

class ChatMessage {
  final String id;
  final String deviceId;
  final String messageText;
  final String? messageMedia;
  final DateTime createAt;
  final bool isMe;
  final bool isSending;
  final String? replyId;
  final String? replyText;
  final bool reading;

  ChatMessage({
    required this.id,
    required this.deviceId,
    required this.messageText,
    this.messageMedia,
    required this.reading,
    required this.createAt,
    required this.isMe,
    this.isSending = false,
    this.replyId,
    this.replyText,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json, String myDeviceId) {
    dotenv.load(fileName: '.env');
    return ChatMessage(
      id: json['id'] as String,
      messageText: json['content'] as String? ?? '',
      messageMedia: json['content_image'] as String?,
      reading: json['reading'] == 1,
      deviceId: json['receiver_id'] as String,
      createAt: DateTime.parse(json['created_at']),
      isMe: json['receiver_id'] == myDeviceId,
      replyId: json['reply_to'] as String?,
      replyText: json['reply_text'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'device_id': deviceId,
      'message_text': messageText,
      'message_media': messageMedia,
      'reading' : reading,
      'reply_id': replyId,
      'reply_text': replyText,
      'createAt': createAt.toIso8601String(),
    };
  }
}