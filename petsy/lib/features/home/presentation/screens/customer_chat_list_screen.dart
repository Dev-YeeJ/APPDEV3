import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:petsy/features/home/presentation/screens/customer_chat_screen.dart';

class CustomerChatListScreen extends StatefulWidget {
  const CustomerChatListScreen({super.key});

  @override
  State<CustomerChatListScreen> createState() => _CustomerChatListScreenState();
}

class _CustomerChatListScreenState extends State<CustomerChatListScreen> {
  final Color _petsyGreen = const Color(0xFF2B8C61);
  final Color _petsyNavy = const Color(0xFF003466);
  final Color _bgColor = const Color(0xFFF4F6F8);
  final User? currentUser = FirebaseAuth.instance.currentUser;

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
          "Order Messages",
          style: GoogleFonts.inter(
            color: _petsyNavy,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: currentUser == null
          ? const Center(child: Text("Please log in to view messages."))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .where('customerId', isEqualTo: currentUser!.uid)
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(color: _petsyGreen),
                  );
                }

                // 🚀 THE MAGIC ERROR CATCHER
                if (snapshot.hasError) {
                  print("🔥 FIREBASE MAGIC LINK ERROR: ${snapshot.error}");
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.red,
                          size: 50,
                        ),
                        const SizedBox(height: 15),
                        Text(
                          "Database Index Required!",
                          style: GoogleFonts.inter(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Check your VS Code Debug Console\nfor the blue Firebase link.",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 60,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 15),
                        Text(
                          "No messages yet.",
                          style: GoogleFonts.inter(
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "Go to your Orders to contact the seller.",
                          style: GoogleFonts.inter(
                            color: Colors.grey.shade400,
                            fontSize: 12,
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
                    final chatData =
                        chats[index].data() as Map<String, dynamic>;
                    final orderId = chatData['orderId'] ?? 'Unknown Order';
                    final shortOrderId = orderId.toString().length > 8
                        ? orderId.toString().substring(0, 8).toUpperCase()
                        : orderId.toString().toUpperCase();
                    final orderSummary = chatData['orderSummary'] ?? 'Items';
                    final lastMessage = chatData['lastMessage'] ?? '';
                    final timestamp = chatData['timestamp'] as Timestamp?;

                    // If last message starts with Admin:, flag it as unread for the customer
                    final bool hasUnread = lastMessage.toString().startsWith(
                      "Admin:",
                    );

                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CustomerChatScreen(
                              orderId: orderId,
                              orderSummary: orderSummary,
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
                              ? Border.all(
                                  color: _petsyGreen.withOpacity(0.5),
                                  width: 1.5,
                                )
                              : Border.all(color: Colors.transparent),
                        ),
                        child: Row(
                          children: [
                            Container(
                              height: 50,
                              width: 50,
                              decoration: BoxDecoration(
                                color: _petsyGreen.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.inventory_2,
                                color: _petsyGreen,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "Order #$shortOrderId",
                                        style: GoogleFonts.inter(
                                          fontWeight: hasUnread
                                              ? FontWeight.w800
                                              : FontWeight.w600,
                                          color: Colors.black87,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        _formatTime(timestamp),
                                        style: GoogleFonts.inter(
                                          color: hasUnread
                                              ? _petsyGreen
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
                                  Text(
                                    orderSummary,
                                    style: GoogleFonts.inter(
                                      color: Colors.grey.shade500,
                                      fontSize: 11,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
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
                                          margin: const EdgeInsets.only(
                                            left: 10,
                                          ),
                                          height: 10,
                                          width: 10,
                                          decoration: const BoxDecoration(
                                            color: Colors.redAccent,
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
