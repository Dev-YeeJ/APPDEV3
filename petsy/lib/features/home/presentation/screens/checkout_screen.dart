import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

// --- Ensure these paths match your project structure ---
import 'package:petsy/features/home/presentation/screens/home_screen.dart';
import 'package:petsy/providers/cart_provider.dart';

// 🚀 IMPORTS FOR THE DUMMY PAYMENT SCREENS
import 'package:petsy/features/home/presentation/screens/dummy_credit_card_screen.dart';
import 'package:petsy/features/home/presentation/screens/dummy_gcash_screen.dart';

// 🚀 CHAT IMPORT
import 'package:petsy/features/home/presentation/screens/customer_chat_list_screen.dart';

class CheckoutScreen extends StatefulWidget {
  final List<Map<String, dynamic>> checkoutItems;

  const CheckoutScreen({super.key, required this.checkoutItems});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  // --- EXACT MOCKUP COLORS ---
  final Color _petsyGreen = const Color(0xFF2B8C61);
  final Color _petsyNavy = const Color(0xFF003466);
  final Color _bgColor = const Color(0xFFF4F6F8);

  // --- FIREBASE VARIABLES ---
  final User? currentUser = FirebaseAuth.instance.currentUser;
  Stream<DocumentSnapshot>? _userDataStream;

  // --- LOGIC VARIABLES ---
  final double _shippingFee = 50.00;
  String _selectedPaymentMethod = 'COD';
  final TextEditingController _noteController = TextEditingController();
  bool _isPlacingOrder = false;

