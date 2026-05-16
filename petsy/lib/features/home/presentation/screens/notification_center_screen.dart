import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:petsy/services/notification_service_enhanced.dart';

class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  State<NotificationCenterScreen> createState() =>
      _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> {
  final Color _petsyGreen = const Color(0xFF2B8C61);
  final Color _petsyNavy = const Color(0xFF003466);
  final NotificationService _notificationService = NotificationService();
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: _petsyGreen,
          title: Text(
            'Notifications',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: Center(child: Text('Please log in to view notifications')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: _petsyGreen,
        title: Text(
          'Notifications',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: _showClearDialog,
            icon: const Icon(Icons.delete_sweep, color: Colors.white),
            label: Text(
              'Clear All',
              style: GoogleFonts.inter(color: Colors.white),
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _notificationService.getNotificationsStream(_currentUser!.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off,
                    size: 64,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }

          final notifications = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notif = notifications[index];
              final isRead = notif['read'] ?? false;
              final timestamp = (notif['timestamp'] as Timestamp?)?.toDate();
              final timeago = _getTimeAgo(timestamp);

              return _buildNotificationCard(context, notif, isRead, timeago);
            },
          );
        },
      ),
    );
  }

  Widget _buildNotificationCard(
    BuildContext context,
    Map<String, dynamic> notif,
    bool isRead,
    String timeago,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isRead ? 0 : 2,
      color: isRead ? Colors.grey[50] : Colors.white,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: _getNotificationIcon(notif['type'] ?? 'system'),
        title: Text(
          notif['title'] ?? 'Notification',
          style: GoogleFonts.inter(
            fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
            color: _petsyNavy,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              notif['body'] ?? '',
              style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[700]),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              timeago,
              style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[500]),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'mark_read') {
              _toggleReadStatus(notif['id']);
            } else if (value == 'delete') {
              _deleteNotification(notif['id']);
            }
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            PopupMenuItem<String>(
              value: 'mark_read',
              child: Row(
                children: [
                  Icon(
                    isRead ? Icons.mark_email_unread : Icons.mark_email_read,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(isRead ? 'Mark Unread' : 'Mark Read'),
                ],
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem<String>(
              value: 'delete',
              child: Row(
                children: [
                  const Icon(Icons.delete, size: 18, color: Colors.red),
                  const SizedBox(width: 8),
                  const Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
        onTap: () {
          if (!isRead) {
            _toggleReadStatus(notif['id']);
          }
          _handleNotificationTap(notif);
        },
      ),
    );
  }

  Widget _getNotificationIcon(String type) {
    IconData icon;
    Color color;

    switch (type) {
      case 'chat_message':
      case 'admin_chat_message':
        icon = Icons.chat;
        color = _petsyNavy;
        break;
      case 'order_status':
      case 'admin_new_order':
        icon = Icons.shopping_bag;
        color = _petsyGreen;
        break;
      case 'payment':
        icon = Icons.payment;
        color = Colors.blue;
        break;
      case 'low_stock':
        icon = Icons.warning;
        color = Colors.orange;
        break;
      default:
        icon = Icons.notifications;
        color = _petsyNavy;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }

  Future<void> _toggleReadStatus(String notifId) async {
    final notif = await FirebaseFirestore.instance
        .collection('notifications')
        .doc(notifId)
        .get();

    if (notif.exists) {
      final isRead = notif['read'] ?? false;
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(notifId)
          .update({'read': !isRead});
    }
  }

  Future<void> _deleteNotification(String notifId) async {
    await _notificationService.deleteNotification(notifId);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Notification deleted')));
    }
  }

  void _showClearDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Clear All Notifications?',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'This will delete all notifications. This action cannot be undone.',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await _notificationService.clearAllNotifications(
                _currentUser!.uid,
              );
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All notifications cleared')),
                );
              }
            },
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _handleNotificationTap(Map<String, dynamic> notif) {
    final type = notif['type'] ?? '';
    final action = notif['action'] ?? '';

    // You can add navigation logic here based on notification type
    print('Notification tapped: $type - $action');
  }

  String _getTimeAgo(DateTime? timestamp) {
    if (timestamp == null) return 'Just now';

    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}
