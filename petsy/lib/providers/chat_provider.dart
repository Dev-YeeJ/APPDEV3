import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:petsy/features/home/data/models/chat_model.dart';
import 'package:petsy/features/home/data/models/message_model.dart';
import 'package:petsy/features/home/data/repositories/chat_repository.dart';

class ChatProvider extends ChangeNotifier {
  final ChatRepository _chatRepository = ChatRepository();

  final List<Chat> _chats = [];
  final List<Message> _messages = [];
  int _unreadCount = 0;
  String? _currentOrderId;

  List<Chat> get chats => _chats;
  List<Message> get messages => _messages;
  int get unreadCount => _unreadCount;
  String? get currentOrderId => _currentOrderId;

  // 🚀 Get current user's chats stream
  Stream<List<Chat>> getCustomerChatsStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value([]);
    return _chatRepository.getCustomerChats(user.uid);
  }

  // 🚀 Get all chats stream (for admin)
  Stream<List<Chat>> getAllChatsStream() {
    return _chatRepository.getAllChats();
  }

  // 🚀 Get messages stream for specific order
  Stream<List<Message>> getMessagesStream(String orderId) {
    _currentOrderId = orderId;
    return _chatRepository.getMessages(orderId);
  }

  // 🚀 Send a message
  Future<void> sendMessage({
    required String orderId,
    required String text,
    required String orderSummary,
    required bool isAdmin,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Send the message
      await _chatRepository.sendMessage(
        orderId: orderId,
        senderId: user.uid,
        text: text,
      );

      // Update chat metadata
      final messagePrefix = isAdmin ? 'Admin: ' : '';
      await _chatRepository.updateChatMetadata(
        orderId: orderId,
        lastMessage: messagePrefix + text,
        orderSummary: orderSummary,
        customerId: isAdmin ? '' : user.uid,
        hasUnreadAdmin:
            !isAdmin, // Mark as unread for admin if customer sent it
      );

      notifyListeners();
    } catch (e) {
      print('Error sending message: $e');
    }
  }

  // 🚀 Mark chat as read (for admin)
  Future<void> markChatAsRead(String orderId) async {
    try {
      await _chatRepository.markChatAsRead(orderId);
      notifyListeners();
    } catch (e) {
      print('Error marking chat as read: $e');
    }
  }

  // 🚀 Update unread count
  Future<void> updateUnreadCount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      _unreadCount = await _chatRepository.getUnreadChatCount(user.uid);
      notifyListeners();
    } catch (e) {
      print('Error updating unread count: $e');
    }
  }

  // 🚀 Initialize a chat for an order
  Future<void> initializeChat({
    required String orderId,
    required String orderSummary,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await _chatRepository.initializeChat(
        orderId: orderId,
        customerId: user.uid,
        orderSummary: orderSummary,
      );
      notifyListeners();
    } catch (e) {
      print('Error initializing chat: $e');
    }
  }

  // 🚀 Check if chat exists
  Future<bool> chatExists(String orderId) async {
    try {
      return await _chatRepository.chatExists(orderId);
    } catch (e) {
      print('Error checking chat existence: $e');
      return false;
    }
  }

  // 🚀 Get unread admin count
  Future<int> getAdminUnreadCount() async {
    try {
      return await _chatRepository.getAdminUnreadChatCount();
    } catch (e) {
      print('Error getting admin unread count: $e');
      return 0;
    }
  }
}
