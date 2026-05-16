import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatBadgeWidget extends StatelessWidget {
  final String userId;
  final Color badgeColor;
  final Color textColor;
  final double badgeSize;
  final double fontSize;

  const ChatBadgeWidget({
    super.key,
    required this.userId,
    this.badgeColor = Colors.red,
    this.textColor = Colors.white,
    this.badgeSize = 20,
    this.fontSize = 11,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .where('customerId', isEqualTo: userId)
          .snapshots(),
      builder: (context, snapshot) {
        int unreadCount = 0;
        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map;
            final lastMsg = data['lastMessage'] ?? '';
            if (lastMsg.toString().startsWith('Admin:')) {
              unreadCount++;
            }
          }
        }

        return unreadCount > 0
            ? Container(
                height: badgeSize,
                width: badgeSize,
                decoration: BoxDecoration(
                  color: badgeColor,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$unreadCount',
                    style: GoogleFonts.inter(
                      color: textColor,
                      fontSize: fontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              )
            : const SizedBox();
      },
    );
  }
}

class UnreadNotificationBadge extends StatelessWidget {
  final String userId;
  final Color badgeColor;
  final Color textColor;
  final double badgeSize;
  final double fontSize;

  const UnreadNotificationBadge({
    super.key,
    required this.userId,
    this.badgeColor = Colors.red,
    this.textColor = Colors.white,
    this.badgeSize = 20,
    this.fontSize = 11,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('read', isEqualTo: false)
          .snapshots(),
      builder: (context, snapshot) {
        int unreadCount = snapshot.data?.docs.length ?? 0;

        return unreadCount > 0
            ? Container(
                height: badgeSize,
                width: badgeSize,
                decoration: BoxDecoration(
                  color: badgeColor,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    unreadCount > 99 ? '99+' : '$unreadCount',
                    style: GoogleFonts.inter(
                      color: textColor,
                      fontSize: fontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              )
            : const SizedBox();
      },
    );
  }
}

class AdminUnreadBadge extends StatelessWidget {
  final String adminId;
  final Color badgeColor;
  final Color textColor;
  final double badgeSize;
  final double fontSize;

  const AdminUnreadBadge({
    super.key,
    required this.adminId,
    this.badgeColor = Colors.orange,
    this.textColor = Colors.white,
    this.badgeSize = 20,
    this.fontSize = 11,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .where('hasUnreadAdmin', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        int unreadCount = snapshot.data?.docs.length ?? 0;

        return unreadCount > 0
            ? Container(
                height: badgeSize,
                width: badgeSize,
                decoration: BoxDecoration(
                  color: badgeColor,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    unreadCount > 99 ? '99+' : '$unreadCount',
                    style: GoogleFonts.inter(
                      color: textColor,
                      fontSize: fontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              )
            : const SizedBox();
      },
    );
  }
}
