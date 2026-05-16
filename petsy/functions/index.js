// Firebase Cloud Function to make a user admin
// Save this as: functions/index.js
// Deploy with: firebase deploy --only functions

const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

const db = admin.firestore();

// 🚀 Make user admin by email
exports.makeUserAdmin = functions.https.onRequest(async (req, res) => {
  // Enable CORS
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Methods", "POST, OPTIONS");
  res.set("Access-Control-Allow-Headers", "Content-Type");

  if (req.method === "OPTIONS") {
    res.status(200).send("");
    return;
  }

  try {
    const email = req.body.email;
    const isAdmin = req.body.isAdmin || true;

    if (!email) {
      return res.status(400).json({ error: "Email is required" });
    }

    // Find user by email
    const user = await admin.auth().getUserByEmail(email);

    // Update Firestore user document
    await db.collection("users").doc(user.uid).update({
      isAdmin: isAdmin,
      role: isAdmin ? "admin" : "user",
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Also set custom claim for Firebase Auth
    await admin.auth().setCustomUserClaims(user.uid, {
      admin: isAdmin,
    });

    return res.status(200).json({
      success: true,
      message: `User ${email} is now ${isAdmin ? "admin" : "regular user"}`,
      uid: user.uid,
    });
  } catch (error) {
    console.error("Error:", error);
    return res.status(500).json({
      error: error.message,
    });
  }
});

// 🚀 Get all admin users
exports.getAllAdmins = functions.https.onRequest(async (req, res) => {
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Methods", "GET, OPTIONS");
  res.set("Access-Control-Allow-Headers", "Content-Type");

  if (req.method === "OPTIONS") {
    res.status(200).send("");
    return;
  }

  try {
    const snapshot = await db
      .collection("users")
      .where("isAdmin", "==", true)
      .get();

    const admins = [];
    snapshot.forEach((doc) => {
      admins.push({
        uid: doc.id,
        email: doc.data().email,
        username: doc.data().username,
        createdAt: doc.data().createdAt,
      });
    });

    return res.status(200).json({
      success: true,
      count: admins.length,
      admins: admins,
    });
  } catch (error) {
    console.error("Error:", error);
    return res.status(500).json({
      error: error.message,
    });
  }
});

// 🚀 Remove admin privileges
exports.removeAdminPrivileges = functions.https.onRequest(async (req, res) => {
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Methods", "POST, OPTIONS");
  res.set("Access-Control-Allow-Headers", "Content-Type");

  if (req.method === "OPTIONS") {
    res.status(200).send("");
    return;
  }

  try {
    const email = req.body.email;

    if (!email) {
      return res.status(400).json({ error: "Email is required" });
    }

    const user = await admin.auth().getUserByEmail(email);

    await db.collection("users").doc(user.uid).update({
      isAdmin: false,
      role: "user",
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    await admin.auth().setCustomUserClaims(user.uid, {
      admin: false,
    });

    return res.status(200).json({
      success: true,
      message: `Admin privileges removed from ${email}`,
      uid: user.uid,
    });
  } catch (error) {
    console.error("Error:", error);
    return res.status(500).json({
      error: error.message,
    });
  }
});

// 🚀 Trigger: Send notification when new order placed
exports.onNewOrder = functions.firestore
  .document("orders/{userId}/{orderId}")
  .onCreate(async (snap, context) => {
    try {
      const order = snap.data();
      const userId = context.params.userId;
      const orderId = context.params.orderId;

      // Notify all admins
      const adminsSnapshot = await db
        .collection("users")
        .where("isAdmin", "==", true)
        .get();

      const batch = db.batch();

      adminsSnapshot.forEach((adminDoc) => {
        const notificationRef = db.collection("notifications").doc();
        batch.set(notificationRef, {
          adminId: adminDoc.id,
          type: "new_order",
          title: "🛍️ New Order Received",
          body: `Order #${orderId.substring(0, 8)} - ${
            order.items.length
          } items - ₱${order.totalPrice.toFixed(2)}`,
          orderId: orderId,
          totalAmount: order.totalPrice,
          itemCount: order.items.length,
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
          read: false,
        });
      });

      await batch.commit();
      console.log("New order notifications sent");
    } catch (error) {
      console.error("Error sending new order notification:", error);
    }
  });

// 🚀 Trigger: Send notification when order status changes
exports.onOrderStatusChange = functions.firestore
  .document("orders/{userId}/{orderId}")
  .onUpdate(async (change, context) => {
    try {
      const beforeData = change.before.data();
      const afterData = change.after.data();

      if (beforeData.status === afterData.status) {
        return; // Status didn't change
      }

      const userId = context.params.userId;
      const orderId = context.params.orderId;

      // Get customer info
      const customerDoc = await db.collection("users").doc(userId).get();
      const customerEmail = customerDoc.data().email;

      // Map status to notification type
      let notificationType = "order_status";
      let title = "📦 Order Status Updated";
      let body = `Order #${orderId.substring(0, 8)} is now ${afterData.status}`;

      if (afterData.status === "toShip") {
        notificationType = "order_shipped";
        title = "📮 Your Order Has Been Shipped";
        body = `Your order #${orderId.substring(0, 8)} is on its way! 📮`;
      } else if (afterData.status === "toReceive") {
        body = `Your order #${orderId.substring(0, 8)} is out for delivery! 🚚`;
      } else if (afterData.status === "completed") {
        notificationType = "order_delivered";
        title = "✅ Your Order Has Been Delivered";
        body = `Your order #${orderId.substring(0, 8)} has been delivered! ✅`;
      } else if (afterData.status === "cancelled") {
        notificationType = "order_cancelled";
        title = "❌ Order Cancelled";
        body = `Your order #${orderId.substring(0, 8)} has been cancelled. ❌`;
      }

      // Save notification to Firestore
      await db.collection("notifications").add({
        userId: userId,
        type: notificationType,
        title: title,
        body: body,
        orderId: orderId,
        orderStatus: afterData.status,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        read: false,
      });

      console.log(
        `Order status change notification sent for ${customerEmail}`
      );
    } catch (error) {
      console.error("Error sending status change notification:", error);
    }
  });

// 🚀 Trigger: Send notification when chat message received
exports.onNewChatMessage = functions.firestore
  .document("chats/{orderId}/messages/{messageId}")
  .onCreate(async (snap, context) => {
    try {
      const message = snap.data();
      const orderId = context.params.orderId;

      // Get chat document to find customer and admin
      const chatDoc = await db.collection("chats").doc(orderId).get();
      const chatData = chatDoc.data();

      // Get sender info
      const senderDoc = await db
        .collection("users")
        .doc(message.senderId)
        .get();
      const senderName = senderDoc.data().username || senderDoc.data().email;

      if (message.senderId === chatData.customerId) {
        // Customer sent message, notify admin
        const adminsSnapshot = await db
          .collection("users")
          .where("isAdmin", "==", true)
          .get();

        const batch = db.batch();

        adminsSnapshot.forEach((adminDoc) => {
          const notificationRef = db.collection("notifications").doc();
          batch.set(notificationRef, {
            adminId: adminDoc.id,
            type: "new_customer_message",
            title: "💬 New Customer Message",
            body: `${senderName}: ${message.text.substring(0, 50)}...`,
            customerName: senderName,
            orderId: orderId,
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
            read: false,
          });
        });

        await batch.commit();
      } else {
        // Admin sent message, notify customer
        await db.collection("notifications").add({
          userId: chatData.customerId,
          type: "chat_message",
          title: "💬 New Message from Admin",
          body: message.text.substring(0, 100),
          orderId: orderId,
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
          read: false,
        });
      }

      console.log("Chat notification sent");
    } catch (error) {
      console.error("Error sending chat notification:", error);
    }
  });
