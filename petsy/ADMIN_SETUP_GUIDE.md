#!/bin/bash

# PETSY APPLICATION REVIEW & ADMIN SETUP GUIDE

## 📱 APPLICATION OVERVIEW

### Architecture
- **Frontend**: Flutter (iOS, Android)
- **Backend**: Firebase (Firestore, Authentication, Storage, Messaging)
- **State Management**: Provider (Cart, Chat)
- **UI Framework**: Material Design with Google Fonts

### Core Features Implemented
1. ✅ Authentication (Sign Up/Sign In with Firebase Auth)
2. ✅ Customer Dashboard (Home Screen with Products)
3. ✅ Shopping Cart (Real-time sync with Firestore)
4. ✅ Order Management (Order placement, tracking)
5. ✅ Admin Dashboard (Product management, order management)
6. ✅ Real-time Chat (Customer-Admin messaging)
7. ✅ Push Notifications (Chat & Order tracking)
8. ✅ User Profiles & Settings

---

## 👨‍💼 ADMIN USER SETUP GUIDE

### Option 1: Create Admin via Firebase Console (Recommended)

1. Go to Firebase Console: https://console.firebase.google.com/
2. Select your Petsy project
3. Go to **Firestore Database** → **Collections** → **users**
4. Create a new document with a user's UID (or modify existing user)
5. Add these fields:
   ```
   username: "Admin Name"
   email: "admin@petsy.com"
   createdAt: (current timestamp)
   role: "admin"
   isAdmin: true
   profileCompleted: true
   firstName: "Admin"
   lastName: "Petsy"
   phone: "09XX-XXX-XXXX"
   barangay: "Makati"
   city: "Metro Manila"
   addressDetails: "Your Office Address"
   fcmToken: "" (will be auto-filled on first login)
   ```

### Option 2: Create Admin via CLI Script (Firebase Functions)

Create a Cloud Function to make any user an admin:

```bash
# Copy the provided createAdmin.js file to your Firebase functions directory
firebase deploy --only functions:makeUserAdmin
```

Then call:
```
POST https://your-region-your-project.cloudfunctions.net/makeUserAdmin
Body: {
  "email": "admin@petsy.com",
  "isAdmin": true
}
```

### Option 3: Manual Database Update

1. In Firebase Console, navigate to user document
2. Click **Edit** on the user
3. Add field: `isAdmin` → `true`
4. Click **Save**

---

## 🔐 CREATING A TEST ADMIN ACCOUNT

### Manual Steps (Fastest):

1. **Sign Up a new account:**
   - Open Petsy app
   - Click "Sign Up"
   - Email: `admin@petsy.local`
   - Password: `AdminPetsy123!`
   - Username: `PetsyAdmin`

2. **Convert to Admin in Firebase:**
   - Go to Firebase Console
   - Collections → users
   - Find document with email `admin@petsy.local`
   - Copy the UID (e.g., `abc123def456`)
   - Edit that document
   - Add field: `isAdmin` = `true`

3. **Sign Out & Sign Back In:**
   - App will now route to Admin Dashboard

---

## 📲 PUSH NOTIFICATION SYSTEM

### Notification Types Implemented:

#### Customer Notifications:
- 💬 **New Chat Message** - Admin replies to customer inquiry
- 📦 **Order Status Updated** - Generic order status change
- 📮 **Order Shipped** - Package is on its way
- 🚚 **Order Out for Delivery** - Final delivery stage
- ✅ **Order Delivered** - Successfully received
- ❌ **Order Cancelled** - Order cancellation
- 🎉 **Order Ready** - Ready for pickup

#### Admin Notifications:
- 💬 **New Customer Message** - Customer sent a message
- 🛍️ **New Order Received** - Customer placed an order
- ⚠️ **Low Stock Alert** - Product stock is low

### Triggering Notifications:

```dart
// In your code, use NotificationService to send notifications

// Send chat notification to customer
await NotificationService().sendChatNotification(
  customerId: "user123",
  senderName: "Admin Petsy",
  messagePreview: "Your order will arrive today!",
);

// Send order status notification
await NotificationService().sendOrderStatusNotification(
  customerId: "user123",
  orderId: "order456",
  orderStatus: "toShip", // 'toShip', 'toReceive', 'completed', 'cancelled'
);

// Send admin notification for new message
await NotificationService().sendAdminChatNotification(
  adminId: "admin123",
  customerName: "John Doe",
  messagePreview: "Is my order coming today?",
  orderId: "order456",
);

// Send new order notification to admin
await NotificationService().sendAdminNewOrderNotification(
  adminId: "admin123",
  orderId: "order456",
  totalAmount: 1250.00,
  itemCount: 3,
);
```

### Setup Requirements:

1. **Update pubspec.yaml** with these dependencies:
   ```yaml
   dependencies:
     firebase_messaging: ^14.6.0
     flutter_local_notifications: ^16.1.0
   ```

