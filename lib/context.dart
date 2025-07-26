import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'interface/chat_message.dart';

class ContextService extends ChangeNotifier {
  final List<ChatMessage> _chats = [];
  List<ChatMessage> get chats => _chats;

  final String myDeviceId;
  static const String _storageKey = 'chat_messages';

  ContextService({required this.myDeviceId}) {
    _init();
  }

  Future<void> _init() async {
    await _loadMessagesFromStorage();

    if (_chats.isEmpty) {
      await loadFromAPI();
    }
  }

  Future<void> _loadMessagesFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_storageKey);
    if (stored != null) {
      final decoded = jsonDecode(stored) as List;
      _chats.clear();
      _chats.addAll(decoded.map((e) => ChatMessage.fromJson(e, myDeviceId)));
      notifyListeners();
    }
  }

  Future<void> _saveMessagesToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(_chats.map((e) => e.toJson()).toList());
    await prefs.setString(_storageKey, jsonString);
  }

  Future<void> addMessage(ChatMessage message) async {
    _chats.add(message);
    await _saveMessagesToStorage();
    notifyListeners();
  }

  Future<void> loadFromAPI() async {
    await dotenv.load(fileName: ".env");
    try {
      final res = await http.post(Uri.parse("${dotenv.env['SOCKET_URL']}/message"));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as List;
        _chats.clear();
        _chats.addAll(data.map((e) => ChatMessage.fromJson(e, myDeviceId)));
        await _saveMessagesToStorage();
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) {
        print("Failed to fetch messages from API: $e");
      }
    }
  }

  void clearAll() async {
    _chats.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    notifyListeners();
  }
}
