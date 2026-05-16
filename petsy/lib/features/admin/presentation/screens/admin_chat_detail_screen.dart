import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminChatDetailScreen extends StatefulWidget {
  final String customerId;
  final String orderId; // 🚀 NEW: We need the specific order ID!

  const AdminChatDetailScreen({
    super.key,
    required this.customerId,
    required this.orderId,
  });

  @override
  State<AdminChatDetailScreen> createState() => _AdminChatDetailScreenState();
}

class _AdminChatDetailScreenState extends State<AdminChatDetailScreen> {
  final Color _petsyGreen = const Color(0xFF2B8C61);
  final Color _petsyNavy = const Color(0xFF003466);
  final Color _bgColor = const Color(0xFFF4F6F8);

  String _customerName = '';
  final TextEditingController _messageController = TextEditingController();
  final User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _markChatAsRead();
    _loadCustomerName();
  }

  Future<void> _loadCustomerName() async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.customerId)
          .get();

      if (userDoc.exists && userDoc.data() != null) {
        final data = userDoc.data()!;
        final firstName = (data['firstName'] ?? '').toString();
        final lastName = (data['lastName'] ?? '').toString();
        final fullName = '$firstName $lastName'.trim();

        if (fullName.isNotEmpty && mounted) {
          setState(() {
            _customerName = fullName;
          });
        }
      }
    } catch (_) {
      // ignore errors for now, fallback remains
    }
  }

  // Clear the yellow dot on the inbox!
  Future<void> _markChatAsRead() async {
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.orderId) // 🚀 FIXED: Point to the Order ID!
        .update({'hasUnreadAdmin': false});
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || currentUser == null) return;

    HapticFeedback.lightImpact();
    _messageController.clear();

    final chatRef = FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.orderId); // 🚀 FIXED: Point to the Order ID!

    // 1. Add the admin's reply to the messages subcollection
    await chatRef.collection('messages').add({
      'text': text,
      'senderId': currentUser!.uid, // This is the Admin's UID
      'timestamp': FieldValue.serverTimestamp(),
    });

    // 2. Update the parent document
    await chatRef.set({
      'lastMessage': "Admin: $text",
      'timestamp': FieldValue.serverTimestamp(),
      'hasUnreadAdmin': false, // Still false because the Admin sent it
    }, SetOptions(merge: true));
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final displayId = widget.customerId.length > 8
        ? widget.customerId.substring(0, 8).toUpperCase()
        : widget.customerId.toUpperCase();

    final shortOrderId = widget.orderId.length > 8
        ? widget.orderId.substring(0, 8).toUpperCase()
        : widget.orderId.toUpperCase();

    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        shadowColor: Colors.black.withOpacity(0.05),
        leading: const BackButton(color: Colors.black87),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _petsyNavy.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.person, color: _petsyNavy, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _customerName.isNotEmpty
                        ? _customerName
                        : 'Customer #$displayId',
                    style: GoogleFonts.inter(
                      color: _petsyNavy,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  // 🚀 UPGRADED: Shows the Admin exactly which order this is about
                  Text(
                    "Order #$shortOrderId",
                    style: GoogleFonts.inter(
                      color: Colors.grey.shade600,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // --- CHAT MESSAGES AREA ---
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(widget.orderId) // 🚀 FIXED: Point to the Order ID!
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(color: _petsyGreen),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      "No messages yet.",
                      style: GoogleFonts.inter(color: Colors.grey),
                    ),
                  );
                }

                final messages = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final data = messages[index].data() as Map<String, dynamic>;
                    final bool isAdmin = data['senderId'] == currentUser?.uid;
                    final text = data['text'] ?? '';

                    // 🚀 Format timestamp
                    final timestamp = data['timestamp'] as Timestamp?;
                    String formattedTime = 'now';
                    if (timestamp != null) {
                      final dateTime = timestamp.toDate();
                      final now = DateTime.now();
                      final difference = now.difference(dateTime);

                      if (difference.inMinutes < 60) {
                        formattedTime = '${difference.inMinutes}m ago';
                      } else if (difference.inHours < 24) {
                        formattedTime = '${difference.inHours}h ago';
                      } else {
                        formattedTime = '${difference.inDays}d ago';
                      }
                    }

                    return _buildMessageBubble(text, isAdmin, formattedTime);
                  },
                );
              },
            ),
          ),

          // --- ADMIN MESSAGE INPUT FIELD ---
          Container(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F6F8),
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: TextField(
                      controller: _messageController,
                      style: GoogleFonts.inter(fontSize: 14),
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: "Reply to customer...",
                        hintStyle: GoogleFonts.inter(
                          color: Colors.grey.shade500,
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _sendMessage,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _petsyNavy,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(String text, bool isAdmin, String timestamp) {
    return Align(
      alignment: isAdmin ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isAdmin
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 5),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isAdmin ? _petsyNavy : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: Radius.circular(isAdmin ? 20 : 5),
                bottomRight: Radius.circular(isAdmin ? 5 : 20),
              ),
              boxShadow: isAdmin
                  ? []
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
              border: isAdmin ? null : Border.all(color: Colors.grey.shade200),
            ),
            child: Text(
              text,
              style: GoogleFonts.inter(
                color: isAdmin ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w500,
                fontSize: 14,
                height: 1.3,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            child: Text(
              timestamp,
              style: GoogleFonts.inter(
                color: Colors.grey.shade500,
                fontSize: 11,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
