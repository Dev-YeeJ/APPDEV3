# 🚀 Enhanced Notification System - Petsy

## Overview

Complete notification system with push notifications, in-app overlays, notification center, and comprehensive communication between admin and users for all transactions and interactions.

---

## ✨ Features

### 1. **Push Notifications** 📱
- Works when app is **open**, **closed**, or **in background**
- Automatic FCM token management
- Reliable delivery with fallback handling

### 2. **In-App Overlay Notifications** 💬
- Sleek animated notifications at the top of the screen
- Non-blocking user experience
- Auto-dismiss with manual dismiss option
- Queue management for multiple notifications

### 3. **Notification Center** 📋
- View all past notifications
- Mark as read/unread
- Delete individual notifications
- Clear all notifications
- Time ago indicator (e.g., "2h ago", "3d ago")

### 4. **Notification Badge** 🔴
- Real-time unread count
- Easy access to notification center
- Shows "99+" for large counts

### 5. **Comprehensive Notification Types**

#### **Customer Notifications:**
- 💬 **Chat Messages** - New messages from admin
- 📦 **Order Status** - Order updates (pending, shipped, delivered, etc.)
- 🚚 **Delivery Updates** - Real-time delivery status
- ✅ **Order Delivered** - Confirmation
- ❌ **Order Cancelled** - Cancellation notice
- 💰 **Payment Notifications** - Transaction success/failure

#### **Admin Notifications:**
- 💬 **Customer Messages** - New customer messages
- 🛍️ **New Orders** - Order received alerts
- ⚠️ **Low Stock** - Inventory alerts

---

## 📦 Installation & Setup

### 1. **Update Dependencies**

Already done in `pubspec.yaml`:
```yaml
dependencies:
  firebase_messaging: ^18.0.0
  flutter_local_notifications: ^18.0.0
```

### 2. **Android Configuration**

Already configured in `android/app/build.gradle.kts`:
```kotlin
android {
    compileSdk = 35
    minSdk = 21
    
    compileOptions {
        isCoreLibraryDesugaringEnabled = true
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}
```

### 3. **Android Permissions**

Already added to `AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.VIBRATE" />
```

---

## 🚀 Usage Examples

### **1. Send Chat Notification**

```dart
import 'package:petsy/services/notification_service_enhanced.dart';

await NotificationService().sendChatNotification(
  recipientId: 'customer_uid',
  senderName: 'Admin Support',
  messagePreview: 'Your order will arrive today!',
  orderId: 'order_123',
);
```

### **2. Send Order Status Notification**

```dart
await NotificationService().sendOrderStatusNotification(
  customerId: 'customer_uid',
  orderId: 'order_123',
  orderStatus: 'toShip', // 'pending', 'toShip', 'toReceive', 'completed', 'cancelled'
  totalAmount: 1250.00,
);
```

### **3. Send Payment Notification**

```dart
await NotificationService().sendPaymentNotification(
  userId: 'customer_uid',
  transactionId: 'txn_123',
  amount: 1250.00,
  paymentMethod: 'GCash',
  isSuccess: true,
);
```

### **4. Send Admin Notifications**

**New Order:**
```dart
await NotificationService().sendAdminNewOrderNotification(
  adminId: 'admin_uid',
  orderId: 'order_123',
  customerName: 'John Doe',
  totalAmount: 1250.00,
  itemCount: 3,
);
```

**Customer Message:**
```dart
await NotificationService().sendAdminChatNotification(
  adminId: 'admin_uid',
  customerName: 'John Doe',
  messagePreview: 'Is my order coming today?',
  orderId: 'order_123',
);
```

**Low Stock:**
```dart
await NotificationService().sendLowStockNotification(
  adminId: 'admin_uid',
  productName: 'Premium Dog Food',
  currentStock: 5,
  threshold: 10,
);
```

### **5. Custom Notification**

```dart
await NotificationService().sendCustomNotification(
  userId: 'user_uid',
  title: 'Special Offer!',
  body: 'Get 20% off on all pet accessories',
  type: 'promotion',
  customData: {
    'promoCode': 'PETSY20',
    'validUntil': '2026-12-31',
  },
);
```

---

## 🎨 UI Components

### **1. Add Notification Badge to App Bar**

