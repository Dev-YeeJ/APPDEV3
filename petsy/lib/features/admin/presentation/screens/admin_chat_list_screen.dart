import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Import the detail screen
import 'package:petsy/features/admin/presentation/screens/admin_chat_detail_screen.dart';

class AdminChatListScreen extends StatefulWidget {
  const AdminChatListScreen({super.key});

  @override
  State<AdminChatListScreen> createState() => _AdminChatListScreenState();
}

class _AdminChatListScreenState extends State<AdminChatListScreen> {
  final Color _petsyGreen = const Color(0xFF2B8C61);
  final Color _petsyNavy = const Color(0xFF003466);
  final Color _bgColor = const Color(0xFFF4F6F8);

  // Cache to avoid querying Firestore for the same customer's name repeatedly
  final Map<String, String> _customerNameCache = {};

  Future<String> _getCustomerName(String customerId) async {
    if (_customerNameCache.containsKey(customerId)) {
      return _customerNameCache[customerId]!;
    }

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(customerId)
          .get();
      if (userDoc.exists && userDoc.data() != null) {
        final data = userDoc.data()!;
        final firstName = (data['firstName'] ?? '').toString().trim();
        final lastName = (data['lastName'] ?? '').toString().trim();
        final fullName = '$firstName $lastName'.trim();

        if (fullName.isNotEmpty) {
          _customerNameCache[customerId] = fullName;
          return fullName;
        }
      }
    } catch (_) {}

    final fallback = customerId.length > 8
        ? 'Customer #${customerId.substring(0, 8).toUpperCase()}'
        : 'Customer #${customerId.toUpperCase()}';
    _customerNameCache[customerId] = fallback;
    return fallback;
  }

  String _formatTime(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final DateTime date = timestamp.toDate();
    final String hour = date.hour > 12
        ? '${date.hour - 12}'
        : (date.hour == 0 ? '12' : '${date.hour}');
    final String minute = date.minute.toString().padLeft(2, '0');
    final String ampm = date.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $ampm';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        shadowColor: Colors.black.withOpacity(0.05),
        leading: const BackButton(color: Colors.black87),
        title: Text(
          "Support Inbox",
          style: GoogleFonts.inter(
            color: _petsyNavy,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // 🚀 Fetching ALL order chats, ordered by the most recent message
        stream: FirebaseFirestore.instance
            .collection('chats')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: _petsyGreen));
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Error loading chats.",
                style: GoogleFonts.inter(color: Colors.red),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.mark_chat_read_outlined,
                    size: 60,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 15),
                  Text(
                    "All caught up!",
                    style: GoogleFonts.inter(
                      color: _petsyNavy,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "No active customer inquiries.",
                    style: GoogleFonts.inter(
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }

          final chats = snapshot.data!.docs;

          return ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(20),
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chatData = chats[index].data() as Map<String, dynamic>;

              // 🚀 NEW ORDER-BASED DATA
              final customerId = chatData['customerId'] ?? 'Unknown';
              final orderId = chatData['orderId'] ?? chats[index].id;
              final orderSummary = chatData['orderSummary'] ?? 'Items';
              final lastMessage = chatData['lastMessage'] ?? 'Attachment';
              final timestamp = chatData['timestamp'] as Timestamp?;
              final hasUnread =
                  chatData['hasUnreadAdmin'] ==
                  true; // True if customer sent the last message

              final shortOrderId = orderId.toString().length > 8
                  ? orderId.toString().substring(0, 8).toUpperCase()
                  : orderId.toString().toUpperCase();

              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();

                  // ⚠️ CRITICAL: Passing orderId to the Detail screen instead of just customerId!
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AdminChatDetailScreen(
                        orderId:
                            orderId, // We will update the detail screen next to accept this!
                        customerId: customerId,
                      ),
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: hasUnread
                        ? Border.all(color: Colors.amber.shade500, width: 1.5)
                        : Border.all(color: Colors.transparent),
                  ),
                  child: Row(
                    children: [
                      // CUSTOMER AVATAR
                      Container(
                        height: 50,
                        width: 50,
                        decoration: BoxDecoration(
                          color: hasUnread
                              ? Colors.amber.shade50
                              : _petsyNavy.withOpacity(0.05),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.person,
                          color: hasUnread ? Colors.amber.shade700 : _petsyNavy,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // ASYNC CUSTOMER NAME
                                FutureBuilder<String>(
                                  future: _getCustomerName(customerId),
                                  builder: (context, nameSnapshot) {
                                    final customerName =
                                        nameSnapshot.connectionState ==
                                            ConnectionState.done
                                        ? (nameSnapshot.data ?? 'Customer')
                                        : 'Loading...';
                                    return Expanded(
                                      child: Text(
                                        customerName,
                                        style: GoogleFonts.inter(
                                          fontWeight: hasUnread
                                              ? FontWeight.w800
                                              : FontWeight.w700,
                                          color: Colors.black87,
                                          fontSize: 15,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  _formatTime(timestamp),
                                  style: GoogleFonts.inter(
                                    color: hasUnread
                                        ? Colors.amber.shade700
                                        : Colors.grey.shade500,
                                    fontSize: 11,
                                    fontWeight: hasUnread
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            // 🚀 ORDER SUMMARY
                            Text(
                              "Order #$shortOrderId • $orderSummary",
                              style: GoogleFonts.inter(
                                color: _petsyNavy.withOpacity(0.7),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    lastMessage,
                                    style: GoogleFonts.inter(
                                      color: hasUnread
                                          ? Colors.black87
                                          : Colors.grey.shade600,
                                      fontSize: 13,
                                      fontWeight: hasUnread
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (hasUnread)
                                  Container(
                                    margin: const EdgeInsets.only(left: 10),
                                    height: 10,
                                    width: 10,
                                    decoration: BoxDecoration(
                                      color: Colors.amber.shade500,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
