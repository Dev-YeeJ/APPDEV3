# 🚀 PETSY - COMPLETE SETUP & DEPLOYMENT GUIDE

**Date:** May 9, 2026  
**Status:** Ready for Testing & Deployment  
**App Version:** 1.0

---

## 📋 SETUP CHECKLIST

### Phase 1: Dependencies Installation (5 minutes)

#### Step 1.1: Install Pub Dependencies
```bash
cd /path/to/petsy
flutter pub get
flutter pub upgrade
```

**What this does:**
- Downloads and installs all package dependencies
- Installs `firebase_messaging` (push notifications)
- Installs `flutter_local_notifications` (local notification display)
- Links all Firebase packages

**Verify Success:**
```bash
flutter doctor
```
Should show: ✓ Flutter, ✓ Android, ✓ iOS (if applicable)

#### Step 1.2: Clean Build
```bash
flutter clean
flutter pub get
```

---

### Phase 2: Firebase Setup (10 minutes)

#### Step 2.1: Verify Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select **Petsy** project
3. Verify these services are enabled:
   - ✅ Cloud Firestore
   - ✅ Firebase Authentication
   - ✅ Firebase Storage
   - ✅ Cloud Messaging (FCM)

#### Step 2.2: Create Admin User via Firebase Console

**Method 1: Firebase Console (Recommended - 3 minutes)**

1. Go to Firebase Console → **Authentication**
2. Click **Add User**
3. Enter credentials:
   - **Email:** `admin@petsy.local`
   - **Password:** `AdminPetsy123!`
4. Click **Create User**
5. Go to **Firestore** → **Collections** → **users**
6. Find the document with email `admin@petsy.local`
7. Edit document and **Add new field:**
   - **Field name:** `isAdmin`
   - **Type:** Boolean
   - **Value:** `true`
8. Click **Save**

**Result:** User is now admin ✅

**Method 2: Cloud Function (Advanced - 5 minutes)**

Prerequisites: Firebase CLI installed

```bash
# From project root
cd functions
npm install
firebase deploy --only functions
```

Then call the function:
```bash
curl -X POST https://us-central1-petsy.cloudfunctions.net/makeUserAdmin \
  -H "Content-Type: application/json" \
  -d '{"email": "admin@petsy.local", "isAdmin": true}'
```

**Method 3: Manual Firestore Edit (Quickest - 2 minutes)**

1. Create user via Sign Up in app
2. Go to Firebase → Firestore → users collection
3. Find your user document
4. Edit: Add `isAdmin: true` (boolean)
5. Save and sign back in

---

### Phase 3: Android Setup (10 minutes)

#### Step 3.1: Update Android Manifest

Edit: `android/app/src/main/AndroidManifest.xml`

Add these permissions after `<manifest>` opening tag:

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
<uses-permission android:name="com.google.android.c2dm.permission.RECEIVE" />
```

#### Step 3.2: Add Google Services JSON

1. From Firebase Console:
   - **Project Settings** → **Service Accounts**
   - Download `google-services.json`
2. Place in: `android/app/google-services.json`

✅ Already done (check file exists)

#### Step 3.3: Update build.gradle

Edit: `android/build.gradle.kts`

Add to `dependencies` block:
```kotlin
classpath("com.google.gms:google-services:4.3.15")
```

Edit: `android/app/build.gradle.kts`

Add to `plugins` block:
```kotlin
id("com.google.gms.google-services")
```

#### Step 3.4: Compile Version Check

Edit: `android/app/build.gradle.kts`

Verify these are set:
```kotlin
compileSdk = 34  // Or higher
minSdk = 21
targetSdk = 34
```

---

### Phase 4: iOS Setup (15 minutes)

#### Step 4.1: iOS Capabilities

1. Open in Xcode:
   ```bash
   open ios/Runner.xcworkspace
   ```

2. Select **Runner** project
3. Go to **Signing & Capabilities** tab
4. Click **+ Capability**
5. Add these capabilities:
   - **Push Notifications**
   - **Background Modes** → Select:
     - Remote Notifications
     - Background fetch

#### Step 4.2: Update Info.plist

Edit: `ios/Runner/Info.plist`

Add:
```xml
<key>UIBackgroundModes</key>
<array>
    <string>remote-notification</string>
    <string>fetch</string>
