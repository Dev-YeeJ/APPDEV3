import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// --- Ensure these paths match your project ---
import 'package:petsy/features/home/presentation/screens/home_screen.dart';
import 'package:petsy/features/home/presentation/screens/cart_screen.dart';
import 'package:petsy/features/home/presentation/screens/profile_page.dart';
import 'package:petsy/features/home/presentation/screens/product_details_screen.dart';
import 'package:petsy/features/home/presentation/screens/dummy_credit_card_screen.dart';
import 'package:petsy/features/home/presentation/screens/dummy_gcash_screen.dart';
import 'package:petsy/features/home/presentation/screens/customer_chat_screen.dart';

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
  final String paymentMethod;
  final bool isRated; // Added to track if the user has already rated

  Order({
    required this.orderId,
    required this.orderDate,
    required this.status,
    required this.items,
    required this.totalPrice,
    required this.paymentMethod,
    required this.isRated,
  });

  factory Order.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
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

    List<OrderItem> parsedItems = [];
    if (data['items'] != null) {
      parsedItems = (data['items'] as List)
          .map((i) => OrderItem.fromMap(i as Map<String, dynamic>))
          .toList();
    }

    DateTime parsedDate = DateTime.now();
    if (data['orderDate'] != null) {
      parsedDate = (data['orderDate'] as Timestamp).toDate();
    }

    return Order(
      orderId: doc.id,
      orderDate: parsedDate,
      status: parsedStatus,
      items: parsedItems,
      totalPrice: (data['totalPrice'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: data['paymentMethod']?.toString() ?? 'COD',
      isRated: data['isRated'] == true,
    );
  }
}

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});
  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final Color _petsyGreen = const Color(0xFF2B8C61);
  final Color _petsyNavy = const Color(0xFF003466);
  final Color _bgColor = const Color(0xFFF4F6F8);
  final Color _bottomNavBg = const Color(0xFFE2E2E2);

  final User? currentUser = FirebaseAuth.instance.currentUser;

  String _formatPrice(double price) => price.toStringAsFixed(2);

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return "${months[date.month - 1]} ${date.day}, ${date.year}";
  }

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

  // 🚀 ACTION: REAL UPDATE WITH CONFIRMATION DIALOGS
  Future<void> _confirmAndUpdateStatus(
    String orderId,
    String newStatus,
    String title,
    String content,
  ) async {
    HapticFeedback.selectionClick();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          title,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: _petsyNavy,
          ),
        ),
        content: Text(content, style: GoogleFonts.inter(color: Colors.black87)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Go Back",
              style: GoogleFonts.inter(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _petsyGreen,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              Navigator.pop(context);
              if (currentUser == null) return;
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(currentUser!.uid)
                  .collection('orders')
                  .doc(orderId)
                  .update({'status': newStatus});
            },
            child: Text(
              "Confirm",
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🚀 ACTION: PUSH ITEMS TO CART
  Future<void> _buyAgain(Order order) async {
    if (currentUser == null) return;
    HapticFeedback.mediumImpact();

    final cartRef = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser!.uid)
        .collection('cart');

    // Add all items back to the cart
    for (var item in order.items) {
      await cartRef.add({
        'name': item.title,
        'brand': item.brand,
        'image': item.imageUrl,
        'price': item.price,
        'quantity': 1,
        'size': item.size,
        'addedAt': FieldValue.serverTimestamp(),
      });
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 10),
              Text(
                "Items added to Cart!",
                style: GoogleFonts.inter(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          backgroundColor: _petsyGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // 🚀 ACTION: SHOW PREMIUM RATING SHEET
  void _showRatingSheet(String orderId) {
    HapticFeedback.selectionClick();
    int selectedStars = 5;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: const EdgeInsets.all(25),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 5,
                  width: 50,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 25),
                Text(
                  "Rate your experience",
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _petsyNavy,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "How satisfied are you with this order?",
                  style: GoogleFonts.inter(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        setModalState(() => selectedStars = index + 1);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        child: Icon(
                          index < selectedStars
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          color: Colors.amber.shade500,
                          size: 45,
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _petsyGreen,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    onPressed: () async {
                      Navigator.pop(context);
                      if (currentUser != null) {
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(currentUser!.uid)
                            .collection('orders')
                            .doc(orderId)
                            .update({'isRated': true, 'rating': selectedStars});
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text("Thank you for your rating!"),
                              backgroundColor: _petsyGreen,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      }
                    },
                    child: Text(
                      "Submit Review",
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).padding.bottom + 10),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _processPendingPayment(Order order) async {
    bool? success;
    if (order.paymentMethod == 'GCASH') {
      success = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DummyGCashScreen(amountToPay: order.totalPrice),
        ),
      );
    } else if (order.paymentMethod == 'BANK') {
      success = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DummyCreditCardScreen(amountToPay: order.totalPrice),
        ),
      );
    }

    if (success == true && currentUser != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .collection('orders')
          .doc(order.orderId)
          .update({'status': 'toShip'});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Payment Successful! Order is being prepared."),
            backgroundColor: _petsyGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return Scaffold(
        backgroundColor: _bgColor,
        body: const Center(child: Text("Please log in.")),
      );
    }

    return DefaultTabController(
      length: 6,
      child: Scaffold(
        backgroundColor: _bgColor,
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
              color: _petsyNavy,
              letterSpacing: -0.5,
            ),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
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
                  _buildTab("Favorites ❤️"),
                ],
              ),
            ),
          ),
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser!.uid)
              .collection('orders')
              .orderBy('orderDate', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(color: _petsyGreen),
              );
            }

            List<Order> allOrders = [];
            if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
              allOrders = snapshot.data!.docs
                  .map((doc) => Order.fromFirestore(doc))
                  .toList();
            }

            return TabBarView(
              physics: const BouncingScrollPhysics(),
              children: [
                _buildOrderList(
                  allOrders,
                  OrderStatus.toPay,
                  Icons.account_balance_wallet_outlined,
                  "No pending payments!",
                ),
                _buildOrderList(
                  allOrders,
                  OrderStatus.toShip,
                  Icons.inventory_2_outlined,
                  "No orders to ship.",
                ),
                _buildOrderList(
                  allOrders,
                  OrderStatus.toReceive,
                  Icons.local_shipping_outlined,
                  "No incoming parcels.",
                ),
                _buildOrderList(
                  allOrders,
                  OrderStatus.completed,
                  Icons.check_circle_outline,
                  "No completed orders yet.",
                ),
                _buildOrderList(
                  allOrders,
                  OrderStatus.cancelled,
                  Icons.cancel_outlined,
                  "No cancelled orders.",
                ),
                _buildFavoritesTab(currentUser!.uid),
              ],
            );
          },
        ),
        bottomNavigationBar: _buildCustomBottomNav(),
      ),
    );
  }

  Widget _buildOrderList(
    List<Order> allOrders,
    OrderStatus status,
    IconData emptyIcon,
    String emptyMessage,
  ) {
    final filteredOrders = allOrders.where((o) => o.status == status).toList();

    if (filteredOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Icon(emptyIcon, size: 60, color: Colors.grey.shade300),
            ),
            const SizedBox(height: 20),
            Text(
              emptyMessage,
              style: GoogleFonts.inter(
                color: Colors.grey.shade500,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      physics: const BouncingScrollPhysics(),
      itemCount: filteredOrders.length,
      itemBuilder: (context, index) => _buildOrderCard(filteredOrders[index]),
    );
  }

  Widget _buildOrderCard(Order order) {
    final truncatedId = order.orderId.length > 8
        ? order.orderId.substring(0, 8).toUpperCase()
        : order.orderId.toUpperCase();
    final statusColor = _getStatusColor(order.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.storefront, color: _petsyNavy, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      "Petsy Official Store",
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        color: _petsyNavy,
                        fontSize: 13,
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
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _getStatusText(order.status),
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade100),

          Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              children: order.items
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 75,
                            width: 75,
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: item.imageUrl.startsWith('http')
                                ? Image.network(item.imageUrl)
                                : Image.asset(
                                    item.imageUrl,
                                    errorBuilder: (c, e, s) =>
                                        const Icon(Icons.image),
                                  ),
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
                                const SizedBox(height: 4),
                                Text(
                                  "${item.brand} • ${item.size}",
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "₱ ${_formatPrice(item.price)}",
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    Text(
                                      "x${item.quantity}",
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey.shade600,
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
                  )
                  .toList(),
            ),
          ),

          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: const Color(0xFFFDFDFD),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${order.items.length} items • Order #$truncatedId",
                          style: GoogleFonts.inter(
                            color: Colors.grey.shade500,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatDate(order.orderDate),
                          style: GoogleFonts.inter(
                            color: Colors.grey.shade400,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          "Total: ",
                          style: GoogleFonts.inter(
                            color: Colors.black87,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          "₱ ${_formatPrice(order.totalPrice)}",
                          style: GoogleFonts.inter(
                            color: _petsyGreen,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                if (order.status != OrderStatus.cancelled) ...[
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // 🚀 CHAT WITH SELLER (Always available except cancelled)
                      _buildOutlinedButton("Chat", () {
                        HapticFeedback.selectionClick();
                        String summary = order.items.isNotEmpty
                            ? order.items.first.title
                            : "Petsy Items";
                        if (order.items.length > 1) {
                          summary += " (+${order.items.length - 1} more)";
                        }

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CustomerChatScreen(
                              orderId: order.orderId,
                              orderSummary: summary,
                            ),
                          ),
                        );
                      }, _petsyGreen),

                      // CANCEL BUTTON
                      if (order.status == OrderStatus.toPay ||
                          order.status == OrderStatus.toShip) ...[
                        const SizedBox(width: 10),
                        _buildOutlinedButton(
                          "Cancel Order",
                          () => _confirmAndUpdateStatus(
                            order.orderId,
                            'cancelled',
                            "Cancel Order",
                            "Are you sure you want to cancel this order? This action cannot be undone.",
                          ),
                          Colors.grey.shade600,
                        ),
                      ],

                      // PAY NOW
                      if (order.status == OrderStatus.toPay &&
                          order.paymentMethod != 'COD') ...[
                        const SizedBox(width: 10),
                        _buildSolidButton(
                          "Pay Now",
                          () => _processPendingPayment(order),
                          _petsyGreen,
                        ),
                      ],

                      // ORDER RECEIVED
                      if (order.status == OrderStatus.toReceive) ...[
                        const SizedBox(width: 10),
                        _buildSolidButton(
                          "Order Received",
                          () => _confirmAndUpdateStatus(
                            order.orderId,
                            'completed',
                            "Confirm Delivery",
                            "Have you received all items in good condition?",
                          ),
                          _petsyGreen,
                        ),
                      ],

                      // COMPLETED ACTIONS
                      if (order.status == OrderStatus.completed) ...[
                        if (!order.isRated)
                          _buildOutlinedButton(
                            "Rate",
                            () => _showRatingSheet(order.orderId),
                            Colors.amber.shade700,
                          ),
                        const SizedBox(width: 10),
                        _buildSolidButton(
                          "Buy Again",
                          () => _buyAgain(order),
                          _petsyGreen,
                        ),
                      ],
                    ],
                  ),
                ],
                // CANCELLED ACTION
                if (order.status == OrderStatus.cancelled) ...[
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _buildSolidButton(
                        "Buy Again",
                        () => _buyAgain(order),
                        _petsyGreen,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSolidButton(String text, VoidCallback onTap, Color color) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        minimumSize: const Size(0, 36),
      ),
      onPressed: onTap,
      child: Text(
        text,
        style: GoogleFonts.inter(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildOutlinedButton(String text, VoidCallback onTap, Color color) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: color.withOpacity(0.5), width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        minimumSize: const Size(0, 36),
      ),
      onPressed: onTap,
      child: Text(
        text,
        style: GoogleFonts.inter(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildFavoritesTab(String uid) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('favorites')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: _petsyGreen));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.favorite_border,
                    size: 60,
                    color: Colors.grey.shade300,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "No favorites yet!",
                  style: GoogleFonts.inter(
                    color: Colors.grey.shade500,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        }

        final favoriteItems = snapshot.data!.docs;

        return GridView.builder(
          padding: const EdgeInsets.all(20),
          physics: const BouncingScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.65,
            crossAxisSpacing: 15,
            mainAxisSpacing: 15,
          ),
          itemCount: favoriteItems.length,
          itemBuilder: (context, index) {
            final product = favoriteItems[index].data() as Map<String, dynamic>;
            final rawPrice = product['price']?.toString() ?? '0.00';
            final parsedPrice = double.tryParse(rawPrice) ?? 0.0;
            final price = parsedPrice.toStringAsFixed(2);
            final imageUrl = product['image']?.toString() ?? '';
            final name = product['name']?.toString() ?? 'Unknown Item';

            return GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProductDetailsScreen(product: product),
                ),
              ),
              child: Container(
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
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12.0),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                        ),
                        child: imageUrl.startsWith('http')
                            ? Image.network(imageUrl, fit: BoxFit.contain)
                            : Image.asset(
                                imageUrl,
                                fit: BoxFit.contain,
                                errorBuilder: (c, e, s) =>
                                    const Icon(Icons.image),
                              ),
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
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "₱$price",
                            style: GoogleFonts.inter(
                              color: _petsyGreen,
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
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
        );
      },
    );
  }

  Widget _buildActionCircle(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: CircleAvatar(
        backgroundColor: Colors.white,
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
                _buildNavItem(Icons.person_outline, "Profile", false, () {
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
}