```dart
import 'package:petsy/widgets/notification_badge.dart';

AppBar(
  title: const Text('Home'),
  actions: [
    NotificationBadge(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const NotificationCenterScreen(),
          ),
        );
      },
    ),
  ],
)
```

### **2. Open Notification Center**

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const NotificationCenterScreen(),
  ),
);
```

---

## 📊 Notification Data Structure (Firestore)

```json
{
  "recipientId": "user_123",
  "type": "chat_message",
  "title": "💬 New Message from Admin",
  "body": "Your order will arrive today!",
  "timestamp": "2026-05-16T10:30:00Z",
  "read": false,
  "action": "open_chat",
  "orderId": "order_123",
  "senderName": "Admin Support"
}
```

---

## 🔍 Getting FCM Token for Testing

1. Run the app: `flutter run`
2. Look in the console for:
```
════════════════════════════════════════════════════
🚀🚀🚀 FCM TOKEN 🚀🚀🚀
════════════════════════════════════════════════════
eL6JX_p8S7E:APA91bH2k5F8mK9pL2oN5qR8sT1uV4wX7yZ0aB3...
════════════════════════════════════════════════════
```

3. Copy the token and use in Firebase Console to send test messages

---

## 🧪 Testing Notifications

### **In-App Testing:**
```dart
// Add this temporary button to test
ElevatedButton(
  onPressed: () async {
    await NotificationService().sendPaymentNotification(
      userId: FirebaseAuth.instance.currentUser!.uid,
      transactionId: 'test_123',
      amount: 999.99,
      paymentMethod: 'Test',
      isSuccess: true,
    );
  },
  child: const Text('Test Notification'),
)
```

### **Firebase Console Testing:**
1. Go to Firebase Messaging
2. Create campaign
3. Select your app
4. Enter your FCM token
5. Click "Test"

---

## 📁 File Structure

```
lib/
├── services/
│   ├── notification_service_enhanced.dart    # Main service
│   └── notification_service.dart             # Legacy (can delete after migration)
├── widgets/
│   ├── notification_overlay.dart             # Overlay UI
│   ├── notification_badge.dart               # Badge widget
│   └── chat_badge_widget.dart                # Existing
├── features/home/presentation/screens/
│   ├── notification_center_screen.dart       # Notification center
│   └── profile_page.dart                     # Add badge here
└── main.dart                                  # Updated with new service
```

---

## 🔄 Migration Guide (from old to new service)

### **Before:**
```dart
import 'package:petsy/services/notification_service.dart';

await NotificationService().sendChatNotification(...);
```

### **After:**
```dart
import 'package:petsy/services/notification_service_enhanced.dart';

await NotificationService().sendChatNotification(
  recipientId: 'id',      // Changed from customerId
  senderName: 'name',
  messagePreview: 'msg',
  orderId: 'id',          // New required parameter
);
```

---

## 🐛 Troubleshooting

| Issue | Solution |
|-------|----------|
| No FCM token | Check console for errors, verify Firebase setup |
| Notifications don't appear | Check device notification settings, verify Firebase Messaging enabled |
| App crashes on notification | Check console logs, verify all imports |
| Overlay not showing | Make sure `NotificationService.setAppContext()` was called |
| Badge shows wrong count | Clear app cache and restart |

---

## ✅ Checklist for Production

- [ ] Replace legacy `notification_service.dart` with `notification_service_enhanced.dart`
- [ ] Add `NotificationBadge` widget to app bar
- [ ] Add `NotificationCenterScreen` route
- [ ] Test all notification types
- [ ] Verify FCM tokens are saved to Firestore
- [ ] Test background notifications
- [ ] Test terminated app notifications
- [ ] Verify notification permissions on target devices

---

## 📞 Support

For issues or questions:
1. Check the troubleshooting section above
2. Review Firebase setup in `ADMIN_SETUP_GUIDE.md`
3. Check console logs with `flutter logs`
4. Verify FCM token is being generated and saved

---

## 📝 Notes

- Notifications are automatically saved to Firestore for history
- Each notification includes a timestamp for sorting
- Read/unread status is tracked
- Notifications can be deleted individually or all at once
- Overlay notifications automatically queue and show one at a time