</array>
```

#### Step 4.3: Update Pod Dependencies

```bash
cd ios
pod repo update
pod install --repo-update
cd ..
```

---

### Phase 5: Test Setup (20 minutes)

#### Test 5.1: Run App on Android/iOS
```bash
flutter run
```

#### Test 5.2: Create Test Accounts

**Customer Account:**
- Email: `customer@petsy.local`
- Password: `Customer123!`
- Role: Regular user

**Admin Account:**
- Email: `admin@petsy.local`
- Password: `AdminPetsy123!`
- Role: Admin (manually set `isAdmin: true`)

#### Test 5.3: Verify Routing

| User Type | Expected Screen |
|-----------|-----------------|
| Regular User | HomeScreen (Products) |
| Admin User | AdminDashboardScreen |
| Not Logged In | SplashScreen → SignInScreen |

#### Test 5.4: Chat Functionality

**Customer:**
1. Place an order
2. Go to Orders tab
3. Click "Chat" button
4. Type message
5. Send

**Admin:**
1. Go to Admin Dashboard
2. Click "Customer Support Inbox"
3. See customer chat
4. Click to open
5. Reply to message
6. Check notification badge

#### Test 5.5: Notification Testing

**To receive notifications, you need:**

1. Physical device or emulator with Google Play Services
2. App in background (or foreground for FCM testing)
3. Firebase Project connected
4. FCM tokens saved to user documents

**Test Process:**

1. Sign in as customer on Device A
2. Sign in as admin on Device B (or same device, different app instance)
3. Customer places order
4. Admin receives "New Order" notification ✅
5. Admin sends chat message
6. Customer receives "New Message" notification ✅

---

## 🎯 NEXT STEPS - INTEGRATION POINTS

### Step 1: Integrate Notifications into Screens

The notification infrastructure is complete. Now add the **notification trigger calls** to 5 key screens:

#### Location 1: orders_screen.dart - Order Status Changes
```dart
// In _confirmAndUpdateStatus() method, after Firebase update:
await NotificationService().sendOrderStatusNotification(
  customerId: customerId,
  orderId: orderId,
  orderStatus: newStatus, // 'toShip', 'toReceive', 'completed', 'cancelled'
);
```

#### Location 2: customer_chat_screen.dart - Customer Sends Message
```dart
// In _sendMessage() method, after chatRef.collection('messages').add():
await NotificationService().sendAdminChatNotification(
  adminId: 'ADMIN_UID', // Get from Firestore
  customerName: currentUser.email ?? 'Customer',
  messagePreview: _messageController.text.substring(0, 50),
  orderId: widget.orderId,
);
```

#### Location 3: admin_chat_detail_screen.dart - Admin Sends Message
```dart
// In _sendMessage() method, after message sent:
await NotificationService().sendChatNotification(
  customerId: widget.customerId,
  senderName: 'Admin',
  messagePreview: _messageController.text.substring(0, 50),
);
```

#### Location 4: checkout_screen.dart - Order Placed
```dart
// In _placeOrder() method, success block:
await NotificationService().sendAdminNewOrderNotification(
  adminId: 'ADMIN_UID',
  orderId: orderId,
  totalAmount: totalPrice,
  itemCount: cart.length,
);
```

#### Location 5: manage_products_screen.dart - Low Stock Alert
```dart
// In updateStock() method, when stock < threshold:
if (newStock < 5) {
  await NotificationService().sendLowStockNotification(
    adminId: 'ADMIN_UID',
    productName: productName,
    stockLevel: newStock,
  );
}
```

---

## 📱 DEPLOYMENT CHECKLIST

### Before Release:
- [ ] All dependencies installed (`flutter pub get`)
- [ ] No compilation errors (`flutter analyze`)
- [ ] Chat feature tested (customer & admin)
- [ ] Notifications working (sent & received)
- [ ] Admin routing verified (isAdmin field working)
- [ ] All 5 notification integration points added
- [ ] Android manifest updated
- [ ] iOS capabilities enabled
- [ ] Build tested on physical device
- [ ] User can sign up, sign in, place order, chat, receive notifications

### Release:
- [ ] Firebase security rules reviewed and deployed
- [ ] Cloud Functions deployed (if using admin setup function)
- [ ] Version bumped (pubspec.yaml)
- [ ] App signed (release build)
- [ ] Published to Play Store / App Store

---

## 🧪 TESTING SCENARIOS

### Scenario 1: Basic Chat Flow (5 minutes)
```
1. Customer A signs up and logs in
2. Customer A places an order
3. Admin B signs in
4. Admin B goes to "Customer Support Inbox"
5. Admin B sees Customer A's chat
6. Admin B sends message: "Hi, thanks for ordering!"
7. Verify: Customer A receives notification
8. Verify: Message shows as "Admin: Hi, thanks..."
```

### Scenario 2: Order Status Notification (3 minutes)
```
1. Admin updates order from "toPay" to "toShip"
2. Verify: Customer receives "Order Shipped" notification
3. Customer taps notification
4. Verify: Routed to Orders screen with updated status
```

### Scenario 3: Multiple Admin Test (10 minutes)
```
1. Create 2 admin users (isAdmin: true)
2. Customer places order
3. All admins should receive "New Order" notification
4. Admin 1 replies to chat
5. Admin 2 should see hasUnreadAdmin = false
6. Verify: Only Admin 1 sees new customer message (if not already read)
```

### Scenario 4: Unread Badge Test (5 minutes)
```
1. Customer sends message: "Where is my order?"
2. Admin doesn't read it yet
3. Check: Admin dashboard shows red badge with "1"
4. Admin reads message
5. Verify: Badge disappears
```

---

## 🐛 TROUBLESHOOTING

### Issue: "Target of URI doesn't exist: 'package:firebase_messaging...'"

**Solution:**
```bash
flutter clean
flutter pub get
flutter pub upgrade firebase_messaging flutter_local_notifications
```

### Issue: FCM Token Not Saving

**Check:**
1. User is logged in
2. App has internet connection
3. Firebase project has Cloud Messaging enabled
4. Verify token saved in Firestore:
   - Go to Firestore → users → {userId}
   - Should see `fcmToken: "ABC123..."`

**If missing:**
```dart
// In main.dart, verify this line runs:
await NotificationService().initialize();
```

### Issue: Notifications Not Received

**Check Checklist:**
- [ ] App running on physical device (emulator may not work)
- [ ] Google Play Services installed
- [ ] Notifications permission granted
- [ ] App in background or foreground
- [ ] FCM token saved in Firestore
- [ ] Firebase project FCM enabled
- [ ] No build errors

**Debug:**
```bash
# Check logs
flutter logs
```

### Issue: Admin Not Routing to Dashboard

**Check:**
1. User document has `isAdmin: true` (boolean, not string)
2. Sign out and sign in again
3. Check Firestore user document:
   ```
   {
     email: "admin@...",
     isAdmin: true  // ✅ Must be boolean
   }
   ```

### Issue: Chat Messages Not Appearing

**Verify:**
1. Firestore Firestore Security Rules allow read/write for chats collection
2. Message senderId matches current user UID
3. Chat document exists with orderId as document ID
4. Messages are in subcollection, not top-level

---

## 📊 QUICK REFERENCE

### Notification Types
```dart
Customer Notifications:
- 'chat_message' → Admin replied
- 'order_status' → Status updated
- 'order_shipped' → Shipped
- 'order_delivered' → Delivered
- 'order_cancelled' → Cancelled
- 'order_ready' → Ready for pickup

