import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../interface/chat_message.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io';
import 'package:http/http.dart' as http;

import '../context.dart';

class Chats extends StatefulWidget {
  const Chats({super.key});

  @override
  State<Chats> createState() => _ChatsState();
}

class _ChatsState extends State<Chats> {


  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _emojiShowing = false;



  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _toggleEmojiPicker() {
    if (!_emojiShowing) {
      FocusScope.of(context).unfocus();
    }
    setState(() {
      _emojiShowing = !_emojiShowing;
    });
  }

  void  _sendMessage() async {
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
          isSending: true
      ),
    ); // Gunakan ContextService
    _controller.clear();
    await dotenv.load(fileName: '.env');
    final res = await http.post(Uri.parse("${dotenv.env['SOCKET_URL']}/message/send"),
        headers: <String, String> {
          "Content-Type" : "application/json; charset=UTF-8"
        },
        body: jsonEncode(<String, String> {
          "message" : text,
          "device_id" : contextService.myDeviceId
        })
    );
    setState(() => _emojiShowing = false);
  }

  @override
  Widget build(BuildContext context) {
    final chats = context.watch<ContextService>().chats;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 232, 239, 246),
        elevation: 1,
        leading: const Padding(
          padding: EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundImage: AssetImage('assets/profiles.jpeg'),
          ),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "My Baby Cute 💜",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            // Text("online", style: TextStyle(fontSize: 13, color: Colors.green)),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.pushNamed(context, "/remotecam");
            },
            icon: const Icon(FontAwesomeIcons.video, color: Color.fromARGB(
                255, 25, 30, 89),size: 16,),
          ),

          IconButton(
            onPressed: () {
              Navigator.pushNamed(context, "/remotecall");
            },
            icon: const Icon(FontAwesomeIcons.phone, color: Color.fromARGB(255, 25, 30, 89),size: 16,),
          ),

          IconButton(
            onPressed: () {
              Navigator.pushNamed(context, "/services");
            },
            icon: const Icon(Icons.more_vert, color: Color.fromARGB(255, 25, 30, 89)),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: true,
              padding: const EdgeInsets.only(top: 10),
              itemCount: chats.length,
              itemBuilder: (context, index) {
                final reversedIndex = chats.length - 1 - index;
                final chat = chats[reversedIndex];
                return ChatBubble(
                  message: chat.messageText,
                  isMe: chat.isMe,
                  isSending: chat.isSending,
                  time:
                  "${chat.createAt.hour}:${chat.createAt.minute.toString().padLeft(2, '0')}",
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, -1),
            blurRadius: 4,
            color: Colors.black.withOpacity(0.05),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: Icon(
                _emojiShowing ? Icons.keyboard : Icons.emoji_emotions_outlined,
                color: Colors.grey.shade600,
              ),
              onPressed: _toggleEmojiPicker,
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
                decoration: InputDecoration(
                  hintText: 'Message',
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: Theme.of(context).primaryColor,
              borderRadius: BorderRadius.circular(30),
              child: InkWell(
                borderRadius: BorderRadius.circular(30),
                onTap: _sendMessage,
                child: const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Icon(Icons.send, color: Colors.white, size: 22),
                ),
              ),
            ),
          ],
        ),
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
            _controller
              ..text += emoji.emoji
              ..selection = TextSelection.fromPosition(
                TextPosition(offset: _controller.text.length),
              );
          },
          onBackspacePressed: () {
            _controller
              ..text = _controller.text.characters.skipLast(1).toString()
              ..selection = TextSelection.fromPosition(
                TextPosition(offset: _controller.text.length),
              );
          },
          config: Config(
            height: 256,
            checkPlatformCompatibility: true,
            emojiViewConfig: EmojiViewConfig(
              backgroundColor: const Color(0xFFF2F6FC),
              columns: 8,
              emojiSizeMax: 28 * (Platform.isIOS ? 1.30 : 1.0),
              recentsLimit: 28,
            ),
            categoryViewConfig: CategoryViewConfig(
              indicatorColor: Colors.teal,
              iconColor: Colors.grey,
              iconColorSelected: Colors.teal,
              backgroundColor: const Color(0xFFF2F6FC),
              recentTabBehavior: RecentTabBehavior.RECENT,
              initCategory: Category.RECENT,
            ),
            skinToneConfig: const SkinToneConfig(
              enabled: true,
              dialogBackgroundColor: Colors.white,
              indicatorColor: Colors.grey,
            ),
            bottomActionBarConfig: const BottomActionBarConfig(
              enabled: true,
              buttonColor: Color.fromARGB(0, 255, 255, 255),
              backgroundColor: Colors.white,
              buttonIconColor: Colors.grey,
            ),
          ),
        ),
      ),
    );
  }
}

class ChatBubble extends StatelessWidget {
  final String message;
  final String time;
  final bool isMe;
  final bool isSending;

  const ChatBubble({
    super.key,
    required this.message,
    required this.time,
    required this.isMe,
    required this.isSending
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: isSending ? const Color.fromARGB(180, 99, 135, 255) : isMe ? const Color.fromARGB(255, 99, 135, 255) : const Color.fromARGB(255, 81, 150, 255),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft:
            isMe ? const Radius.circular(16) : const Radius.circular(0),
            bottomRight:
            isMe ? const Radius.circular(0) : const Radius.circular(16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              style: const TextStyle(fontSize: 15, color: Color.fromARGB(221, 255, 255, 255)),
            ),
            const SizedBox(height: 4),
            (isSending) ? Icon(FontAwesomeIcons.clock,size: 10,weight: 800,color: Colors.white,) : Text(
              time,
              style: TextStyle(
                fontSize: 11,
                color: const Color.fromARGB(255, 255, 255, 255).withOpacity(0.5),
              ),
            )
          ],
        ),
      ),
    );
  }
}
