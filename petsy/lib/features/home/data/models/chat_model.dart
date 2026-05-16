import 'package:cloud_firestore/cloud_firestore.dart';

class Chat {
  final String orderId;
  final String customerId;
  final String orderSummary;
  final String lastMessage;
  final DateTime timestamp;
  final bool hasUnreadAdmin;

  Chat({
    required this.orderId,
    required this.customerId,
    required this.orderSummary,
    required this.lastMessage,
    required this.timestamp,
    required this.hasUnreadAdmin,
  });

  factory Chat.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Chat(
      orderId: data['orderId'] ?? doc.id,
      customerId: data['customerId'] ?? '',
      orderSummary: data['orderSummary'] ?? 'Items',
      lastMessage: data['lastMessage'] ?? '',
      timestamp: data['timestamp'] != null
          ? (data['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
      hasUnreadAdmin: data['hasUnreadAdmin'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'orderId': orderId,
      'customerId': customerId,
      'orderSummary': orderSummary,
      'lastMessage': lastMessage,
      'timestamp': FieldValue.serverTimestamp(),
      'hasUnreadAdmin': hasUnreadAdmin,
    };
  }
}