2. **Initialize in main.dart:**
   ```dart
   void main() async {
     WidgetsFlutterBinding.ensureInitialized();
     await Firebase.initializeApp(
       options: DefaultFirebaseOptions.currentPlatform,
     );
     await NotificationService().initialize();
     runApp(const MyApp());
   }
   ```

3. **Android Configuration:**
   - Add to `android/app/build.gradle`:
     ```gradle
     android {
       compileSdkVersion 34
       minSdkVersion 21
     }
     ```

4. **iOS Configuration:**
   - Capabilities → Push Notifications (enabled)
   - Capabilities → Background Modes → Remote Notifications

---

## 📁 PROJECT STRUCTURE

```
lib/
├── features/
│   ├── auth/
│   │   └── presentation/screens/
│   │       ├── sign_in_screen.dart
│   │       ├── sign_up_screen.dart
│   │       └── complete_profile_screen.dart
│   ├── home/
│   │   ├── data/
│   │   │   ├── models/
│   │   │   │   ├── chat_model.dart
│   │   │   │   └── message_model.dart
│   │   │   └── repositories/
│   │   │       └── chat_repository.dart
│   │   └── presentation/screens/
│   │       ├── home_screen.dart
│   │       ├── product_details_screen.dart
│   │       ├── cart_screen.dart
│   │       ├── orders_screen.dart
│   │       ├── profile_page.dart
│   │       ├── customer_chat_list_screen.dart
│   │       └── customer_chat_screen.dart
│   └── admin/
│       └── presentation/screens/
│           ├── admin_dashboard_screen.dart
│           ├── admin_manage_orders_screen.dart
│           ├── admin_chat_list_screen.dart
│           ├── admin_chat_detail_screen.dart
│           └── manage_products_screen.dart
├── providers/
│   ├── cart_provider.dart
│   └── chat_provider.dart
├── services/
│   └── notification_service.dart
├── widgets/
│   └── chat_badge_widget.dart
├── utils/
│   └── chat_constants.dart
└── main.dart
```

---

## 🚀 KEY INTEGRATIONS

### Firebase Firestore Collections:
- `users` - User profiles with isAdmin flag
- `products` - Product catalog
- `chats` - Order-based chat messages
- `notifications` - Push notification history
- `orders` - Customer orders

### Authentication Flow:
1. User signs up → Creates user document with `isAdmin: false`
2. Admin manually sets `isAdmin: true` in Firebase
3. User signs in → App checks `isAdmin` field
4. If `isAdmin: true` → Routes to AdminDashboardScreen
5. If `isAdmin: false` → Routes to HomeScreen

---

## ✅ TESTING CHECKLIST

- [ ] Create test customer account
- [ ] Create test admin account (using steps above)
- [ ] Test customer can see products
- [ ] Test customer can add to cart
- [ ] Test customer can place order
- [ ] Test admin can view orders
- [ ] Test admin-customer chat
- [ ] Test notifications (send manual test)
- [ ] Test order status updates trigger notifications
- [ ] Test badge counts update in real-time

---

## 📞 SUPPORT FEATURES

### Real-Time Chat
- ✅ Customer initiates chat from orders or product details
- ✅ Admin can view all pending chats with unread count
- ✅ Messages prefixed with "Admin: " for admin replies
- ✅ Auto-updates admin unread status

### Order Tracking
- ✅ Customers can view order status (toPay, toShip, toReceive, completed)
- ✅ Customers can contact seller from order card
- ✅ Status changes trigger notifications
- ✅ Order history persists in Firestore

---

## 🔔 NOTIFICATION FLOW

```
Admin sends message
    ↓
ChatRepository.sendMessage()
    ↓
Updates chat metadata with "Admin: " prefix
    ↓
NotificationService.sendChatNotification()
    ↓
Saves to notifications collection
    ↓
Shows local notification + FCM (if enabled)
    ↓
Customer receives notification badge
    ↓
Customer taps → Opens chat screen
```

---

## 🛠️ TROUBLESHOOTING

### Notifications not showing?
1. Check FCM token is saved in user document
2. Verify notification permissions are granted
3. Check Android notification channel setup
4. For iOS, ensure Background Modes enabled

### Admin not routing correctly?
1. Verify `isAdmin: true` is set in Firestore
2. Clear app cache and sign in again
3. Check Firebase Auth UID matches document ID

### Chat not syncing?
1. Verify user and admin UIDs are correct
2. Check Firestore security rules allow reads/writes
3. Ensure chat collection has proper indexing

---

## 📚 RESOURCES

- Firebase Documentation: https://firebase.flutter.dev/
- Flutter Notifications: https://pub.dev/packages/firebase_messaging
- Petsy Project Structure: See PROJECT STRUCTURE above

---

**Version:** 1.0  
**Last Updated:** May 9, 2026  
**Status:** ✅ Complete with Chat, Orders, Notifications
