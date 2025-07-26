import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../interface/chat_message.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../context.dart';

// --- TEMA UNGU MODERN ---
const Color themePrimaryColor = Color(0xFF5A2C9D); // Ungu utama
const Color themeLightPurple = Color(0xFFD1C4E9); // Ungu muda untuk highlight
const Color myBubbleColor = Color(0xFFEDE7F6);   // Warna bubble-ku (sangat muda)
const Color highlightColor = Color(0xFFDCD6E6);   // Warna saat di-sorot lebih gelap
const Color backgroundColor = Color(0xFFF9F8FC); // Warna latar belakang keunguan

class Chats extends StatefulWidget {
  const Chats({super.key});

  @override
  State<Chats> createState() => _ChatsState();
}

class _ChatsState extends State<Chats> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _emojiShowing = false;
  bool _isTyping = false;
  Map<String, String>? _replyMessage;

  final ItemScrollController _itemScrollController = ItemScrollController();
  String? _highlightedMessageId;
  Timer? _highlightTimer;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      if (_controller.text.isNotEmpty != _isTyping) {
        setState(() {
          _isTyping = _controller.text.isNotEmpty;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _highlightTimer?.cancel();
    super.dispose();
  }

  void _scrollToMessage(String messageId) {
    final chats = context.read<ContextService>().chats;
    final targetChatIndex = chats.indexWhere((chat) => chat.id == messageId);

    if (targetChatIndex != -1) {
      final scrollIndex = chats.length - 1 - targetChatIndex;
      _highlightTimer?.cancel();

      _itemScrollController.scrollTo(
        index: scrollIndex,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      ).then((_) {
        setState(() {
          _highlightedMessageId = messageId;
        });
        _highlightTimer = Timer(const Duration(seconds: 2), () {
          setState(() {
            _highlightedMessageId = null;
          });
        });
      });
    }
  }

  void _onEmojiIconPressed() {
    if (_emojiShowing) {
      _focusNode.requestFocus();
    } else {
      _focusNode.unfocus();
    }
    setState(() {
      _emojiShowing = !_emojiShowing;
    });
  }

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final contextService = context.read<ContextService>();
    contextService.addMessage(
      ChatMessage(
        deviceId: contextService.myDeviceId,
        messageText: text,
        createAt: DateTime.now(),
        id: "0",
        isMe: true,
        isSending: true,
        replyId: _replyMessage?['id'],
        replyText: _replyMessage?['text'],
      ),
    );

    final replyDataToSend = _replyMessage;
    _controller.clear();

    try {
      await dotenv.load(fileName: '.env');
      await http.post(
        Uri.parse("${dotenv.env['SOCKET_URL']}/message/send"),
        headers: {"Content-Type": "application/json; charset=UTF-8"},
        body: jsonEncode({
          "message": text,
          "device_id": contextService.myDeviceId,
          "reply_id": replyDataToSend?['id'] ?? "",
          "reply_text": replyDataToSend?['text'] ?? "",
        }),
      );
    } catch (e) {
      print("Error sending message: $e");
    }

    setState(() {
      _replyMessage = null;
      _emojiShowing = false;
    });

    _focusNode.requestFocus();
  }

  void _cancelReply() {
    setState(() {
      _replyMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final chats = context.watch<ContextService>().chats;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: themePrimaryColor,
        foregroundColor: Colors.white,
        elevation: 1.0,
        leading: const Padding(
          padding: EdgeInsets.fromLTRB(10, 2, 0, 2),
          child: CircleAvatar(
            backgroundImage: AssetImage('assets/profiles.jpeg'),
          ),
        ),
        title: const Text(
          "My Baby Cute 💜",
          style: TextStyle(fontSize: 18.5, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: () => Navigator.pushNamed(context, "/remotecam"),
            icon: const Icon(FontAwesomeIcons.video, size: 20),
          ),
          IconButton(
            onPressed: () => Navigator.pushNamed(context, "/remotecall"),
            icon: const Icon(FontAwesomeIcons.phone, size: 20),
          ),
          IconButton(
            onPressed: () => Navigator.pushNamed(context, "/services"),
            icon: const Icon(Icons.more_vert),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ScrollablePositionedList.builder(
              itemScrollController: _itemScrollController,
              reverse: true,
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              itemCount: chats.length,
              itemBuilder: (context, index) {
                final reversedIndex = chats.length - 1 - index;
                final chat = chats[reversedIndex];
                return ChatBubble(
                  chatId: chat.id,
                  message: chat.messageText,
                  isMe: chat.isMe,
                  isSending: chat.isSending,
                  time: "${chat.createAt.hour}:${chat.createAt.minute.toString().padLeft(2, '0')}",
                  replyId: chat.replyId,
                  replyText: chat.replyText,
                  replyOwner: chat.isMe ? "You" : "My Baby Cute 💜",
                  isHighlighted: _highlightedMessageId == chat.id,
                  onSwipe: () {
                    setState(() {
                      _replyMessage = {
                        'id': chat.id,
                        'text': chat.messageText,
                        'owner': chat.isMe ? "You" : "My Baby Cute 💜",
                      };
                    });
                    _focusNode.requestFocus();
                  },
                  onReplyTap: (messageId) {
                    _scrollToMessage(messageId);
                  },
                );
              },
            ),
          ),
          _buildInputArea(),
          _buildEmojiPicker(),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              offset: const Offset(0, -1),
              blurRadius: 5,
              color: Colors.black.withOpacity(0.05),
            )
          ]
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_replyMessage != null) _buildReplyPreview(),
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius: BorderRadius.circular(25.0),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            _emojiShowing ? Icons.keyboard : Icons.emoji_emotions_outlined,
                            color: Colors.grey.shade600,
                          ),
                          onPressed: _onEmojiIconPressed,
                        ),
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            focusNode: _focusNode,
                            onTap: () {
                              if (_emojiShowing) {
                                setState(() => _emojiShowing = false);
                              }
                            },
                            decoration: const InputDecoration(
                              hintText: 'Message',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(vertical: 10),
                            ),
                            minLines: 1,
                            maxLines: 5,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.camera_alt, color: Colors.grey.shade600),
                          onPressed: () {},
                        ),
                        const SizedBox(width: 8),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6.0),
                FloatingActionButton(
                  onPressed: _isTyping ? _sendMessage : null,
                  backgroundColor: _isTyping ? themePrimaryColor : Colors.grey.shade400,
                  elevation: 2.0,
                  shape: const CircleBorder(),
                  child: const Icon(
                    Icons.send,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReplyPreview() {
    return Container(
      margin: const EdgeInsets.fromLTRB(0, 0, 0, 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: myBubbleColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: const Border(left: BorderSide(color: themePrimaryColor, width: 4)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _replyMessage!['owner']!,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: themePrimaryColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _replyMessage!['text']!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey.shade800),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: _cancelReply,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          )
        ],
      ),
    );
  }

  Widget _buildEmojiPicker() {
    return Offstage(
      offstage: !_emojiShowing,
      child: SizedBox(
        height: 250,
        child: EmojiPicker(
          onEmojiSelected: (category, emoji) {
            _controller.text += emoji.emoji;
          },
          onBackspacePressed: () {
            _controller.text = _controller.text.characters.skipLast(1).toString();
          },
          config: Config(
            height: 256,
            checkPlatformCompatibility: true,
            emojiViewConfig: EmojiViewConfig(
              emojiSizeMax: 28 * (Platform.isIOS ? 1.30 : 1.0),
              backgroundColor: const Color(0xFFF2F2F2),
            ),
            categoryViewConfig: const CategoryViewConfig(
              backgroundColor: Color(0xFFF2F2F2),
              indicatorColor: themePrimaryColor,
              iconColorSelected: themePrimaryColor,
            ),
            bottomActionBarConfig: const BottomActionBarConfig(
              enabled: false,
            ),
          ),
        ),
      ),
    );
  }
}

