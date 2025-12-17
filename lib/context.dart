import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'interface/chat_message.dart';

class ContextService extends ChangeNotifier {
  final List<ChatMessage> _chats = [];
  List<ChatMessage> get chats => _chats;

  String? _lastMessageCreatedAtString; // Changed name for clarity and to avoid confusion
  String? get lastMessageCreatedAt => _lastMessageCreatedAtString; // Public getter

  final String myDeviceId;
  static const String _storageKey = 'chat_messages';

  ContextService({required this.myDeviceId}) {
    _init();
  }

  Future<void> _init() async {
    await _loadMessagesFromStorage();

    if (_chats.isEmpty) {
      await fetchMessages();
    }
    // By removing the 'else' block, we simplify the startup logic.
    // We no longer proactively fetch new messages on every app start,
    // which should fix the "chats not loading" issue.
    // New messages will be fetched by other triggers like background services or after sending.
  }

  void _updateLastMessageTimestamp() {
    if (_chats.isNotEmpty) {
      _chats.sort((a, b) => b.createAt.compareTo(a.createAt)); // Ensure latest is first
      _lastMessageCreatedAtString = _chats.first.createAt.toIso8601String(); // Convert DateTime to String
    }
  }

  Future<void> _loadMessagesFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_storageKey);
    if (stored != null) {
      try {
        final decoded = jsonDecode(stored);

        if (decoded is! List) {
          print("DIAGNOSTIC: Cached data is not a List. Wiping cache.");
          _chats.clear();
          await prefs.remove(_storageKey);
          return;
        }

        _chats.clear();
        final List<ChatMessage> cachedMessages = [];
        for (final item in decoded) {
          try {
            if (item is Map<String, dynamic>) {
              cachedMessages.add(ChatMessage.fromJson(item, myDeviceId));
            }
          } catch (e) {
            print("DIAGNOSTIC: Failed to parse a cached chat message, skipping. Error: $e, Data: $item");
          }
        }
        
        _chats.addAll(cachedMessages);
        _updateLastMessageTimestamp();
        notifyListeners();
        print("DIAGNOSTIC: Successfully loaded ${_chats.length} messages from cache.");

      } catch (e) {
        print("DIAGNOSTIC: Failed to load messages from cache due to a major parsing error. Wiping cache. Error: $e");
        _chats.clear();
        await prefs.remove(_storageKey);
      }
    }
  }

  Future<void> _saveMessagesToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(_chats.map((e) => e.toJson()).toList());
    await prefs.setString(_storageKey, jsonString);
  }

  Future<void> addMessage(ChatMessage message) async {
    // This function might be for optimistic updates, but let's ensure no duplicates.
    if (_chats.any((c) => c.id == message.id)) return;
    _chats.insert(0, message); // Prepend to keep it sorted (newest first)
    _updateLastMessageTimestamp();
    await _saveMessagesToStorage();
    notifyListeners();
  }

  void markMessageAsSent(String optimisticId) {
    final index = _chats.indexWhere((chat) => chat.id == optimisticId && chat.isSending);
    if (index != -1) {
      _chats[index] = _chats[index].copyWith(isSending: false);
      _updateLastMessageTimestamp();
      _saveMessagesToStorage();
      notifyListeners();
      print("DIAGNOSTIC: Marked optimistic message $optimisticId as sent.");
    } else {
      print("DIAGNOSTIC: Optimistic message $optimisticId not found or already sent to mark as sent.");
    }
  }
  
  // This is the refactored, efficient message loading function with enhanced logging.
  Future<void> fetchMessages({String? after}) async {
    await dotenv.load(fileName: ".env");
    try {
      final String? socketUrl = dotenv.env['SOCKET_URL'];
      final String? authKey = dotenv.env['AUTH'];

      if (socketUrl == null || authKey == null) {
        print("DIAGNOSTIC: FATAL: SOCKET_URL or AUTH key is missing in .env file. Cannot fetch messages.");
        return;
      }

      var url = "$socketUrl/message?Auth=$authKey";
      if (after != null) {
        url += "&after=$after";
      }
      
      print("DIAGNOSTIC: Fetching messages from URL: $url");

      final res = await http.get(Uri.parse(url),
          headers: {"Content-Type": "application/json; charset=UTF-8"},
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as List;
        if (data.isEmpty) {
          // If we were fetching new messages after sending, we still need to remove the optimistic one.
          _chats.removeWhere((chat) => chat.isSending == true);
          notifyListeners();
          print("DIAGNOSTIC: API returned 200 OK with an empty list. Cleaned up optimistic messages.");
          return;
        }

        print("DIAGNOSTIC: Received ${data.length} message(s) from API. Starting parse.");
        final List<ChatMessage> newMessages = [];
        for (final item in data) {
          try {
            if (item is Map<String, dynamic>) {
              newMessages.add(ChatMessage.fromJson(item, myDeviceId));
            }
          } catch (e) {
            print("DIAGNOSTIC: Failed to parse a chat message, skipping. Error: $e, Data: $item");
          }
        }

        if (newMessages.isEmpty) {
          print("DIAGNOSTIC: All messages in the received batch failed to parse.");
          return;
        }

        if (after == null) {
          _chats.clear();
          _chats.addAll(newMessages);
        } else {
          _chats.insertAll(0, newMessages.where((nm) => !_chats.any((em) => em.id == nm.id)));
          // Remove all optimistic messages now that we have updates from the server.
          _chats.removeWhere((chat) => chat.isSending == true);
        }
        
        _updateLastMessageTimestamp();
        await _saveMessagesToStorage();
        notifyListeners();
        print("DIAGNOSTIC: Successfully fetched and processed ${newMessages.length} messages.");

      } else {
        print("DIAGNOSTIC: API request failed with status code: ${res.statusCode}. Response: ${res.body}");
      }
    } catch (e) {
        print("DIAGNOSTIC: Failed to fetch messages from API due to an exception: $e");
    }
  }

  Future<void> loadFromAPI() async {
    // This function is now deprecated and replaced by fetchMessages.
    // For backward compatibility, it will perform a full initial load.
    await fetchMessages();
  }


  void clearAll() async {
    _chats.clear();
    _lastMessageCreatedAtString = null; // Corrected variable name
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    notifyListeners();
  }
}
