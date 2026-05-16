import 'package:flutter/material.dart';

class ChatConstants {
  // --- COLORS ---
  static const Color petsyGreen = Color(0xFF2B8C61);
  static const Color petsyNavy = Color(0xFF003466);
  static const Color petsyBgColor = Color(0xFFF4F6F8);

  // --- CHAT NOTIFICATION TYPES ---
  static const String chatMessageType = 'chat_message';
  static const String orderStatusType = 'order_status';
  static const String orderShippedType = 'order_shipped';
  static const String orderDeliveredType = 'order_delivered';
  static const String orderCancelledType = 'order_cancelled';
  static const String orderReadyType = 'order_ready';

  // --- NOTIFICATION TITLES & MESSAGES ---
  static const Map<String, String> notificationTitles = {
    chatMessageType: '💬 New Message from Admin',
    orderStatusType: '📦 Order Status Updated',
    orderShippedType: '📮 Your Order Has Been Shipped',
    orderDeliveredType: '✅ Your Order Has Been Delivered',
    orderCancelledType: '❌ Order Cancelled',
    orderReadyType: '🎉 Your Order is Ready for Pickup',
  };

  static const Map<String, String> notificationDescriptions = {
    chatMessageType: 'You have a new message',
    orderStatusType: 'Check your order status',
    orderShippedType: 'Track your package now',
    orderDeliveredType: 'Successfully delivered',
    orderCancelledType: 'Your order has been cancelled',
    orderReadyType: 'Available for pickup',
  };

  // --- ADMIN NOTIFICATION TYPES ---
  static const String newCustomerMessageType = 'new_customer_message';
  static const String newOrderType = 'new_order';
  static const String lowStockType = 'low_stock';

  static const Map<String, String> adminNotificationTitles = {
    newCustomerMessageType: '💬 New Customer Message',
    newOrderType: '🛍️ New Order Received',
    lowStockType: '⚠️ Low Stock Alert',
  };

  // --- NOTIFICATION CHANNELS (for Android) ---
  static const String chatChannelId = 'petsy_chat_channel';
  static const String orderChannelId = 'petsy_order_channel';
  static const String adminChannelId = 'petsy_admin_channel';

  static const Map<String, String> channelNames = {
    chatChannelId: 'Chat Messages',
    orderChannelId: 'Order Updates',
    adminChannelId: 'Admin Notifications',
  };

  static const Map<String, String> channelDescriptions = {
    chatChannelId: 'Notifications for chat messages',
    orderChannelId: 'Notifications for order status updates',
    adminChannelId: 'Notifications for admin alerts',
  };
}
