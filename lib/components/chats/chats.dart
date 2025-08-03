import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../../utils/image_preview_screen.dart';
import '../../utils/image_viewer_screen.dart';
import '../../interface/chat_message.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../context.dart';
import 'media.dart';

const Color themePrimaryColor = Color(0xFF5A2C9D);
const Color themeLightPurple = Color(0xFFD1C4E9);
const Color myBubbleColor = Color(0xFFEDE7F6);
const Color highlightColor = Color(0xFFDCD6E6);
const Color backgroundColor = Color(0xFFF9F8FC);

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

  Future<void> _handleImageSelection() async {
    if (!mounted) return;
    final XFile? image = await Navigator.of(context).push<XFile?>(
      MaterialPageRoute(builder: (context) => const MediaPickerScreen()),
    );
    if (image == null) return;

    final replyDataForPreview = _replyMessage;
    setState(() {
      _replyMessage = null;
    });

    if (!mounted) return;
    final String? captionFromPreview = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ImagePreviewScreen(imagePath: image.path),
      ),
    );

    if (captionFromPreview == null) return;

    final String finalCaption = captionFromPreview.trim().isEmpty ? "♥︎" : captionFromPreview;

    context.read<ContextService>().addMessage(
      ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        deviceId: context.read<ContextService>().myDeviceId,
        messageText: finalCaption,
        messageMedia: image.path,
        createAt: DateTime.now(),
        reading: true,
        isMe: true,
        isSending: true,
        replyId: replyDataForPreview?['id'],
        replyText: replyDataForPreview?['text'],
      ),
    );

    _uploadAndSendMessage(
        localPath: image.path,
        caption: finalCaption,
        replyData: replyDataForPreview
    );
  }

  Future<void> _uploadAndSendMessage({
    required String localPath,
    required String caption,
    Map<String, String>? replyData
  }) async {
    try {
      final uploadUrl = Uri.parse('https://webrtc.yohanes.dpdns.org/message/upload');
      var request = http.MultipartRequest('PUT', uploadUrl)
        ..files.add(await http.MultipartFile.fromPath('image', localPath));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final responseData = jsonDecode(response.body);
        final publicUrl = responseData['public_url'];

        await _sendMessageToServer(
            text: caption,
            mediaUrl: publicUrl,
            replyData: replyData
        );
      } else {
        print("Upload failed: ${response.body}");
      }
    } catch (e) {
      print("Error during image upload and send: $e");
    }
  }

  void _sendTextMessage() {
    final text = _controller.text.trim();
    if(text.isEmpty) return;

    context.read<ContextService>().addMessage(
      ChatMessage(
        deviceId: context.read<ContextService>().myDeviceId,
        messageText: text,
        createAt: DateTime.now(),
        id: "0",
        isMe: true,
        reading: false,
        isSending: true,
        replyId: _replyMessage?['id'],
        replyText: _replyMessage?['text'],
      ),
    );
    _sendMessageToServer(text: text, replyData: _replyMessage );
    _controller.clear();
    setState(() {
      _replyMessage = null;
    });
  }

  Future<void> _sendMessageToServer({
    String? text,
    String? mediaUrl,
    Map<String, String>? replyData,
  }) async {

    final textToSend = text?.trim() ?? '';
    if (textToSend.isEmpty && (mediaUrl == null || mediaUrl.isEmpty)) return;
    try {
      await dotenv.load(fileName: '.env');
      await http.post(
        Uri.parse("${dotenv.env['SOCKET_URL']}/message/send?auth=${dotenv.env['AUTH']}"),
        headers: {"Content-Type": "application/json; charset=UTF-8"},
        body: jsonEncode({
          "message": textToSend,
          "message_media": mediaUrl ?? "",
          "device_id": context.read<ContextService>().myDeviceId,
          "reply_id": replyData?['id'] ?? "",
          "reply_text": replyData?['text'] ?? "",
        }),
      );
      await context.read<ContextService>().loadFromAPI();
    } catch (e) {
      print("Error sending message to server: $e");
    }
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
                  messageMedia: chat.messageMedia,
                  isMe: chat.isMe,
                  isSending: chat.isSending,
                  reading: chat.reading,
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
                          onPressed: _handleImageSelection,
                        ),
                        const SizedBox(width: 8),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6.0),
                FloatingActionButton(
                  onPressed: _isTyping ? _sendTextMessage : null,
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
  final String? messageMedia;
  final String time;
  final bool isMe;
  final bool isSending;
  final String? replyId;
  final String? replyText;
  final String? replyOwner;
  final bool isHighlighted;
  final VoidCallback? onSwipe;
  final bool reading;
  final Function(String messageId)? onReplyTap;

  const ChatBubble({
    super.key,
    required this.chatId,
    required this.message,
    this.messageMedia,
    required this.time,
    required this.isMe,
    required this.reading,
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
            decoration: BoxDecoration(
              color: finalBubbleColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 5,
                  offset: const Offset(1, 1),
                ),
              ],
            ),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 4, 4, 20),
                  child: _buildMainContent(context, hasValidReply),
                ),
                Positioned(
                  bottom: 4,
                  right: 8,
                  child: _buildTimestamp(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent(BuildContext context, bool hasValidReply) {
    final bool hasMedia = messageMedia != null && messageMedia!.isNotEmpty;
    final bool hasText = message.isNotEmpty && message != "♥︎";

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasValidReply) _buildReplyContent(),
        if (hasMedia) _buildMediaContent(context, hasText),
        if (hasText) _buildTextContent(),
      ],
    );
  }

  Widget _buildReplyContent() {
    return GestureDetector(
      onTap: () => onReplyTap?.call(replyId!),
      child: Container(
        margin: const EdgeInsets.fromLTRB(6, 4, 6, 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.05),
          borderRadius: const BorderRadius.all(Radius.circular(8)),
          border: const Border(left: BorderSide(color: themePrimaryColor, width: 4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(replyOwner ?? "", style: const TextStyle(fontWeight: FontWeight.bold, color: themePrimaryColor, fontSize: 13)),
            const SizedBox(height: 2),
            Text(replyText!, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, color: Colors.black54)),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaContent(BuildContext context, bool hasTextBelow) {
    final bool isLocalFile = !(messageMedia?.startsWith('http') ?? false);
    final double bottomRadius = hasTextBelow ? 0.0 : 12.0;
    final authKey = dotenv.env['AUTH'];
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ImageViewerScreen(
              imageUrl: messageMedia!,
              isLocalFile: isLocalFile,
            ),
          ),
        );
      },
      child: Hero(
        tag: messageMedia!,
        child: ClipRRect(
          borderRadius: BorderRadius.vertical(top: const Radius.circular(12.0), bottom: Radius.circular(bottomRadius)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 300),
            child: isLocalFile
                ? Image.file(File(messageMedia!), fit: BoxFit.cover)
                : Image.network("${messageMedia!}?auth=$authKey",
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) => progress == null ? child : Container(height: 250, color: myBubbleColor, child: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: themePrimaryColor))),
              errorBuilder: (context, error, stack) => Container(height: 250, color: Colors.grey.shade200, child: const Center(child: Icon(Icons.broken_image, color: Colors.grey))),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextContent() {
    final bool hasMediaAbove = messageMedia != null && messageMedia!.isNotEmpty;

    return Padding(
      padding: EdgeInsets.fromLTRB(10, hasMediaAbove ? 8 : 4, 10, 4),
      child: Text(
        message,
        style: const TextStyle(fontSize: 16, color: Color(0xFF333333), height: 1.4),
      ),
    );
  }

  Widget _buildTimestamp() {
    final bool hasText = message.isNotEmpty && message != "♥︎";
    final bool hasMedia = messageMedia != null && messageMedia!.isNotEmpty;
    final bool isTextWhite = hasMedia && !hasText;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          time,
          style: TextStyle(
            fontSize: 11,
            color: isTextWhite ? Colors.white : Colors.grey.shade600,
            shadows: isTextWhite ? [const Shadow(color: Colors.black54, blurRadius: 4)] : [],
          ),
        ),
        if (isMe) ...[
          const SizedBox(width: 4),
          Icon(
            isSending ? Icons.timer_outlined :  Icons.done_all,
            size: 15,
            color: reading ?  Colors.blue : isSending
                ? (isTextWhite ? Colors.white70 : Colors.grey.shade600)
                : (isTextWhite ? Colors.white : Colors.grey),
            shadows: isTextWhite ? [const Shadow(color: Colors.black54, blurRadius: 4)] : [],
          ),
        ]
      ],
    );
  }
}