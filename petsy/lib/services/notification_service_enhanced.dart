import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:petsy/utils/chat_constants.dart';
import 'package:flutter/material.dart';

// 🚀 BACKGROUND MESSAGE HANDLER - MUST BE TOP-LEVEL
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('🔔 Background message handled: ${message.notification?.title}');
  // Show notification even when app is closed
  await _showBackgroundNotification(message);
}

// 🚀 Show notification in background
Future<void> _showBackgroundNotification(RemoteMessage message) async {
  final plugin = FlutterLocalNotificationsPlugin();
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    importance: Importance.high,
    enableVibration: true,
    playSound: true,
  );

  await plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(channel);

  await plugin.show(
    message.hashCode,
    message.notification?.title ?? 'Petsy',
    message.notification?.body ?? '',
    NotificationDetails(
      android: AndroidNotificationDetails(
        channel.id,
        channel.name,
        importance: Importance.high,
        priority: Priority.high,
      ),
    ),
  );
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  static BuildContext? _appContext;

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // 🚀 Set app context for overlay notifications
  static void setAppContext(BuildContext context) {
    _appContext = context;
  }

  // --- INITIALIZATION ---
  Future<void> initialize() async {
    // 🚀 REGISTER BACKGROUND MESSAGE HANDLER
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 🚀 REQUEST NOTIFICATION PERMISSIONS
    await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    // 🚀 SETUP LOCAL NOTIFICATIONS
    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _handleNotificationTap,
    );

    // 🚀 CREATE NOTIFICATION CHANNELS
    await _createNotificationChannels();

    // 🚀 LISTEN TO INCOMING FCM MESSAGES
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // 🚀 GET AND SAVE FCM TOKEN
    String? token = await _firebaseMessaging.getToken();
    if (token != null) {
      print('');
      print('════════════════════════════════════════════════════');
      print('🚀🚀🚀 FCM TOKEN 🚀🚀🚀');
      print('════════════════════════════════════════════════════');
      print(token);
      print('════════════════════════════════════════════════════');
      print('');
      await _saveFcmToken(token);
    }

    // Listen for token refresh
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      print('');
      print('🔄 NEW FCM TOKEN RECEIVED:');
      print(newToken);
      print('');
      _saveFcmToken(newToken);
    });
  }

  // 🚀 CREATE NOTIFICATION CHANNELS
  Future<void> _createNotificationChannels() async {
    final List<AndroidNotificationChannel> channels = [
      AndroidNotificationChannel(
        ChatConstants.chatChannelId,
        ChatConstants.channelNames[ChatConstants.chatChannelId]!,
        description:
            ChatConstants.channelDescriptions[ChatConstants.chatChannelId],
        importance: Importance.high,
        enableVibration: true,
        playSound: true,
      ),
      AndroidNotificationChannel(
        ChatConstants.orderChannelId,
        ChatConstants.channelNames[ChatConstants.orderChannelId]!,
        description:
            ChatConstants.channelDescriptions[ChatConstants.orderChannelId],
        importance: Importance.high,
        enableVibration: true,
        playSound: true,
      ),
      AndroidNotificationChannel(
        ChatConstants.adminChannelId,
        ChatConstants.channelNames[ChatConstants.adminChannelId]!,
        description:
            ChatConstants.channelDescriptions[ChatConstants.adminChannelId],
        importance: Importance.high,
        enableVibration: true,
        playSound: true,
      ),
      // 🚀 NEW CHANNELS FOR TRANSACTIONS
      const AndroidNotificationChannel(
        'transaction_channel',
        'Transaction Notifications',
        description: 'Payment and transaction updates',
        importance: Importance.high,
        enableVibration: true,
        playSound: true,
      ),
      const AndroidNotificationChannel(
        'system_channel',
        'System Notifications',
        description: 'Important system updates',
        importance: Importance.high,
        enableVibration: true,
        playSound: true,
      ),
    ];

    for (final channel in channels) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(channel);
    }
  }

  // 🚀 SAVE FCM TOKEN TO FIRESTORE
  Future<void> _saveFcmToken(String token) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
              'fcmToken': token,
              'fcmTokenUpdated': FieldValue.serverTimestamp(),
            });
      }
    } catch (e) {
      print('Error saving FCM token: $e');
    }
  }

  // 🚀 HANDLE FOREGROUND MESSAGE
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('🔔 Foreground message: ${message.notification?.title}');

    await _showLocalNotification(
      title: message.notification?.title ?? 'Petsy Notification',
      body: message.notification?.body ?? '',
      payload: message.data.toString(),
      channelId: message.data['channelId'] ?? ChatConstants.orderChannelId,
    );
  }

  // 🚀 HANDLE MESSAGE WHEN APP IS OPENED FROM NOTIFICATION
  void _handleMessageOpenedApp(RemoteMessage message) {
    print('🔔 Message opened app: ${message.notification?.title}');
    _navigateToAppropriateScreen(message.data);
  }

  // 🚀 HANDLE LOCAL NOTIFICATION TAP
  void _handleNotificationTap(NotificationResponse notificationResponse) async {
    print('🔔 Notification tapped: ${notificationResponse.payload}');
  }

  // 🚀 SHOW LOCAL NOTIFICATION
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    required String payload,
    required String channelId,
  }) async {
    try {
      await _localNotifications.show(
        DateTime.now().millisecond,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            ChatConstants.channelNames[channelId] ??
                ChatConstants.channelNames[ChatConstants.orderChannelId]!,
            importance: Importance.high,
            priority: Priority.high,
            showWhen: true,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: payload,
      );
    } catch (e) {
      print('Error showing local notification: $e');
    }
  }

  // 🚀 NAVIGATE TO APPROPRIATE SCREEN
  void _navigateToAppropriateScreen(Map<String, dynamic> data) {
    final notificationType = data['type'] ?? '';
    print('Navigate to: $notificationType');
  }

  // ==================== PUBLIC NOTIFICATION METHODS ====================

  // 🚀 CHAT: SEND MESSAGE NOTIFICATION
  Future<void> sendChatNotification({
    required String recipientId,
    required String senderName,
    required String messagePreview,
    required String orderId,
  }) async {
    try {
      // Save to Firestore
      await FirebaseFirestore.instance.collection('notifications').add({
        'recipientId': recipientId,
        'type': 'chat_message',
        'title': '💬 New Message from $senderName',
        'body': messagePreview,
        'senderName': senderName,
        'orderId': orderId,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
        'action': 'open_chat',
      });

      // Show local notification
      await _showLocalNotification(
        title: '💬 New Message from $senderName',
        body: messagePreview,
        payload: 'chat:$orderId',
        channelId: ChatConstants.chatChannelId,
      );

      // Show overlay if in app
      _showOverlayNotification(
        title: 'New Message',
        message: '$senderName: $messagePreview',
        type: 'chat',
      );
    } catch (e) {
      print('Error sending chat notification: $e');
    }
  }

  // 🚀 ORDER: STATUS CHANGED
  Future<void> sendOrderStatusNotification({
    required String customerId,
    required String orderId,
    required String orderStatus,
    required double totalAmount,
  }) async {
    try {
      String title = '📦 Order Updated';
      String body = 'Order #${orderId.substring(0, 8)} status: $orderStatus';
      String emoji = '📦';

      if (orderStatus == 'pending') {
        title = '⏳ Order Pending';
        body = 'Your order #${orderId.substring(0, 8)} is being processed.';
        emoji = '⏳';
      } else if (orderStatus == 'toShip') {
        title = '📮 Order Shipped!';
        body = 'Your order #${orderId.substring(0, 8)} is on its way! 📮';
        emoji = '📮';
      } else if (orderStatus == 'toReceive') {
        title = '🚚 Out for Delivery';
        body = 'Your order #${orderId.substring(0, 8)} is out for delivery! 🚚';
        emoji = '🚚';
      } else if (orderStatus == 'completed') {
        title = '✅ Order Delivered';
        body = 'Your order #${orderId.substring(0, 8)} has been delivered! ✅';
        emoji = '✅';
      } else if (orderStatus == 'cancelled') {
        title = '❌ Order Cancelled';
        body = 'Your order #${orderId.substring(0, 8)} has been cancelled. ❌';
        emoji = '❌';
      }

      // Save to Firestore
      await FirebaseFirestore.instance.collection('notifications').add({
        'recipientId': customerId,
        'type': 'order_status',
        'title': title,
        'body': body,
        'orderId': orderId,
        'orderStatus': orderStatus,
        'totalAmount': totalAmount,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
        'action': 'open_order',
      });

      // Show notifications
      await _showLocalNotification(
        title: title,
        body: body,
        payload: 'order:$orderId',
        channelId: ChatConstants.orderChannelId,
      );

      _showOverlayNotification(title: title, message: body, type: 'order');
    } catch (e) {
      print('Error sending order notification: $e');
    }
  }

  // 🚀 PAYMENT: TRANSACTION COMPLETED
  Future<void> sendPaymentNotification({
    required String userId,
    required String transactionId,
    required double amount,
    required String paymentMethod,
    bool isSuccess = true,
  }) async {
    try {
      final title = isSuccess ? '✅ Payment Successful' : '❌ Payment Failed';
      final body = isSuccess
          ? 'Payment of ₱${amount.toStringAsFixed(2)} via $paymentMethod'
          : 'Payment failed. Please try again.';

      // Save to Firestore
      await FirebaseFirestore.instance.collection('notifications').add({
        'recipientId': userId,
        'type': 'payment',
        'title': title,
        'body': body,
        'transactionId': transactionId,
        'amount': amount,
        'paymentMethod': paymentMethod,
        'isSuccess': isSuccess,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });

      // Show notifications
      await _showLocalNotification(
        title: title,
        body: body,
        payload: 'payment:$transactionId',
        channelId: 'transaction_channel',
      );

      _showOverlayNotification(
        title: title,
        message: body,
        type: isSuccess ? 'success' : 'error',
      );
    } catch (e) {
      print('Error sending payment notification: $e');
    }
  }

  // 🚀 ADMIN: NEW ORDER RECEIVED
  Future<void> sendAdminNewOrderNotification({
    required String adminId,
    required String orderId,
    required String customerName,
    required double totalAmount,
    required int itemCount,
  }) async {
    try {
      final title = '🛍️ New Order Received';
      final body =
          '$customerName ordered $itemCount item(s) - ₱${totalAmount.toStringAsFixed(2)}';

      // Save to Firestore
      await FirebaseFirestore.instance.collection('notifications').add({
        'adminId': adminId,
        'type': 'admin_new_order',
        'title': title,
        'body': body,
        'orderId': orderId,
        'customerName': customerName,
        'totalAmount': totalAmount,
        'itemCount': itemCount,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
        'action': 'open_admin_orders',
      });

      // Show notifications
      await _showLocalNotification(
        title: title,
        body: body,
        payload: 'admin_order:$orderId',
        channelId: ChatConstants.adminChannelId,
      );

      _showOverlayNotification(title: title, message: body, type: 'order');
    } catch (e) {
      print('Error sending admin order notification: $e');
    }
  }

  // 🚀 ADMIN: NEW CUSTOMER MESSAGE
  Future<void> sendAdminChatNotification({
    required String adminId,
    required String customerName,
    required String messagePreview,
    required String orderId,
  }) async {
    try {
      final title = '💬 New Customer Message';
      final body = '$customerName: $messagePreview';

      // Save to Firestore
      await FirebaseFirestore.instance.collection('notifications').add({
        'adminId': adminId,
        'type': 'admin_chat_message',
        'title': title,
        'body': body,
        'customerName': customerName,
        'orderId': orderId,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
        'action': 'open_admin_chat',
      });

      // Show notifications
      await _showLocalNotification(
        title: title,
        body: body,
        payload: 'admin_chat:$orderId',
        channelId: ChatConstants.adminChannelId,
      );

      _showOverlayNotification(title: title, message: body, type: 'chat');
    } catch (e) {
      print('Error sending admin chat notification: $e');
    }
  }

  // 🚀 ADMIN: LOW STOCK ALERT
  Future<void> sendLowStockNotification({
    required String adminId,
    required String productName,
    required int currentStock,
    required int threshold,
  }) async {
    try {
      final title = '⚠️ Low Stock Alert';
      final body = '$productName has only $currentStock items left!';

      // Save to Firestore
      await FirebaseFirestore.instance.collection('notifications').add({
        'adminId': adminId,
        'type': 'low_stock',
        'title': title,
        'body': body,
        'productName': productName,
        'currentStock': currentStock,
        'threshold': threshold,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });

      // Show notifications
      await _showLocalNotification(
        title: title,
        body: body,
        payload: 'admin_stock:$productName',
        channelId: 'system_channel',
      );

      _showOverlayNotification(title: title, message: body, type: 'warning');
    } catch (e) {
      print('Error sending stock notification: $e');
    }
  }

  // 🚀 GENERAL: CUSTOM NOTIFICATION
  Future<void> sendCustomNotification({
    required String userId,
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? customData,
  }) async {
    try {
      // Save to Firestore
      final data = {
        'recipientId': userId,
        'type': type,
        'title': title,
        'body': body,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
        ...?customData,
      };

      await FirebaseFirestore.instance.collection('notifications').add(data);

      // Show notifications
      await _showLocalNotification(
        title: title,
        body: body,
        payload: '$type:$userId',
        channelId: 'system_channel',
      );

      _showOverlayNotification(title: title, message: body, type: type);
    } catch (e) {
      print('Error sending custom notification: $e');
    }
  }

  // 🚀 SHOW OVERLAY NOTIFICATION (IN-APP)
  void _showOverlayNotification({
    required String title,
    required String message,
    required String type,
  }) {
    if (_appContext == null) return;

    // Import NotificationOverlay from the widget file
    // This will be called from the overlay widget we created
  }

  // 🚀 GET UNREAD NOTIFICATIONS COUNT
  Future<int> getUnreadCount(String userId) async {
    try {
      final query = await FirebaseFirestore.instance
          .collection('notifications')
          .where('recipientId', isEqualTo: userId)
          .where('read', isEqualTo: false)
          .count()
          .get();
      return query.count ?? 0;
    } catch (e) {
      print('Error getting unread count: $e');
      return 0;
    }
  }

  // 🚀 GET NOTIFICATIONS STREAM
  Stream<List<Map<String, dynamic>>> getNotificationsStream(String userId) {
    return FirebaseFirestore.instance
        .collection('notifications')
        .where('recipientId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => {...doc.data(), 'id': doc.id})
              .toList(),
        );
  }

  // 🚀 MARK NOTIFICATION AS READ
  Future<void> markAsRead(String notificationId) async {
    try {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(notificationId)
          .update({'read': true});
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  // 🚀 DELETE NOTIFICATION
  Future<void> deleteNotification(String notificationId) async {
    try {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(notificationId)
          .delete();
    } catch (e) {
      print('Error deleting notification: $e');
    }
  }

  // 🚀 CLEAR ALL NOTIFICATIONS FOR USER
  Future<void> clearAllNotifications(String userId) async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      final snapshot = await FirebaseFirestore.instance
          .collection('notifications')
          .where('recipientId', isEqualTo: userId)
          .get();

      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      print('Error clearing notifications: $e');
    }
  }
}
