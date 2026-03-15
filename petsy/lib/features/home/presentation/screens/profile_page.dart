import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

import 'package:petsy/features/home/presentation/screens/edit_profile_screen.dart';
import 'package:petsy/features/home/presentation/screens/home_screen.dart';
import 'package:petsy/features/auth/presentation/screens/sign_in_screen.dart';
// Make sure this path matches where you saved the new admin screen!
import 'package:petsy/features/admin/presentation/screens/manage_products_screen.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final User? currentUser = FirebaseAuth.instance.currentUser;

  // Theme Colors
  final Color _petsyGreen = const Color(0xFF339967);
  final Color _petsyNavy = const Color(0xFF003466);
  final Color _lightGray = const Color(0xFFF8F9FA);

  Future<void> _signOut() async {
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
    if (userData['address'] != null && userData['address']['region'] != null) {
      score += 0.25;
    }
    return score;
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return const Scaffold(body: Center(child: Text("No user logged in")));
    }

    return Scaffold(
      extendBody: true,
      backgroundColor: _lightGray,

      // --- REVISED CUSTOM NAVIGATION BAR ---
      bottomNavigationBar: Container(
        height: 90, // Total height to allow the active circle to pop out
        color: Colors.transparent,
        child: Stack(
          alignment: Alignment.bottomCenter, // Automatically anchors to bottom
          clipBehavior: Clip.none,
          children: [
            // 1. Solid Gray Background Bar
            Container(
              height: 65, // Height of the gray area
              color: const Color(0xFFD9D9D9),
            ),

            // 2. Navigation Items
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildNavItem(Icons.home_outlined, "Home", false),
                _buildNavItem(Icons.shopping_cart_outlined, "Cart", false),
                _buildNavItem(Icons.format_list_bulleted, "Orders", false),
                _buildNavItem(
                  Icons.person_outline,
                  "Profile",
                  true,
                ), // Active Item
              ],
            ),
          ],
        ),
      ),

      // --- MAIN BODY ---
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
            return const Center(child: Text("Error loading profile"));
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

          // 👇 THE MAGIC ADMIN CHECK 👇
          final bool isAdmin = userData['isAdmin'] == true;

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
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
                                    IconButton(
                                      icon: const Icon(
                                        Icons.chat_bubble_outline,
                                        color: Colors.white,
                                      ),
                                      onPressed: () {},
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                    const SizedBox(width: 15),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.settings_outlined,
                                        color: Colors.white,
                                      ),
                                      onPressed: () {},
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 10),

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
                            Container(
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
                          ],
                        ),
                        const SizedBox(height: 15),
                        Text(
                          fullName.isEmpty ? "User" : fullName,
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
                                    _buildStatItem("29", "Followers"),
                                    Container(
                                      height: 40,
                                      width: 1,
                                      color: Colors.white.withOpacity(0.3),
                                    ),
                                    _buildStatItem("40", "Following"),
                                    Container(
                                      height: 40,
                                      width: 1,
                                      color: Colors.white.withOpacity(0.3),
                                    ),
                                    _buildStatItem("102", "Orders"),
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
                          child: LinearProgressIndicator(
                            value: completionScore,
                            backgroundColor: Colors.grey.shade300,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _petsyGreen,
                            ),
                            minHeight: 8,
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
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      EditProfileScreen(userData: userData),
                                ),
                              ),
                              icon: const Icon(
                                Icons.edit_outlined,
                                color: Colors.white,
                                size: 18,
                              ),
                              label: const Text(
                                "Edit Profile",
                                style: TextStyle(
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
                                style: TextStyle(
                                  color: _petsyGreen,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 30),

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
                            ),
                            _buildDivider(),
                            _buildMenuTile(
                              Icons.location_on_outlined,
                              "Shipping Addresses",
                              subtitle: "Manage delivery locations",
                            ),
                            _buildDivider(),
                            _buildMenuTile(
                              Icons.credit_card_outlined,
                              "Payment Methods",
                              subtitle: "Visa, GCash, Maya",
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
                            ),
                            _buildDivider(),
                            _buildMenuTile(
                              Icons.security_outlined,
                              "Privacy & Security",
                            ),
                            _buildDivider(),
                            _buildMenuTile(Icons.help_outline, "Help Center"),
                          ],
                        ),
                      ),

                      // --- 🛡️ ADMIN CONTROLS SECTION 🛡️ ---
                      // This section will ONLY build if the logged in user has isAdmin: true in Firebase
                      if (isAdmin) ...[
                        const SizedBox(height: 25),
                        Text(
                          "Admin Controls",
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.orange.shade200,
                              width: 1.5,
                            ),
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
                                Icons.inventory_2_outlined,
                                "Manage Store Products",
                                subtitle: "Add, upload, and edit items",
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const ManageProductsScreen(),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],

                      // ----------------------------------------
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

                      const SizedBox(
                        height: 120,
                      ), // Extra padding to scroll past the new nav bar
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

  // Helper Widget for Bottom Nav Bar Items
  Widget _buildNavItem(IconData icon, String label, bool isActive) {
    return GestureDetector(
      onTap: () {
        if (!isActive) {
          if (label == "Home") {
            Navigator.pushReplacement(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    const HomeScreen(),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                      return FadeTransition(opacity: animation, child: child);
                    },
                transitionDuration: const Duration(milliseconds: 300),
              ),
            );
          }
          // Add logic for Cart and Orders later
        }
      },
      child: SizedBox(
        width: 70,
        height: 85, // Total height to accommodate the circle pop-up
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            // Inactive State (Icon + Text)
            if (!isActive)
              Positioned(
                bottom: 12,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: Colors.black87, size: 26),
                    const SizedBox(height: 2),
                    Text(
                      label,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            // Active State (Green Circle pop-up)
            if (isActive)
              Positioned(
                top: 0, // Pushes it out of the gray box
                child: Container(
                  height: 60,
                  width: 60,
                  decoration: BoxDecoration(
                    color: _petsyGreen,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: Icon(icon, color: Colors.white, size: 30),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String number, String label) {
    return Column(
      children: [
        Text(
          number,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.inter(
            color: Colors.white.withOpacity(0.8),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuTile(
    IconData icon,
    String title, {
    String? subtitle,
    VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: _lightGray,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: _petsyNavy, size: 22),
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
      trailing: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.arrow_forward_ios,
          size: 14,
          color: Colors.black45,
        ),
      ),
      onTap: onTap,
    );
  }

  Widget _buildDivider() => const Divider(
    height: 1,
    indent: 70,
    endIndent: 20,
    color: Colors.black12,
  );
}
