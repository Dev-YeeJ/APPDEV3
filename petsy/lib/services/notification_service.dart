import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:petsy/utils/chat_constants.dart';

// 🚀 BACKGROUND MESSAGE HANDLER - MUST BE TOP-LEVEL
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Background message: ${message.notification?.title}');
  // You can also trigger a local notification here if needed
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // --- INITIALIZATION ---
  Future<void> initialize() async {
    // 🚀 REGISTER BACKGROUND MESSAGE HANDLER (CRITICAL!)
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

    // 🚀 CREATE NOTIFICATION CHANNELS (Android)
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

  // 🚀 CREATE ANDROID NOTIFICATION CHANNELS
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
            .update({'fcmToken': token});
      }
    } catch (e) {
      print('Error saving FCM token: $e');
    }
  }

  // 🚀 HANDLE FOREGROUND MESSAGE
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('Foreground message: ${message.notification?.title}');

    await _showLocalNotification(
      title: message.notification?.title ?? 'Petsy Notification',
      body: message.notification?.body ?? '',
      payload: message.data.toString(),
      channelId: message.data['channelId'] ?? ChatConstants.orderChannelId,
    );
  }

  // 🚀 HANDLE MESSAGE WHEN APP IS OPENED FROM NOTIFICATION
  void _handleMessageOpenedApp(RemoteMessage message) {
    print('Message opened app: ${message.notification?.title}');
    // Handle notification tap - route to appropriate screen
    _navigateToAppropriateScreen(message.data);
  }

  // 🚀 HANDLE LOCAL NOTIFICATION TAP
  void _handleNotificationTap(NotificationResponse notificationResponse) async {
    print('Notification tapped: ${notificationResponse.payload}');
    // Handle local notification tap
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
    // This will be handled by the app's main navigation logic
    print('Navigate to: $notificationType');
  }

  // ========== PUBLIC METHODS FOR SENDING NOTIFICATIONS ==========

  // 🚀 NOTIFY CUSTOMER: NEW CHAT MESSAGE FROM ADMIN
  Future<void> sendChatNotification({
    required String customerId,
    required String senderName,
    required String messagePreview,
  }) async {
    try {
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': customerId,
        'type': ChatConstants.chatMessageType,
        'title':
            ChatConstants.notificationTitles[ChatConstants.chatMessageType],
        'body': messagePreview,
        'senderName': senderName,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });

      // Show local notification immediately
      await _showLocalNotification(
        title: ChatConstants.notificationTitles[ChatConstants.chatMessageType]!,
        body: messagePreview,
        payload: ChatConstants.chatMessageType,
        channelId: ChatConstants.chatChannelId,
      );
    } catch (e) {
      print('Error sending chat notification: $e');
    }
  }

  // 🚀 NOTIFY CUSTOMER: ORDER STATUS CHANGED
  Future<void> sendOrderStatusNotification({
    required String customerId,
    required String orderId,
    required String orderStatus,
  }) async {
    try {
      String notificationType = ChatConstants.orderStatusType;
      String title =
          ChatConstants.notificationTitles[ChatConstants.orderStatusType]!;
      String body = 'Order #${orderId.substring(0, 8)} status: $orderStatus';

      if (orderStatus == 'toShip') {
        notificationType = ChatConstants.orderShippedType;
        title =
            ChatConstants.notificationTitles[ChatConstants.orderShippedType]!;
        body = 'Your order #${orderId.substring(0, 8)} is on its way! 📮';
      } else if (orderStatus == 'toReceive') {
        body = 'Your order #${orderId.substring(0, 8)} is out for delivery! 🚚';
      } else if (orderStatus == 'completed') {
        notificationType = ChatConstants.orderDeliveredType;
        title =
            ChatConstants.notificationTitles[ChatConstants.orderDeliveredType]!;
        body = 'Your order #${orderId.substring(0, 8)} has been delivered! ✅';
      } else if (orderStatus == 'cancelled') {
        notificationType = ChatConstants.orderCancelledType;
        title =
            ChatConstants.notificationTitles[ChatConstants.orderCancelledType]!;
        body = 'Your order #${orderId.substring(0, 8)} has been cancelled. ❌';
      }

      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': customerId,
        'type': notificationType,
        'title': title,
        'body': body,
        'orderId': orderId,
        'orderStatus': orderStatus,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });

      await _showLocalNotification(
        title: title,
        body: body,
        payload: notificationType,
        channelId: ChatConstants.orderChannelId,
      );
    } catch (e) {
      print('Error sending order notification: $e');
    }
  }

  // 🚀 NOTIFY ADMIN: NEW CUSTOMER MESSAGE
  Future<void> sendAdminChatNotification({
    required String adminId,
    required String customerName,
    required String messagePreview,
    required String orderId,
  }) async {
    try {
      await FirebaseFirestore.instance.collection('notifications').add({
        'adminId': adminId,
        'type': ChatConstants.newCustomerMessageType,
        'title': ChatConstants
            .adminNotificationTitles[ChatConstants.newCustomerMessageType],
        'body': '$customerName: $messagePreview',
        'customerName': customerName,
        'orderId': orderId,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });

      await _showLocalNotification(
        title: ChatConstants
            .adminNotificationTitles[ChatConstants.newCustomerMessageType]!,
        body: '$customerName: $messagePreview',
        payload: ChatConstants.newCustomerMessageType,
        channelId: ChatConstants.adminChannelId,
      );
    } catch (e) {
      print('Error sending admin chat notification: $e');
    }
  }

  // 🚀 NOTIFY ADMIN: NEW ORDER RECEIVED
  Future<void> sendAdminNewOrderNotification({
    required String adminId,
    required String orderId,
    required double totalAmount,
    required int itemCount,
  }) async {
    try {
      await FirebaseFirestore.instance.collection('notifications').add({
        'adminId': adminId,
        'type': ChatConstants.newOrderType,
        'title':
            ChatConstants.adminNotificationTitles[ChatConstants.newOrderType],
        'body':
            'Order #${orderId.substring(0, 8)} - $itemCount items - ₱$totalAmount',
        'orderId': orderId,
        'totalAmount': totalAmount,
        'itemCount': itemCount,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });

      await _showLocalNotification(
        title:
            ChatConstants.adminNotificationTitles[ChatConstants.newOrderType]!,
        body:
            'Order #${orderId.substring(0, 8)} - $itemCount items - ₱${totalAmount.toStringAsFixed(2)}',
        payload: ChatConstants.newOrderType,
        channelId: ChatConstants.adminChannelId,
      );
    } catch (e) {
      print('Error sending new order notification: $e');
    }
  }

  // 🚀 NOTIFY ADMIN: LOW STOCK ALERT
  Future<void> sendLowStockNotification({
    required String adminId,
    required String productName,
    required int stockLevel,
  }) async {
    try {
      await FirebaseFirestore.instance.collection('notifications').add({
        'adminId': adminId,
        'type': ChatConstants.lowStockType,
        'title':
            ChatConstants.adminNotificationTitles[ChatConstants.lowStockType],
        'body': '$productName stock is low: only $stockLevel items left',
        'productName': productName,
        'stockLevel': stockLevel,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });

      await _showLocalNotification(
        title:
            ChatConstants.adminNotificationTitles[ChatConstants.lowStockType]!,
        body: '$productName stock is low: only $stockLevel items left',
        payload: ChatConstants.lowStockType,
        channelId: ChatConstants.adminChannelId,
      );
    } catch (e) {
      print('Error sending low stock notification: $e');
    }
  }

  // 🚀 GET ALL UNREAD NOTIFICATIONS FOR USER
  Stream<QuerySnapshot> getUnreadNotifications(String userId) {
    return FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('read', isEqualTo: false)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // 🚀 MARK NOTIFICATION AS READ
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(notificationId)
          .update({'read': true});
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }
}
