import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// --- Ensure these paths match your project ---
import 'package:petsy/features/home/presentation/screens/home_screen.dart';
import 'package:petsy/features/home/presentation/screens/cart_screen.dart';
import 'package:petsy/features/home/presentation/screens/profile_page.dart';

// --- DATA MODELS ---
enum OrderStatus { toPay, toShip, toReceive, completed, cancelled }

class OrderItem {
  final String imageUrl;
  final String title;
  final String brand;
  final String size;
  final double price;
  final int quantity;

  OrderItem({
    required this.imageUrl,
    required this.title,
    required this.brand,
    required this.size,
    required this.price,
    required this.quantity,
  });

  // Safely parse from Firebase Map
  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      imageUrl: map['image'] ?? '',
      title: map['name'] ?? 'Unknown Item',
      brand: map['brand'] ?? 'Petsy',
      size: map['size'] ?? 'Standard',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      quantity: map['quantity'] as int? ?? 1,
    );
  }
}

class Order {
  final String orderId;
  final DateTime orderDate;
  final OrderStatus status;
  final List<OrderItem> items;
  final double totalPrice;

  Order({
    required this.orderId,
    required this.orderDate,
    required this.status,
    required this.items,
    required this.totalPrice,
  });

  // Safely parse from Firebase Document
  factory Order.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // 1. Parse Status String to Enum
    OrderStatus parsedStatus = OrderStatus.toPay;
    switch (data['status']) {
      case 'toShip':
        parsedStatus = OrderStatus.toShip;
        break;
      case 'toReceive':
        parsedStatus = OrderStatus.toReceive;
        break;
      case 'completed':
        parsedStatus = OrderStatus.completed;
        break;
      case 'cancelled':
        parsedStatus = OrderStatus.cancelled;
        break;
    }

    // 2. Parse Items List
    List<OrderItem> parsedItems = [];
    if (data['items'] != null) {
      parsedItems = (data['items'] as List)
          .map((i) => OrderItem.fromMap(i as Map<String, dynamic>))
          .toList();
    }

    // 3. Parse Date safely
    DateTime parsedDate = DateTime.now();
    if (data['orderDate'] != null) {
      parsedDate = (data['orderDate'] as Timestamp).toDate();
    }