Admin Notifications:
- 'new_customer_message' → Customer messaged
- 'new_order' → New order placed
- 'low_stock' → Product stock low
```

### Key Files
| File | Purpose |
|------|---------|
| `lib/services/notification_service.dart` | Push notification manager |
| `lib/providers/chat_provider.dart` | Chat state management |
| `lib/features/home/data/repositories/chat_repository.dart` | Firestore operations |
| `lib/utils/chat_constants.dart` | Constants & notification types |
| `lib/widgets/chat_badge_widget.dart` | Reusable badge components |

### Important URLs
| Resource | URL |
|----------|-----|
| Firebase Console | https://console.firebase.google.com/ |
| Flutter Docs | https://flutter.dev/docs |
| Firebase Docs | https://firebase.google.com/docs |
| FCM Setup | https://firebase.google.com/docs/cloud-messaging/flutter/client |

---

## ✅ SUCCESS CRITERIA

Your app is **ready for production** when:

- ✅ All dependencies installed without errors
- ✅ App builds successfully (`flutter build apk` / `flutter build ios`)
- ✅ User can create account and sign in
- ✅ Admin user created and routing to dashboard
- ✅ Customer can place order and access chat
- ✅ Admin can view all chats and reply
- ✅ Notifications sent and received on device
- ✅ All 5 notification integration points implemented
- ✅ Tested on physical device (Android & iOS)
- ✅ No compilation errors or warnings

---

## 🎯 QUICK START (For Returning Users)

If you're coming back to this project:

1. **Install dependencies:**
   ```bash
   flutter pub get
   ```

2. **Verify setup:**
   ```bash
   flutter doctor
   ```

3. **Run app:**
   ```bash
   flutter run
   ```

4. **Create test admin:**
   - Sign up in app
   - Go to Firebase Console → Firestore
   - Edit user document: add `isAdmin: true`
   - Sign back in

5. **Test chat:**
   - Sign in as customer
   - Place order
   - Click "Chat" button
   - Send message

---

## 📞 SUPPORT

### Key Contacts
- **Firebase Support:** https://firebase.google.com/support
- **Flutter Community:** https://flutter.dev/community
- **Stack Overflow:** Tag `flutter` `firebase`

### Documentation Files
- [APPLICATION_REVIEW.md](APPLICATION_REVIEW.md) - Full app features
- [ADMIN_SETUP_GUIDE.md](ADMIN_SETUP_GUIDE.md) - Admin setup detailed

---

**Document Version:** 1.0  
**Last Updated:** May 9, 2026  
**Status:** ✅ Complete and Ready for Deployment
