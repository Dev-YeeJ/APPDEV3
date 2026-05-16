import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

// --- Ensure these paths match your project ---
import 'package:petsy/features/auth/presentation/screens/sign_in_screen.dart';
import 'package:petsy/features/admin/presentation/screens/manage_products_screen.dart';
// 🚀 NEW IMPORT: Your separated Admin Orders Screen
import 'package:petsy/features/admin/presentation/screens/admin_manage_orders_screen.dart';
import 'package:petsy/features/admin/presentation/screens/admin_chat_list_screen.dart';
import 'package:petsy/providers/chat_provider.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final Color _petsyGreen = const Color(0xFF2B8C61);
  final Color _petsyNavy = const Color(0xFF003466);
  final Color _bgColor = const Color(0xFFF4F6F8);

  Future<void> _adminSignOut() async {
    HapticFeedback.mediumImpact();
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const SignInScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: _petsyNavy,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Admin Dashboard",
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.white,
              ),
            ),
            Text(
              "Petsy Control Center",
              style: GoogleFonts.inter(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _adminSignOut,
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Store Overview",
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: _petsyNavy,
              ),
            ),
            const SizedBox(height: 15),

            // --- LIVE STATS GRID ---
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
              childAspectRatio: 1.1,
              children: [
                _buildLiveStatCard(
                  title: "Total Products",
                  icon: Icons.inventory_2_outlined,
                  color: Colors.blue,
                  stream: FirebaseFirestore.instance
                      .collection('products')
                      .snapshots(),
                ),
                _buildLiveStatCard(
                  title: "Registered Users",
                  icon: Icons.people_outline,
                  color: Colors.orange,
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .snapshots(),
                ),
                // 🚀 GLOBAL ORDERS TRACKER
                _buildLiveStatCard(
                  title: "Total Global Orders",
                  icon: Icons.receipt_long,
                  color: _petsyGreen,
                  stream: FirebaseFirestore.instance
                      .collectionGroup('orders')
                      .snapshots(),
                ),
                _buildLiveStatCard(
                  title: "Pending Shipments",
                  icon: Icons.local_shipping_outlined,
                  color: Colors.purple,
                  stream: FirebaseFirestore.instance
                      .collectionGroup('orders')
                      .where('status', isEqualTo: 'toShip')
                      .snapshots(),
                ),
              ],
            ),

            const SizedBox(height: 30),
            Text(
              "Management Tools",
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: _petsyNavy,
              ),
            ),
            const SizedBox(height: 15),

            // --- ADMIN QUICK ACTIONS ---
            _buildAdminMenuTile(
              title: "Manage Store Products",
              subtitle: "Add, edit, delete, and tag products",
              icon: Icons.shopping_bag_outlined,
              onTap: () {
                HapticFeedback.selectionClick();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ManageProductsScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),

            _buildAdminMenuTile(
              title: "Manage Customer Orders",
              subtitle: "View all purchases and update delivery statuses",
              icon: Icons.local_shipping_outlined,
              onTap: () {
                HapticFeedback.selectionClick();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdminManageOrdersScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),

            // 🚀 CHAT TILE WITH UNREAD BADGE
            FutureBuilder<int>(
              future: context.read<ChatProvider>().getAdminUnreadCount(),
              builder: (context, snapshot) {
                int unreadCount = snapshot.data ?? 0;
                return _buildAdminMenuTile(
                  title: "Customer Support Inbox",
                  subtitle: unreadCount > 0
                      ? "🔴 $unreadCount unread message${unreadCount > 1 ? 's' : ''}"
                      : "Read and reply to live customer messages",
                  icon: Icons.support_agent,
                  badge: unreadCount > 0 ? unreadCount.toString() : null,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AdminChatListScreen(),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
      // --- ADMIN SPECIFIC BOTTOM NAV ---
      bottomNavigationBar: Container(
        height: 70,
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
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildBottomNavItem(Icons.dashboard, "Dashboard", true, () {}),
            _buildBottomNavItem(
              Icons.inventory_2_outlined,
              "Products",
              false,
              () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ManageProductsScreen(),
                  ),
                );
              },
            ),
            _buildBottomNavItem(Icons.receipt_long, "Orders", false, () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdminManageOrdersScreen(),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveStatCard({
    required String title,
    required IconData icon,
    required Color color,
    required Stream<QuerySnapshot> stream,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const Spacer(),
          StreamBuilder<QuerySnapshot>(
            stream: stream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                );
              }
              int count = snapshot.hasData ? snapshot.data!.docs.length : 0;
              return Text(
                "$count",
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Colors.black87,
                ),
              );
            },
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminMenuTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    String? badge,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _petsyGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(icon, color: _petsyGreen, size: 28),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: _petsyNavy,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey.shade400,
                  size: 16,
                ),
              ],
            ),
          ),
          // 🚀 UNREAD BADGE
          if (badge != null)
            Positioned(
              top: -8,
              right: -8,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  badge,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomNavItem(
    IconData icon,
    String label,
    bool isActive,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isActive ? _petsyGreen : Colors.grey.shade500,
            size: 26,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
              color: isActive ? _petsyGreen : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}