    return Order(
      orderId: doc.id, // We use the Firebase Document ID as the Order ID
      orderDate: parsedDate,
      status: parsedStatus,
      items: parsedItems,
      totalPrice: (data['totalPrice'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  // --- EXACT MOCKUP COLORS ---
  final Color _petsyGreen = const Color(0xFF2B8C61);
  final Color _petsyNavy = const Color(0xFF003466);
  final Color _bgColor = const Color(0xFFF9F9FB);
  final Color _bottomNavBg = const Color(0xFFE2E2E2);

  String _formatPrice(double price) => price.toStringAsFixed(2);

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.toPay:
        return Colors.orange.shade700;
      case OrderStatus.toShip:
        return Colors.blue.shade600;
      case OrderStatus.toReceive:
        return Colors.purple.shade600;
      case OrderStatus.completed:
        return _petsyGreen;
      case OrderStatus.cancelled:
        return Colors.red.shade600;
    }
  }

  String _getStatusText(OrderStatus status) {
    switch (status) {
      case OrderStatus.toPay:
        return 'To Pay';
      case OrderStatus.toShip:
        return 'To Ship';
      case OrderStatus.toReceive:
        return 'To Receive';
      case OrderStatus.completed:
        return 'Completed';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        backgroundColor: _bgColor,
        body: Center(
          child: Text(
            "Please log in to view orders.",
            style: GoogleFonts.inter(color: Colors.grey),
          ),
        ),
        bottomNavigationBar: _buildCustomBottomNav(),
      );
    }

    return DefaultTabController(
      length: 5, // Added Cancelled tab for completeness
      child: Scaffold(
        backgroundColor: _bgColor,

        // --- APP BAR ---
        appBar: AppBar(
          backgroundColor: _bgColor,
          elevation: 0,
          scrolledUnderElevation: 0,
          leadingWidth: 70,
          leading: Padding(
            padding: const EdgeInsets.only(left: 20, top: 8, bottom: 8),
            child: _buildActionCircle(
              Icons.arrow_back,
              () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const HomeScreen()),
              ),
            ),
          ),
          title: Text(
            "Purchases",
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Colors.black87,
            ),
          ),
          centerTitle: false,
          actions: [
            _buildActionCircle(Icons.search, () {}),
            const SizedBox(width: 10),
            _buildActionCircle(Icons.notifications_none_outlined, () {}),
            const SizedBox(width: 20),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                dividerColor: Colors.transparent,
                indicator: BoxDecoration(
                  color: _petsyGreen,
                  borderRadius: BorderRadius.circular(20),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: Colors.black87,
                labelStyle: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                unselectedLabelStyle: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                indicatorPadding: EdgeInsets.zero,
                labelPadding: const EdgeInsets.symmetric(horizontal: 5),
                tabs: [
                  _buildTab("To Pay"),
                  _buildTab("To Ship"),
                  _buildTab("To Receive"),
                  _buildTab("Completed"),
                  _buildTab("Cancelled"),
                ],
              ),
            ),
          ),
        ),

        // --- 🚀 FIREBASE STREAM BODY 🚀 ---
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('orders')
              .orderBy('orderDate', descending: true) // Newest first
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(color: _petsyGreen),
              );
            }

            // Parse all orders from Firebase
            List<Order> allOrders = [];
            if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
              allOrders = snapshot.data!.docs
                  .map((doc) => Order.fromFirestore(doc))
                  .toList();
            }

            // Pass the full list to each tab to be filtered locally
            return TabBarView(
              physics: const BouncingScrollPhysics(),
              children: [
                _buildOrderList(allOrders, OrderStatus.toPay),
                _buildOrderList(allOrders, OrderStatus.toShip),
                _buildOrderList(allOrders, OrderStatus.toReceive),
                _buildOrderList(allOrders, OrderStatus.completed),
                _buildOrderList(allOrders, OrderStatus.cancelled),
              ],
            );
          },
        ),

        // --- CUSTOM BOTTOM NAVIGATION BAR ---
        bottomNavigationBar: _buildCustomBottomNav(),
      ),
    );
  }

  // --- UI HELPER WIDGETS ---

  Widget _buildActionCircle(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: CircleAvatar(
        backgroundColor: const Color(0xFFEFEFEF),
        child: Icon(icon, color: Colors.black87, size: 20),
      ),
    );
  }

  Widget _buildTab(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      height: 35,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _petsyGreen, width: 1.5),
      ),
      child: Center(child: Text(text)),
    );
  }

  Widget _buildOrderList(List<Order> allOrders, OrderStatus status) {
    // Filter the full list based on the tab's status
    final filteredOrders = allOrders.where((o) => o.status == status).toList();

    if (filteredOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 60,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 15),
            Text(
              "No orders found",
              style: GoogleFonts.inter(
                color: Colors.grey.shade600,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      itemCount: filteredOrders.length,
      itemBuilder: (context, index) {
        final order = filteredOrders[index];
        return _buildOrderCard(order);
      },
    );
  }

  Widget _buildOrderCard(Order order) {
    // Format Date: e.g. "Oct 28, 2023 - 14:30"
    final dateStr =
        "${order.orderDate.day}/${order.orderDate.month}/${order.orderDate.year}";
    final truncatedId = order.orderId.length > 8
        ? order.orderId.substring(0, 8).toUpperCase()
        : order.orderId.toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
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
        children: [
          // Order Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Order #$truncatedId",
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dateStr,
                    style: GoogleFonts.inter(
                      color: Colors.grey.shade500,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor(order.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _getStatusText(order.status),
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    color: _getStatusColor(order.status),
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 25),

          // Order Items
          ...order.items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    height: 70,
                    width: 70,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F6F8),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: _buildProductImage(item.imageUrl),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.brand,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _petsyGreen,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "Size: ${item.size}",
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "₱ ${_formatPrice(item.price)}",
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                color: Colors.black87,
                              ),
                            ),
                            Text(
                              "${item.quantity} pcs",
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
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
          ),

          const Divider(height: 20),

          // Order Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "${order.items.length} items",
                style: GoogleFonts.inter(
                  color: Colors.grey.shade600,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Row(
                children: [
                  Text(
                    "Total: ",
                    style: GoogleFonts.inter(
                      color: Colors.black87,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    "₱ ${_formatPrice(order.totalPrice)}",
                    style: GoogleFonts.inter(
                      color: _petsyGreen,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductImage(String imageUrl) {
    if (imageUrl.isEmpty) return const Icon(Icons.image, color: Colors.grey);
    if (imageUrl.startsWith('http'))
      return Image.network(
        imageUrl,
        fit: BoxFit.contain,
        errorBuilder: (c, e, s) =>
            const Icon(Icons.image_not_supported, color: Colors.grey),
      );
    return Image.asset(
      imageUrl,
      fit: BoxFit.contain,
      errorBuilder: (c, e, s) =>
          const Icon(Icons.broken_image, color: Colors.grey),
    );
  }

  // --- CUSTOM BOTTOM NAVIGATION BAR ---
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
                  () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                  ),
                ),
                _buildNavItem(
                  Icons.shopping_cart_outlined,
                  "Cart",
                  () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const CartScreen()),
                  ),
                ),

                // 🚀 RAISED GREEN ORDERS ICON 🚀
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
                    Icons.format_list_bulleted,
                    color: Colors.white,
                    size: 28,
                  ),
                ),

                _buildNavItem(Icons.person_outline, "Profile", () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfilePage()),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, VoidCallback onTap) {
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
}