class ChatBubble extends StatelessWidget {
  final String chatId;
  final String message;
  final String time;
  final bool isMe;
  final bool isSending;
  final String? replyId;
  final String? replyText;
  final String? replyOwner;
  final bool isHighlighted;
  final VoidCallback? onSwipe;
  final Function(String messageId)? onReplyTap;

  const ChatBubble({
    super.key,
    required this.chatId,
    required this.message,
    required this.time,
    required this.isMe,
    required this.isSending,
    this.replyId,
    this.replyText,
    this.replyOwner,
    this.isHighlighted = false,
    this.onSwipe,
    this.onReplyTap,
  });

  @override
  Widget build(BuildContext context) {
    final finalBubbleColor = isHighlighted ? highlightColor : (isMe ? myBubbleColor : Colors.white);
    final bool hasValidReply = replyId != null && replyId!.isNotEmpty && replyText != null && replyText!.isNotEmpty;

    // --- DI SINI PERBAIKANNYA: Menambahkan kembali Dismissible ---
    return Dismissible(
      key: UniqueKey(),
      direction: isMe ? DismissDirection.endToStart : DismissDirection.startToEnd,
      onDismissed: (_) => onSwipe?.call(),
      background: Container(
        color: themeLightPurple.withOpacity(0.5),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        alignment: isMe ? Alignment.centerLeft : Alignment.centerRight,
        child: const Icon(Icons.reply, color: themePrimaryColor),
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        color: isHighlighted ? themeLightPurple.withOpacity(0.4) : Colors.transparent,
        padding: const EdgeInsets.symmetric(vertical: 1.0, horizontal: 8.0),
        child: Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: finalBubbleColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 3,
                  offset: const Offset(1, 1),
                ),
              ],
            ),
            child: IntrinsicWidth(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (hasValidReply)
                    GestureDetector(
                        onTap: () {
                          if (onReplyTap != null) {
                            onReplyTap!(replyId!);
                          }
                        },
                        child: _buildReplyContent()
                    ),
                  Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(4, 0, 60, 15),
                        child: Text(
                          message,
                          style: const TextStyle(fontSize: 16, color: Color(0xFF333333)),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              time,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            if (isMe) const SizedBox(width: 4),
                            if (isMe) isSending
                                ? Icon(Icons.timer, size: 15, color: Colors.grey.shade500)
                                : Icon(Icons.done_all, size: 0, color: Colors.white.withAlpha(0)),
                          ],
                        ),
                      )
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReplyContent() {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: const Border(
          left: BorderSide(
            color: themePrimaryColor,
            width: 4,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            replyOwner ?? "",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: themePrimaryColor,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            replyText!,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}