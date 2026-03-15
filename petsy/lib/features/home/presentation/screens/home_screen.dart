import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// --- IMPORTANT IMPORTS ---
import 'package:petsy/features/home/presentation/screens/map_picker_screen.dart';
import 'package:petsy/features/home/presentation/screens/profile_page.dart';
import 'package:petsy/features/home/presentation/screens/product_details_screen.dart';
import 'package:petsy/features/home/presentation/screens/cart_screen.dart';
import 'package:petsy/features/home/presentation/screens/orders_screen.dart'; // 🚀 ADDED REAL ORDERS SCREEN IMPORT

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final User? currentUser = FirebaseAuth.instance.currentUser;

  // Premium Theme Colors
  final Color _petsyGreen = const Color(0xFF2B8C61);
  final Color _petsyNavy = const Color(0xFF003466);
  final Color _appBackground = const Color(0xFFF8F9FA);

  // --- FIREBASE STREAM VARIABLES ---
  Stream<DocumentSnapshot>? _userDataStream;

  late Stream<QuerySnapshot> _bestSellerStream;
  late Stream<QuerySnapshot> _whatsNewStream;
  late Stream<QuerySnapshot> _favoritePicksStream;

  // --- CATEGORIES ---
  final List<Map<String, dynamic>> categories = [
    {"name": "Dog", "image": "assets/images/category_dog.jpg"},
    {"name": "Cat", "image": "assets/images/category_cat.jpg"},
    {"name": "Fish", "image": "assets/images/category_fish.jpg"},
    {"name": "Birds", "image": "assets/images/category_bird.jpg"},
  ];

  @override
  void initState() {
    super.initState();
    _initStreams();
  }

  void _initStreams() {
    if (currentUser != null) {
      _userDataStream = FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .snapshots();
    }
    _bestSellerStream = FirebaseFirestore.instance
        .collection('products')
        .where('isBestSeller', isEqualTo: true)
        .limit(6)
        .snapshots();
    _whatsNewStream = FirebaseFirestore.instance
        .collection('products')
        .where('isNew', isEqualTo: true)
        .limit(6)
        .snapshots();
    _favoritePicksStream = FirebaseFirestore.instance
        .collection('products')
        .where('isFavorite', isEqualTo: true)
        .limit(6)
        .snapshots();
  }

  String _getGreeting() {
    var hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  Future<void> _handleRefresh() async {
    HapticFeedback.lightImpact();
    setState(() {
      _initStreams();
    });
    await Future.delayed(const Duration(seconds: 1));
  }

  // 🌟 LOGICAL FUNCTION: Show Filter Bottom Sheet
  void _openFilterBottomSheet() {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => const FilterBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser != null && _userDataStream == null) {
      _initStreams();
    }

    if (currentUser == null || _userDataStream == null) {
      return const Scaffold(body: Center(child: Text("No user logged in")));
    }

    return Scaffold(
      extendBody: true,
      backgroundColor: _appBackground,

      // --- CUSTOM BOTTOM NAVIGATION BAR ---
      bottomNavigationBar: Container(
        height: 90,
        color: Colors.transparent,
        child: Stack(
          alignment: Alignment.bottomCenter,
          clipBehavior: Clip.none,
          children: [
            Container(
              height: 65,
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildNavItem(Icons.home_outlined, "Home", true),
                _buildNavItem(Icons.shopping_cart_outlined, "Cart", false),
                _buildNavItem(Icons.format_list_bulleted, "Orders", false),
                _buildNavItem(Icons.person_outline, "Profile", false),
              ],
            ),
          ],
        ),
      ),

      // --- MAIN BODY ---
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: _petsyGreen,
          backgroundColor: Colors.white,
          onRefresh: _handleRefresh,
          child: StreamBuilder<DocumentSnapshot>(
            stream: _userDataStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final userData =
                  snapshot.data?.data() as Map<String, dynamic>? ?? {};
              final address =
                  userData['address'] as Map<String, dynamic>? ?? {};
              final String firstName = userData['firstName'] ?? 'Pet Lover';

              final String barangay =
                  address['barangay']?.toString().isNotEmpty == true
                  ? address['barangay']
                  : "Set Location";
              final String city = address['city']?.toString().isNotEmpty == true
                  ? address['city']
                  : "Philippines";

              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 15),

                    // --- 1. MODERN HEADER ---
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "${_getGreeting()}, $firstName!",
                                  style: GoogleFonts.inter(
                                    color: Colors.grey.shade600,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                GestureDetector(
                                  // 🌟 LOGICAL FUNCTION: Open Map
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const MapPickerScreen(),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.location_on,
                                        color: _petsyGreen,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          "$barangay, $city",
                                          style: GoogleFonts.inter(
                                            color: _petsyNavy,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const Icon(
                                        Icons.keyboard_arrow_down,
                                        size: 18,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            // 🌟 LOGICAL FUNCTION: Open Notifications
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const NotificationsScreen(),
                              ),
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.grey.shade200),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.03),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Icon(
                                    Icons.notifications_none_rounded,
                                    color: _petsyNavy,
                                    size: 24,
                                  ),
                                  Positioned(
                                    top: 2,
                                    right: 2,
                                    child: Container(
                                      height: 8,
                                      width: 8,
                                      decoration: BoxDecoration(
                                        color: Colors.redAccent,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 1.5,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 25),

                    // --- 2. MODERN SEARCH BAR ---
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              // 🌟 LOGICAL FUNCTION: Open Search Screen
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SearchScreen(),
                                ),
                              ),
                              child: Container(
                                height: 50,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.grey.shade200,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const SizedBox(width: 15),
                                    Icon(
                                      Icons.search,
                                      color: Colors.grey.shade500,
                                      size: 22,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      "Search food, toys, accessories...",
                                      style: GoogleFonts.inter(
                                        color: Colors.grey.shade400,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            // 🌟 LOGICAL FUNCTION: Open Filters
                            onTap: _openFilterBottomSheet,
                            child: Container(
                              height: 50,
                              width: 50,
                              decoration: BoxDecoration(
                                color: _petsyGreen,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: _petsyGreen.withOpacity(0.3),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.tune,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 25),

                    // --- 3. ISOLATED AUTO-SLIDING PROMO BANNER ---
                    const PromoCarouselWidget(),

                    const SizedBox(height: 25),

                    // --- 4. CATEGORIES ---
                    _buildSectionHeader("Categories", () {
                      // 🌟 LOGICAL FUNCTION: See All Categories
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const GenericProductsScreen(
                            title: "All Categories",
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 15),
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        scrollDirection: Axis.horizontal,
                        itemCount: categories.length,
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            // 🌟 LOGICAL FUNCTION: Open Specific Category
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => GenericProductsScreen(
                                    title:
                                        "${categories[index]["name"]} Products",
                                  ),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.only(right: 20),
                              child: Column(
                                children: [
                                  Container(
                                    height: 65,
                                    width: 65,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: ClipOval(
                                      child: Image.asset(
                                        categories[index]["image"],
                                        fit: BoxFit.cover,
                                        errorBuilder: (c, e, s) => const Icon(
                                          Icons.pets,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    categories[index]["name"],
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: _petsyNavy,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 10),

                    // --- 5. BEST SELLER ---
                    _buildSectionHeader("Best Seller", () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const GenericProductsScreen(
                            title: "Best Sellers",
                          ),
                        ),
                      );
                    }),
                    _buildProductStreamRow(_bestSellerStream),

                    const SizedBox(height: 15),

                    // --- 6. WHAT'S NEW ---
                    _buildSectionHeader("What's New", () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const GenericProductsScreen(title: "What's New"),
                        ),
                      );
                    }),
                    _buildProductStreamRow(_whatsNewStream),

                    const SizedBox(height: 15),

                    // --- 7. PETSY FAVORITE PICKS ---
                    _buildSectionHeader("Petsy Favorite Picks", () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const GenericProductsScreen(
                            title: "Petsy Favorites",
                          ),
                        ),
                      );
                    }),
                    _buildProductStreamRow(_favoritePicksStream),

                    const SizedBox(height: 120),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback onSeeAllTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: _petsyNavy,
              letterSpacing: -0.5,
            ),
          ),
          GestureDetector(
            onTap: onSeeAllTap,
            child: Text(
              "See all",
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: _petsyGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductStreamRow(Stream<QuerySnapshot> stream) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 230,
            child: Center(child: CircularProgressIndicator(strokeWidth: 3)),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return SizedBox(
            height: 100,
            child: Center(
              child: Text(
                "Coming soon!",
                style: GoogleFonts.inter(
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          );
        }

        final products = snapshot.data!.docs;

        return SizedBox(
          height: 240,
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            scrollDirection: Axis.horizontal,
            itemCount: products.length,
            itemBuilder: (context, index) {
              final productData =
                  products[index].data() as Map<String, dynamic>;
              return Padding(
                padding: const EdgeInsets.only(right: 15),
                child: _buildProductCard(productData),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    final rawPrice = product['price']?.toString() ?? '0.00';
    final parsedPrice = double.tryParse(rawPrice) ?? 0.0;
    final price = parsedPrice.toStringAsFixed(2);
    final rating = product['rating']?.toString() ?? '0.0';
    final sold = product['sold']?.toString() ?? '0';
    final imageUrl = product['image']?.toString() ?? '';
    final name = product['name']?.toString() ?? 'Unknown Item';

    Widget productImageWidget() {
      if (imageUrl.isEmpty) return const Icon(Icons.image, color: Colors.grey);
      if (imageUrl.startsWith('http')) {
        return Image.network(
          imageUrl,
          fit: BoxFit.contain,
          errorBuilder: (c, e, s) =>
              const Icon(Icons.image_not_supported, color: Colors.grey),
        );
      }
      return Image.asset(
        imageUrl,
        fit: BoxFit.contain,
        errorBuilder: (c, e, s) =>
            const Icon(Icons.broken_image, color: Colors.grey),
      );
    }

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProductDetailsScreen(product: product),
        ),
      ),
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 15,
              spreadRadius: 2,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    padding: const EdgeInsets.all(12.0),
                    child: Hero(
                      tag: imageUrl.isNotEmpty ? imageUrl : 'product_image',
                      child: productImageWidget(),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Added to Favorites ❤️"),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 5,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.favorite_border,
                          size: 16,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: _petsyNavy,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        "$rating | $sold sold",
                        style: GoogleFonts.inter(
                          color: Colors.grey.shade600,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "₱$price",
                        style: GoogleFonts.inter(
                          color: _petsyGreen,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          letterSpacing: -0.5,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Added $name to cart!"),
                              backgroundColor: _petsyGreen,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: _petsyGreen,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.add_shopping_cart,
                            color: Colors.white,
                            size: 16,
                          ),
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
  }

  // 🌟 LOGICAL FUNCTION: Bottom Nav Routing
  Widget _buildNavItem(IconData icon, String label, bool isActive) {
    return GestureDetector(
      onTap: () {
        if (!isActive) {
          Widget nextScreen;
          if (label == "Profile") {
            nextScreen = const ProfilePage();
          } else if (label == "Cart") {
            nextScreen = const CartScreen();
          } else if (label == "Orders") {
            nextScreen =
                const OrdersScreen(); // 🚀 POINTS TO THE REAL SCREEN NOW
          } else {
            return; // Already on Home
          }

          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  nextScreen,
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                    return FadeTransition(opacity: animation, child: child);
                  },
              transitionDuration: const Duration(milliseconds: 300),
            ),
          );
        }
      },
      child: SizedBox(
        width: 70,
        height: 85,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            if (!isActive)
              Positioned(
                bottom: 12,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: Colors.grey.shade500, size: 26),
                    const SizedBox(height: 2),
                    Text(
                      label,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            if (isActive)
              Positioned(
                top: 0,
                child: Container(
                  height: 60,
                  width: 60,
                  decoration: BoxDecoration(
                    color: _petsyGreen,
                    shape: BoxShape.circle,
                    border: Border.all(color: _appBackground, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: _petsyGreen.withOpacity(0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 28),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class PromoCarouselWidget extends StatefulWidget {
  const PromoCarouselWidget({super.key});

  @override
  State<PromoCarouselWidget> createState() => _PromoCarouselWidgetState();
}

class _PromoCarouselWidgetState extends State<PromoCarouselWidget> {
  final PageController _bannerController = PageController();
  int _currentBannerIndex = 0;
  Timer? _bannerTimer;
  final Color _petsyGreen = const Color(0xFF2B8C61);
  final Color _petsyNavy = const Color(0xFF003466);

  final List<Map<String, dynamic>> _promos = [
    {
      "title": "New User Offer!",
      "mainText": "10% OFF",
      "subText": "for your 1st order",
      "leftImg": "assets/images/promo_1_left.png",
      "rightImg": "assets/images/promo_1_right.png",
    },
    {
      "title": "Save up to",
      "mainText": "₱ 150",
      "subText": "on selected pet toys!",
      "leftImg": "assets/images/promo_2_left.png",
      "rightImg": "assets/images/promo_2_right.png",
    },
    {
      "title": "Smart Cleaning Solution",
      "mainText": "BUY 1 TAKE 1",
      "subText": "Natural pet safe ingredients!",
      "leftImg": "assets/images/promo_3_left.png",
      "rightImg": "assets/images/promo_3_right.png",
    },
  ];

  @override
  void initState() {
    super.initState();
    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (Timer timer) {
      if (_bannerController.hasClients) {
        int nextPage = (_bannerController.page?.round() ?? 0) + 1;
        if (nextPage >= _promos.length) nextPage = 0;
        _bannerController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.fastOutSlowIn,
        );
      }
    });
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _bannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 150,
          child: PageView.builder(
            controller: _bannerController,
            onPageChanged: (index) =>
                setState(() => _currentBannerIndex = index),
            itemCount: _promos.length,
            itemBuilder: (context, index) {
              final promo = _promos[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_petsyGreen, _petsyNavy],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: _petsyNavy.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    children: [
                      Positioned(
                        left: -15,
                        bottom: -10,
                        child: Image.asset(
                          promo["leftImg"],
                          height: 120,
                          fit: BoxFit.contain,
                          errorBuilder: (c, e, s) => const SizedBox(),
                        ),
                      ),
                      Positioned(
                        right: -15,
                        bottom: -10,
                        child: Image.asset(
                          promo["rightImg"],
                          height: 120,
                          fit: BoxFit.contain,
                          errorBuilder: (c, e, s) => const SizedBox(),
                        ),
                      ),
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              promo["title"],
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              promo["mainText"],
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                height: 1.1,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              promo["subText"],
                              style: GoogleFonts.inter(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 12),
                            GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const GenericProductsScreen(
                                        title: "Exclusive Deals",
                                      ),
                                ),
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  "Shop Now",
                                  style: GoogleFonts.inter(
                                    color: _petsyNavy,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _promos.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 6,
              width: _currentBannerIndex == index ? 24 : 8,
              decoration: BoxDecoration(
                color: _currentBannerIndex == index
                    ? _petsyGreen
                    : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// 🌟 FUNCTIONAL SUB-SCREENS 🌟
// ============================================================================

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: TextField(
          autofocus: true,
          decoration: InputDecoration(
            hintText: "Search food, toys, accessories...",
            hintStyle: GoogleFonts.inter(
              color: Colors.grey.shade400,
              fontSize: 14,
            ),
            border: InputBorder.none,
          ),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 80, color: Colors.grey.shade200),
            const SizedBox(height: 20),
            Text(
              "Type to start searching",
              style: GoogleFonts.inter(
                color: Colors.grey.shade500,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FilterBottomSheet extends StatelessWidget {
  const FilterBottomSheet({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Filters",
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF003466),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(),
          ListTile(
            title: Text("Price: Low to High", style: GoogleFonts.inter()),
            leading: const Icon(Icons.arrow_upward),
          ),
          ListTile(
            title: Text("Price: High to Low", style: GoogleFonts.inter()),
            leading: const Icon(Icons.arrow_downward),
          ),
          ListTile(
            title: Text("Top Rated", style: GoogleFonts.inter()),
            leading: const Icon(Icons.star_border),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2B8C61),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Apply Filters",
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          "Notifications",
          style: GoogleFonts.inter(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: const BackButton(color: Colors.black87),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_off_outlined,
              size: 80,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 15),
            Text(
              "You have no new notifications.",
              style: GoogleFonts.inter(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

class GenericProductsScreen extends StatelessWidget {
  final String title;
  const GenericProductsScreen({super.key, required this.title});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          title,
          style: GoogleFonts.inter(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: const BackButton(color: Colors.black87),
      ),
      body: Center(
        child: Text(
          "$title list coming soon!",
          style: GoogleFonts.inter(color: Colors.grey, fontSize: 16),
        ),
      ),
    );
  }
}