  @override
  void initState() {
    super.initState();
    if (currentUser != null) {
      _userDataStream = FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .snapshots();
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  String _formatPrice(double price) => price.toStringAsFixed(2);

  // 🚀 THE MAGIC BRIDGE: Place Order to Firebase & Handle Fake Payments
  Future<void> _placeOrder() async {
    HapticFeedback.heavyImpact();

    double subtotal = 0.0;
    for (var item in widget.checkoutItems) {
      subtotal += (item['unitPrice'] as double) * (item['quantity'] as int);
    }
    final double total = subtotal + _shippingFee;

    // 🌟 INTERCEPT THE ORDER IF THEY SELECTED "BANK" (Credit Card)
    if (_selectedPaymentMethod == 'BANK') {
      final bool? paymentSuccess = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DummyCreditCardScreen(amountToPay: total),
        ),
      );
      // If they hit the back button without paying, stop the checkout process!
      if (paymentSuccess != true) {
        return;
      }
    }
    // 🌟 INTERCEPT THE ORDER IF THEY SELECTED "GCASH"
    else if (_selectedPaymentMethod == 'GCASH') {
      final bool? paymentSuccess = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DummyGCashScreen(amountToPay: total),
        ),
      );
      // If they hit the back button without paying, stop the checkout process!
      if (paymentSuccess != true) {
        return;
      }
    }

    // If it's COD, or if the digital payment was successful, continue placing the order:
    setState(() => _isPlacingOrder = true);

    try {
      if (currentUser != null) {
        // Build the Order Data exactly how OrdersScreen expects it
        final orderData = {
          'orderDate': FieldValue.serverTimestamp(),
          'status': 'toPay', // Defaults to 'To Pay' tab!
          'totalPrice': total,
          'paymentMethod': _selectedPaymentMethod,
          'note': _noteController.text.trim(),
          'items': widget.checkoutItems
              .map(
                (item) => {
                  'image': item['product']['image'] ?? '',
                  'name': item['product']['name'] ?? 'Unknown Item',
                  'brand': item['product']['brand'] ?? 'Petsy',
                  'size': item['selectedSize'],
                  'price': item['unitPrice'],
                  'quantity': item['quantity'],
                },
              )
              .toList(),
        };

        // Save it to the user's "orders" collection in Firebase
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser!.uid)
            .collection('orders')
            .add(orderData);

        // Empty the Cart (Since they just bought it!)
        if (mounted) {
          context.read<CartProvider>().clearCart();
        }
      }

      // Show the Success Modal
      if (mounted) {
        setState(() => _isPlacingOrder = false);
        _showSuccessModal();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isPlacingOrder = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error placing order: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showSuccessModal() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => TweenAnimationBuilder(
        duration: const Duration(milliseconds: 400),
        tween: Tween<double>(begin: 0.8, end: 1.0),
        curve: Curves.easeOutBack,
        builder: (context, double scale, child) {
          return Transform.scale(
            scale: scale,
            child: AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              contentPadding: const EdgeInsets.all(30),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _petsyGreen.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_circle,
                      color: _petsyGreen,
                      size: 70,
                    ),
                  ),
                  const SizedBox(height: 25),
                  Text(
                    "Order Placed!",
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: _petsyNavy,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Your order has been successfully placed and is now being processed.",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 35),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _petsyGreen,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () {
                        // Take them back home
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const HomeScreen(),
                          ),
                          (route) => false,
                        );
                      },
                      child: Text(
                        "Back to Home",
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 16,
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
    );
  }

  Widget _buildProductImage(String imageUrl) {
    if (imageUrl.isEmpty) return const Icon(Icons.image, color: Colors.grey);
    if (imageUrl.startsWith('http')) {
      return Image.network(imageUrl, fit: BoxFit.contain);
    }
    return Image.asset(imageUrl, fit: BoxFit.contain);
  }

  @override
  Widget build(BuildContext context) {
    double subtotal = 0.0;
    int totalQuantity = 0;
    for (var item in widget.checkoutItems) {
      subtotal += (item['unitPrice'] as double) * (item['quantity'] as int);
      totalQuantity += (item['quantity'] as int);
    }
    final double total = subtotal + _shippingFee;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: _bgColor,

        // --- PREMIUM APP BAR ---
        appBar: AppBar(
          backgroundColor: _bgColor,
          elevation: 0,
          scrolledUnderElevation: 0,
          toolbarHeight: 70,
          leading: Padding(
            padding: const EdgeInsets.only(left: 15),
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.arrow_back, color: Colors.black87, size: 20),
              ),
            ),
          ),
          title: Text(
            "Checkout",
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: _petsyNavy,
              letterSpacing: -0.5,
            ),
          ),
          centerTitle: true,
          actions: [
            // 🚀 SUPPORT CHAT BUTTON
            Padding(
              padding: const EdgeInsets.only(right: 20),
              child: GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CustomerChatListScreen(),
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
                  child: Icon(
                    Icons.forum_outlined,
                    color: _petsyNavy,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),

        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- 1. DYNAMIC SHIPPING ADDRESS CARD ---
                    StreamBuilder<DocumentSnapshot>(
                      stream: _userDataStream,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return _buildLoadingAddressCard();
                        }

                        final userData =
                            snapshot.data?.data() as Map<String, dynamic>? ??
                            {};
                        final address =
                            userData['address'] as Map<String, dynamic>? ?? {};

                        final String fullName =
                            "${userData['firstName'] ?? 'Pet'} ${userData['lastName'] ?? 'Lover'}";
                        final String phone =
                            userData['phone'] ?? '+63 (Not Set)';
                        final String street =
                            address['street'] ?? 'Street not set';
                        final String barangay =
                            address['barangay'] ?? 'Barangay';
                        final String city = address['city'] ?? 'City';
                        final String fullAddress = "$street, $barangay, $city";

                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _petsyGreen.withOpacity(0.3),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.02),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.location_on,
                                        color: _petsyGreen,
                                        size: 22,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        "Delivery Address",
                                        style: GoogleFonts.inter(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          color: _petsyNavy,
                                        ),
                                      ),
                                    ],
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      HapticFeedback.selectionClick();
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            "Edit address coming soon!",
                                          ),
                                        ),
                                      );
                                    },
                                    child: Text(
                                      "Change",
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: _petsyGreen,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 15),
                              Text(
                                fullName,
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                phone,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                fullAddress,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: Colors.grey.shade800,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 25),

                    // --- 2. ORDER ITEM CARDS ---
                    Text(
                      "Order Details",
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: _petsyNavy,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...widget.checkoutItems.map((item) {
                      final String name =
                          item['product']['name'] ?? 'Product Name';
                      final String imageUrl = item['product']['image'] ?? '';
                      final String brand =
                          item['product']['brand'] ?? 'Petsy Partner';
                      final String selectedFlavor =
                          item['selectedFlavor'] ?? '';
                      final String selectedSize = item['selectedSize'] ?? '';
                      final double unitPrice = item['unitPrice'] as double;
                      final int quantity = item['quantity'] as int;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 15),
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 80,
                              width: 80,
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: _buildProductImage(imageUrl),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.black87,
                                      letterSpacing: -0.5,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "$brand • $selectedFlavor, $selectedSize",
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: Colors.grey.shade500,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "₱ ${_formatPrice(unitPrice)}",
                                        style: GoogleFonts.inter(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900,
                                          color: _petsyGreen,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _bgColor,
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: Text(
                                          "Qty: $quantity",
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
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
                      );
                    }),
                    const SizedBox(height: 10),

                    // --- 3. DELIVERY & NOTES ---
                    Text(
                      "Delivery Options",
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: _petsyNavy,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.local_shipping_outlined,
                                    color: _petsyGreen,
                                    size: 22,
                                  ),
                                  const SizedBox(width: 10),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Standard Delivery",
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          color: Colors.black87,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        "J&T Express (2-3 Days)",
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Text(
                                "₱ ${_formatPrice(_shippingFee)}",
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 15),
                            child: Divider(height: 1, color: Colors.black12),
                          ),
                          Row(
                            children: [
                              Icon(
                                Icons.edit_note,
                                color: Colors.grey.shade500,
                                size: 22,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextField(
                                  controller: _noteController,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: "Leave a note for the seller...",
                                    hintStyle: GoogleFonts.inter(
                                      color: Colors.grey.shade400,
                                      fontSize: 14,
                                    ),
                                    border: InputBorder.none,
                                    isDense: true,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),

                    // --- 4. PAYMENT METHOD CARDS ---
                    Text(
                      "Payment Method",
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: _petsyNavy,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 100,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        clipBehavior: Clip.none,
                        children: [
                          _buildPaymentCard(
                            id: 'COD',
                            title: 'Cash on Delivery',
                            subtitle: 'Pay when you receive',
                            icon: Icons.money,
                          ),
                          const SizedBox(width: 15),
                          _buildPaymentCard(
                            id: 'GCASH',
                            title: 'GCash',
                            subtitle: 'E-Wallet Transfer',
                            icon: Icons.account_balance_wallet,
                          ),
                          const SizedBox(width: 15),
                          _buildPaymentCard(
                            id: 'BANK',
                            title: 'Credit Card',
                            subtitle: 'Visa / Mastercard',
                            icon: Icons.credit_card,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),

                    // --- 5. BILLING SUMMARY ---
                    Text(
                      "Billing Summary",
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: _petsyNavy,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildSummaryRow(
                            "Subtotal ($totalQuantity items)",
                            "₱${_formatPrice(subtotal)}",
                            isBold: false,
                          ),
                          const SizedBox(height: 12),
                          _buildSummaryRow(
                            "Shipping Fee",
                            "₱${_formatPrice(_shippingFee)}",
                            isBold: false,
                          ),
                          const SizedBox(height: 15),
                          // Custom Dashed Divider
                          Row(
                            children: List.generate(
                              150 ~/ 3,
                              (index) => Expanded(
                                child: Container(
                                  color: index % 2 == 0
                                      ? Colors.transparent
                                      : Colors.grey.shade300,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 15),
                          _buildSummaryRow(
                            "Total Payment",
                            "₱${_formatPrice(total)}",
                            isBold: true,
                            isTotal: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),

            // --- 6. BOTTOM FIXED CHECKOUT BAR ---
            Container(
              padding: const EdgeInsets.fromLTRB(25, 15, 25, 30),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, -10),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Total Amount",
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        "₱ ${_formatPrice(total)}",
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: _petsyNavy,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 55,
                    width: 170,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _petsyGreen,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      onPressed: _isPlacingOrder ? null : _placeOrder,
                      child: _isPlacingOrder
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            )
                          : Text(
                              "Place Order",
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
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
  }

  // --- UI HELPER: PAYMENT CARDS ---
  Widget _buildPaymentCard({
    required String id,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    bool isSelected = _selectedPaymentMethod == id;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedPaymentMethod = id);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 150,
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: isSelected ? _petsyNavy : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? _petsyNavy : Colors.grey.shade300,
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: _petsyNavy.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(
                  icon,
                  size: 24,
                  color: isSelected ? Colors.white : _petsyNavy,
                ),
                if (isSelected)
                  const Icon(Icons.check_circle, color: Colors.white, size: 18),
              ],
            ),
            const Spacer(),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: isSelected ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 10,
                color: isSelected ? Colors.white70 : Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    required bool isBold,
    bool isTotal = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w500,
            color: isBold ? Colors.black87 : Colors.grey.shade600,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: isTotal ? 18 : 15,
            fontWeight: isBold ? FontWeight.w900 : FontWeight.w700,
            color: isTotal ? _petsyGreen : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingAddressCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200, width: 1.5),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: CircularProgressIndicator(color: _petsyGreen),
        ),
      ),
    );
  }
}
