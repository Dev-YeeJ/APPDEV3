import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';

// 🚀 NOTIFICATION SERVICE
import 'package:petsy/services/notification_service_enhanced.dart';

// --- Ensure these paths match your project structure ---
import 'package:petsy/features/home/presentation/screens/edit_profile_screen.dart';
import 'package:petsy/features/home/presentation/screens/home_screen.dart';
import 'package:petsy/features/home/presentation/screens/cart_screen.dart';
import 'package:petsy/features/home/presentation/screens/orders_screen.dart';
import 'package:petsy/features/auth/presentation/screens/sign_in_screen.dart';
import 'package:petsy/features/admin/presentation/screens/admin_dashboard_screen.dart';

// 🚀 NEW FUNCTIONAL ROUTES
import 'package:petsy/features/home/presentation/screens/customer_chat_list_screen.dart';
import 'package:petsy/features/home/presentation/screens/shipping_address_screen.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final User? currentUser = FirebaseAuth.instance.currentUser;

  final Color _petsyGreen = const Color(0xFF2B8C61);
  final Color _petsyNavy = const Color(0xFF003466);
  final Color _lightGray = const Color(0xFFF4F6F8);
  final Color _bottomNavBg = const Color(0xFFE2E2E2);

  Future<void> _signOut() async {
    HapticFeedback.mediumImpact();
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const SignInScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 400),
        ),
        (route) => false,
      );
    }
  }

  void _shareProfile() {
    HapticFeedback.selectionClick();
    Share.share(
      'Check out my Petsy profile! @${currentUser?.displayName ?? 'user'}',
    );
  }

  double _calculateProfileCompletion(Map<String, dynamic> userData) {
    double score = 0.25;
    if (userData['base64Image'] != null) score += 0.25;
    if (userData['phone'] != null && userData['phone'].toString().isNotEmpty) {
      score += 0.25;
    }
    if (userData['address'] != null && userData['address']['city'] != null) {
      score += 0.25;
    }
    return score;
  }

  // Generic navigation to sub-screens created at the bottom of this file
  void _navigateToLocalScreen(Widget screen) {
    HapticFeedback.selectionClick();
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  // 🚀 TEST: CHAT NOTIFICATION
  Future<void> _testChatNotification() async {
    HapticFeedback.selectionClick();
    try {
      await NotificationService().sendChatNotification(
        recipientId: currentUser!.uid,
        senderName: '👨‍💼 Admin Support',
        messagePreview: 'Your order will arrive today! 📦',
        orderId: 'TEST-ORDER-001',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✅ Chat notification sent!'),
            backgroundColor: _petsyGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('❌ Error: $e')));
      }
    }
  }

  // 🚀 TEST: ORDER NOTIFICATION
  Future<void> _testOrderNotification() async {
    HapticFeedback.selectionClick();
    try {
      await NotificationService().sendOrderStatusNotification(
        customerId: currentUser!.uid,
        orderId: 'TEST-ORDER-001',
        orderStatus: 'toShip',
        totalAmount: 1250.00,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✅ Order notification sent!'),
            backgroundColor: _petsyGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('❌ Error: $e')));
      }
    }
  }

  // 🚀 TEST: PAYMENT NOTIFICATION
  Future<void> _testPaymentNotification() async {
    HapticFeedback.selectionClick();
    try {
      await NotificationService().sendPaymentNotification(
        userId: currentUser!.uid,
        transactionId: 'TXN-TEST-${DateTime.now().millisecond}',
        amount: 1250.00,
        paymentMethod: 'GCash',
        isSuccess: true,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✅ Payment notification sent!'),
            backgroundColor: _petsyGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('❌ Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return Scaffold(
        backgroundColor: _lightGray,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_off, size: 60, color: Colors.grey.shade400),
              const SizedBox(height: 15),
              Text(
                "No user logged in",
                style: GoogleFonts.inter(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: _petsyGreen),
                onPressed: _signOut,
                child: Text(
                  "Return to Login",
                  style: GoogleFonts.inter(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      extendBody: true,
      backgroundColor: _lightGray,
      bottomNavigationBar: _buildCustomBottomNav(),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser!.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_petsyGreen, _petsyNavy],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            );
          }

          if (snapshot.hasError ||
              !snapshot.hasData ||
              !snapshot.data!.exists) {
            return const Center(
              child: Text("Error loading profile. Please restart the app."),
            );
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>;
          final String? base64Image = userData['base64Image'];
          final String fullName =
              "${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}"
                  .trim();
          final String displayUsername = userData['username'] != null
              ? "@${userData['username']}"
              : "@user";
          final double completionScore = _calculateProfileCompletion(userData);
          final Timestamp? createdAt = userData['createdAt'] as Timestamp?;
          final String joinedDate = createdAt != null
              ? "Joined ${createdAt.toDate().year}"
              : "New Member";
          final bool isAdmin = userData['isAdmin'] == true;

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // --- PREMIUM HEADER ---
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.only(bottom: 30),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [_petsyGreen, _petsyNavy],
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(40),
                      bottomRight: Radius.circular(40),
                    ),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  "Profile",
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Image.asset(
                                'assets/images/petsylogowhite.png',
                                height: 26,
                                errorBuilder: (c, e, s) => Text(
                                  "Petsy",
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 20,
                                  ),
                                ),
                              ),

                              Align(
                                alignment: Alignment.centerRight,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // 🚀 ROUTED TO NEW CUSTOMER CHAT LIST (INBOX)
                                    StreamBuilder<QuerySnapshot>(
                                      stream: FirebaseFirestore.instance
                                          .collection('chats')
                                          .where(
                                            'customerId',
                                            isEqualTo: currentUser!.uid,
                                          )
                                          .snapshots(),
                                      builder: (context, chatSnap) {
                                        bool hasUnreadReply = false;
                                        if (chatSnap.hasData) {
                                          for (var doc in chatSnap.data!.docs) {
                                            final lastMsg =
                                                (doc.data()
                                                        as Map)['lastMessage']
                                                    ?.toString() ??
                                                '';
                                            if (lastMsg.startsWith("Admin:")) {
                                              hasUnreadReply = true;
                                            }
                                          }
                                        }

                                        return GestureDetector(
                                          onTap: () {
                                            HapticFeedback.selectionClick();
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    const CustomerChatListScreen(),
                                              ),
                                            );
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(
                                                0.2,
                                              ),
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: Colors.white.withOpacity(
                                                  0.4,
                                                ),
                                                width: 1,
                                              ),
                                            ),
                                            child: Stack(
                                              clipBehavior: Clip.none,
                                              children: [
                                                const Icon(
                                                  Icons.forum_outlined,
                                                  color: Colors.white,
                                                  size: 20,
                                                ), // Changed to Forum icon for Inbox
                                                if (hasUnreadReply)
                                                  Positioned(
                                                    top: -2,
                                                    right: -2,
                                                    child: Container(
                                                      height: 10,
                                                      width: 10,
                                                      decoration: BoxDecoration(
                                                        color: Colors.redAccent,
                                                        shape: BoxShape.circle,
                                                        border: Border.all(
                                                          color: _petsyNavy,
                                                          width: 2,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                    const SizedBox(width: 12),
                                    GestureDetector(
                                      onTap: () => _navigateToLocalScreen(
                                        const LocalSettingsScreen(),
                                      ),
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white.withOpacity(
                                              0.4,
                                            ),
                                            width: 1,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.settings_outlined,
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
                        ),
                        const SizedBox(height: 10),

                        // USER AVATAR
                        Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.white.withOpacity(0.5),
                                    Colors.white,
                                  ],
                                ),
                              ),
                              child: CircleAvatar(
                                radius: 55,
                                backgroundColor: Colors.white,
                                backgroundImage: base64Image != null
                                    ? MemoryImage(base64Decode(base64Image))
                                    : null,
                                child: base64Image == null
                                    ? Icon(
                                        Icons.person,
                                        size: 55,
                                        color: Colors.grey.shade400,
                                      )
                                    : null,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        EditProfileScreen(userData: userData),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _petsyGreen,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 5,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),

                        Text(
                          fullName.isEmpty ? "Petsy User" : fullName,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "$displayUsername  •  $joinedDate",
                          style: GoogleFonts.inter(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 25),

                        // GLASSMORPHISM STATS BAR
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 15,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _buildStatItem(
                                      "0",
                                      "Favorites",
                                      () => Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const OrdersScreen(),
                                        ),
                                      ),
                                    ), // Directs to Orders where Favorites tab is
                                    Container(
                                      height: 40,
                                      width: 1,
                                      color: Colors.white.withOpacity(0.3),
                                    ),
                                    _buildStatItem(
                                      "0",
                                      "Reviews",
                                      () => _navigateToLocalScreen(
                                        const LocalReviewsScreen(),
                                      ),
                                    ),
                                    Container(
                                      height: 40,
                                      width: 1,
                                      color: Colors.white.withOpacity(0.3),
                                    ),
                                    _buildStatItem(
                                      "Orders",
                                      "",
                                      () => Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const OrdersScreen(),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // --- SCROLLABLE SETTINGS & INFO ---
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (completionScore < 1.0) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Profile Completion",
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: _petsyNavy,
                              ),
                            ),
                            Text(
                              "${(completionScore * 100).toInt()}%",
                              style: GoogleFonts.inter(
                                color: _petsyGreen,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: TweenAnimationBuilder<double>(
                            duration: const Duration(milliseconds: 1000),
                            curve: Curves.easeOutCubic,
                            tween: Tween<double>(
                              begin: 0,
                              end: completionScore,
                            ),
                            builder: (context, value, _) {
                              return LinearProgressIndicator(
                                value: value,
                                backgroundColor: Colors.grey.shade300,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  _petsyGreen,
                                ),
                                minHeight: 8,
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 25),
                      ],

                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _petsyGreen,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        EditProfileScreen(userData: userData),
                                  ),
                                );
                              },
                              icon: const Icon(
                                Icons.edit_outlined,
                                color: Colors.white,
                                size: 18,
                              ),
                              label: Text(
                                "Edit Profile",
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                side: BorderSide(
                                  color: _petsyGreen,
                                  width: 1.5,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: _shareProfile,
                              icon: Icon(
                                Icons.ios_share,
                                color: _petsyGreen,
                                size: 18,
                              ),
                              label: Text(
                                "Share",
                                style: GoogleFonts.inter(
                                  color: _petsyGreen,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),

                      if (isAdmin) ...[
                        Text(
                          "Admin Controls",
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.amber.shade400,
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.amber.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: _buildMenuTile(
                            Icons.admin_panel_settings,
                            "Admin Dashboard",
                            subtitle: "Manage inventory, orders & users",
                            iconColor: Colors.amber.shade700,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const AdminDashboardScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 25),
                      ],

                      Text(
                        "Account Settings",
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            _buildMenuTile(
                              Icons.person_outline,
                              "Personal Information",
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      EditProfileScreen(userData: userData),
                                ),
                              ),
                            ),
                            _buildDivider(),

                            // 🚀 FULLY FUNCTIONAL SHIPPING ADDRESS SCREEN
                            _buildMenuTile(
                              Icons.location_on_outlined,
                              "Shipping Addresses",
                              subtitle: "Manage delivery locations",
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ShippingAddressScreen(),
                                ),
                              ),
                            ),

                            _buildDivider(),
                            _buildMenuTile(
                              Icons.credit_card_outlined,
                              "Payment Methods",
                              subtitle: "Visa, GCash, Maya",
                              onTap: () => _navigateToLocalScreen(
                                const LocalPaymentScreen(),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 25),

                      Text(
                        "General",
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            _buildMenuTile(
                              Icons.notifications_none_outlined,
                              "Notifications",
                              onTap: () => _navigateToLocalScreen(
                                const LocalSettingsScreen(),
                              ),
                            ),
                            _buildDivider(),
                            _buildMenuTile(
                              Icons.security_outlined,
                              "Privacy & Security",
                              onTap: () => _navigateToLocalScreen(
                                const LocalSettingsScreen(),
                              ),
                            ),
                            _buildDivider(),
                            _buildMenuTile(
                              Icons.help_outline,
                              "Help Center",
                              onTap: () => _navigateToLocalScreen(
                                const LocalHelpScreen(),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),

                      // 🚀 TEST NOTIFICATIONS SECTION
                      Text(
                        "Testing",
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            _buildMenuTile(
                              Icons.chat_bubble_outline,
                              "Test Chat Notification",
                              subtitle: "Send a test message notification",
                              onTap: () => _testChatNotification(),
                            ),
                            _buildDivider(),
                            _buildMenuTile(
                              Icons.shopping_bag_outlined,
                              "Test Order Notification",
                              subtitle: "Send a test order update",
                              onTap: () => _testOrderNotification(),
                            ),
                            _buildDivider(),
                            _buildMenuTile(
                              Icons.payment_outlined,
                              "Test Payment Notification",
                              subtitle: "Send a test payment confirmation",
                              onTap: () => _testPaymentNotification(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),

                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: TextButton(
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.red.shade50,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: _signOut,
                          child: Text(
                            "Log Out",
                            style: GoogleFonts.inter(
                              color: Colors.red.shade700,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- HELPER METHODS ---

  Widget _buildCustomBottomNav() {
    return Container(
      height: 90,
      color: Colors.transparent,
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          Container(height: 70, decoration: BoxDecoration(color: _bottomNavBg)),
          Padding(
            padding: const EdgeInsets.only(bottom: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildNavItem(
                  Icons.home_outlined,
                  "Home",
                  false,
                  () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                  ),
                ),
                _buildNavItem(
                  Icons.shopping_cart_outlined,
                  "Cart",
                  false,
                  () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const CartScreen()),
                  ),
                ),
                _buildNavItem(
                  Icons.format_list_bulleted,
                  "Orders",
                  false,
                  () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const OrdersScreen()),
                  ),
                ),
                Container(
                  height: 65,
                  width: 65,
                  margin: const EdgeInsets.only(bottom: 5),
                  decoration: BoxDecoration(
                    color: _petsyGreen,
                    shape: BoxShape.circle,
                    border: Border.all(color: _bottomNavBg, width: 4),
                  ),
                  child: const Icon(
                    Icons.person_outline,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    IconData icon,
    String label,
    bool isActive,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 70,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.black87, size: 28),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String number, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Column(
        children: [
          Text(
            number,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (label.isNotEmpty) const SizedBox(height: 2),
          if (label.isNotEmpty)
            Text(
              label,
              style: GoogleFonts.inter(
                color: Colors.white.withOpacity(0.8),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMenuTile(
    IconData icon,
    String title, {
    String? subtitle,
    VoidCallback? onTap,
    Color? iconColor,
  }) {
    final finalIconColor = iconColor ?? _petsyNavy;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: finalIconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: finalIconColor, size: 22),
        ),
        title: Text(
          title,
          style: GoogleFonts.inter(
            color: Colors.black87,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: GoogleFonts.inter(color: Colors.black54, fontSize: 12),
              )
            : null,
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 14,
          color: Colors.black45,
        ),
      ),
    );
  }

  Widget _buildDivider() => const Divider(
    height: 1,
    indent: 70,
    endIndent: 20,
    color: Colors.black12,
  );
}

// =============================================================================
// 🚀 LOCAL FUNCTIONAL SCREENS (Replaces the "Under Construction" blockers)
// =============================================================================

class LocalSettingsScreen extends StatefulWidget {
  const LocalSettingsScreen({super.key});
  @override
  State<LocalSettingsScreen> createState() => _LocalSettingsScreenState();
}

class _LocalSettingsScreenState extends State<LocalSettingsScreen> {
  bool notifs = true;
  bool emailPromo = false;
  bool location = true;
  bool faceId = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: Text(
          "Settings",
          style: GoogleFonts.inter(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            "NOTIFICATIONS",
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  activeColor: const Color(0xFF2B8C61),
                  title: Text(
                    "Push Notifications",
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                  value: notifs,
                  onChanged: (v) => setState(() => notifs = v),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  activeColor: const Color(0xFF2B8C61),
                  title: Text(
                    "Email Promotions",
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                  value: emailPromo,
                  onChanged: (v) => setState(() => emailPromo = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          Text(
            "PRIVACY & SECURITY",
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  activeColor: const Color(0xFF2B8C61),
                  title: Text(
                    "Location Services",
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                  value: location,
                  onChanged: (v) => setState(() => location = v),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  activeColor: const Color(0xFF2B8C61),
                  title: Text(
                    "Biometric Login",
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                  value: faceId,
                  onChanged: (v) => setState(() => faceId = v),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class LocalPaymentScreen extends StatelessWidget {
  const LocalPaymentScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: Text(
          "Payment Methods",
          style: GoogleFonts.inter(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.credit_card, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 20),
            Text(
              "No Linked Cards",
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Add a credit card or GCash account to checkout faster.",
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: Colors.grey),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF2B8C61),
        onPressed: () {},
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          "Add Payment",
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class LocalReviewsScreen extends StatelessWidget {
  const LocalReviewsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: Text(
          "My Reviews",
          style: GoogleFonts.inter(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.star_border, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 20),
            Text(
              "No Reviews Yet",
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Items you review will appear here.",
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class LocalHelpScreen extends StatelessWidget {
  const LocalHelpScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: Text(
          "Help Center",
          style: GoogleFonts.inter(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF003466),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Hi there! How can we help?",
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 15),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: "Search for topics...",
                      hintStyle: GoogleFonts.inter(color: Colors.grey),
                      suffixIcon: const Icon(Icons.search, color: Colors.grey),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          Text(
            "FAQ",
            style: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 10),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              children: [
                ListTile(
                  title: Text(
                    "How to track my order?",
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                  trailing: const Icon(Icons.keyboard_arrow_down),
                ),
                const Divider(height: 1),
                ListTile(
                  title: Text(
                    "Return and Refund Policy",
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                  trailing: const Icon(Icons.keyboard_arrow_down),
                ),
                const Divider(height: 1),
                ListTile(
                  title: Text(
                    "How to contact seller?",
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                  trailing: const Icon(Icons.keyboard_arrow_down),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
