import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:petsy/features/home/data/models/chat_model.dart';
import 'package:petsy/features/home/data/models/message_model.dart';

class ChatRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 🚀 Get all chats for a customer
  Stream<List<Chat>> getCustomerChats(String customerId) {
    return _firestore
        .collection('chats')
        .where('customerId', isEqualTo: customerId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Chat.fromFirestore(doc)).toList(),
        );
  }

  // 🚀 Get all chats for admin (support view)
  Stream<List<Chat>> getAllChats() {
    return _firestore
        .collection('chats')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Chat.fromFirestore(doc)).toList(),
        );
  }

  // 🚀 Get messages for a specific order
  Stream<List<Message>> getMessages(String orderId) {
    return _firestore
        .collection('chats')
        .doc(orderId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Message.fromFirestore(doc)).toList(),
        );
  }

  // 🚀 Send a message
  Future<void> sendMessage({
    required String orderId,
    required String senderId,
    required String text,
  }) async {
    await _firestore
        .collection('chats')
        .doc(orderId)
        .collection('messages')
        .add({
          'senderId': senderId,
          'text': text,
          'timestamp': FieldValue.serverTimestamp(),
        });
  }

  // 🚀 Update chat metadata
  Future<void> updateChatMetadata({
    required String orderId,
    required String lastMessage,
    required String orderSummary,
    required String customerId,
    required bool hasUnreadAdmin,
  }) async {
    await _firestore.collection('chats').doc(orderId).set({
      'orderId': orderId,
      'customerId': customerId,
      'orderSummary': orderSummary,
      'lastMessage': lastMessage,
      'timestamp': FieldValue.serverTimestamp(),
      'hasUnreadAdmin': hasUnreadAdmin,
    }, SetOptions(merge: true));
  }

  // 🚀 Mark chat as read by admin
  Future<void> markChatAsRead(String orderId) async {
    await _firestore.collection('chats').doc(orderId).update({
      'hasUnreadAdmin': false,
    });
  }

  // 🚀 Get unread chat count for customer
  Future<int> getUnreadChatCount(String customerId) async {
    final snapshot = await _firestore
        .collection('chats')
        .where('customerId', isEqualTo: customerId)
        .where('lastMessage', isNotEqualTo: '')
        .snapshots()
        .first;

    int unreadCount = 0;
    for (var doc in snapshot.docs) {
      final data = doc.data();
      final lastMessage = data['lastMessage'] ?? '';
      if (lastMessage.startsWith('Admin:')) {
        unreadCount++;
      }
    }
    return unreadCount;
  }

  // 🚀 Get unread chat count for admin
  Future<int> getAdminUnreadChatCount() async {
    final snapshot = await _firestore
        .collection('chats')
        .where('hasUnreadAdmin', isEqualTo: true)
        .snapshots()
        .first;

    return snapshot.docs.length;
  }

  // 🚀 Check if a chat exists for an order
  Future<bool> chatExists(String orderId) async {
    final doc = await _firestore.collection('chats').doc(orderId).get();
    return doc.exists;
  }

  // 🚀 Create or initialize a chat for an order
  Future<void> initializeChat({
    required String orderId,
    required String customerId,
    required String orderSummary,
  }) async {
    await _firestore.collection('chats').doc(orderId).set({
      'orderId': orderId,
      'customerId': customerId,
      'orderSummary': orderSummary,
      'lastMessage': '',
      'timestamp': FieldValue.serverTimestamp(),
      'hasUnreadAdmin': false,
    }, SetOptions(merge: true));
  }
}
