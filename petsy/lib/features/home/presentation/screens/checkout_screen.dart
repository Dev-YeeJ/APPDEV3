import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// --- Ensure this path matches your project structure ---
import 'package:petsy/features/home/presentation/screens/home_screen.dart';

class CheckoutScreen extends StatefulWidget {
  final Map<String, dynamic> product;
  final int quantity;
  final String selectedFlavor;
  final String selectedSize;
  final double unitPrice;

  const CheckoutScreen({
    super.key,
    required this.product,
    required this.quantity,
    required this.selectedFlavor,
    required this.selectedSize,
    required this.unitPrice,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  // --- EXACT MOCKUP COLORS ---
  final Color _petsyGreen = const Color(0xFF2B8C61);
  final Color _petsyNavy = const Color(0xFF003466);
  final Color _bgColor = const Color(0xFFF7F7F9);

  // --- FIREBASE VARIABLES ---
  final User? currentUser = FirebaseAuth.instance.currentUser;
  Stream<DocumentSnapshot>? _userDataStream;

  // --- LOGIC VARIABLES ---
  final double _shippingFee =
      50.00; // You can make this fetch from a DB later too!
  String _selectedPaymentMethod = 'COD';
  final TextEditingController _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialize the stream to fetch the logged-in user's live data
    if (currentUser != null) {
      _userDataStream = FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .snapshots();
    }
  }

  String _formatPrice(double price) => price.toStringAsFixed(2);

  // 🌟 SUCCESS MODAL
  void _placeOrder() {
    HapticFeedback.heavyImpact();

    // TODO: Add Firestore write logic here to save the order to an 'orders' collection!

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
              child: Icon(Icons.check_circle, color: _petsyGreen, size: 60),
            ),
            const SizedBox(height: 20),
            Text(
              "Order Placed!",
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: _petsyNavy,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Your order has been successfully placed and is being processed.",
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: Colors.grey.shade600,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _petsyGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const HomeScreen()),
                    (route) => false,
                  );
                },
                child: Text(
                  "Back to Home",
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductImage(String imageUrl) {
    if (imageUrl.isEmpty) return const Icon(Icons.image, color: Colors.grey);
    if (imageUrl.startsWith('http'))
      return Image.network(imageUrl, fit: BoxFit.contain);
    return Image.asset(imageUrl, fit: BoxFit.contain);
  }

  @override
  Widget build(BuildContext context) {
    final double subtotal = widget.unitPrice * widget.quantity;
    final double total = subtotal + _shippingFee;

    final String name = widget.product['name'] ?? 'Product Name';
    final String imageUrl = widget.product['image'] ?? '';

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: _bgColor,

        // --- APP BAR ---
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
                backgroundColor: Color(0xFFE6E6E6),
                child: Icon(Icons.arrow_back, color: Colors.black87, size: 20),
              ),
            ),
          ),
          title: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/petsylogo.png',
                height: 16,
                errorBuilder: (c, e, s) => const SizedBox(),
              ),
              const SizedBox(height: 2),
              Text(
                "Checkout",
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          centerTitle: true,
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

                        // Safely extract all dynamic data
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

                        // Combine into a clean multi-line string
                        final String fullAddress = "$street\n$barangay, $city";

                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: _petsyNavy, width: 1.5),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                color: _petsyGreen,
                                size: 22,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Shipping Address",
                                      style: GoogleFonts.inter(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Wrap(
                                      crossAxisAlignment:
                                          WrapCrossAlignment.start,
                                      children: [
                                        Container(
                                          margin: const EdgeInsets.only(
                                            right: 8,
                                            bottom: 4,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _petsyGreen.withOpacity(0.3),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: Text(
                                            "Home",
                                            style: GoogleFonts.inter(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w900,
                                              color: _petsyGreen,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          fullAddress,
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color: Colors.black87,
                                            height: 1.4,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      "$fullName     $phone",
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: Colors.grey.shade700,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Optional Edit Button
                              GestureDetector(
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        "Edit address coming soon!",
                                      ),
                                    ),
                                  );
                                },
                                child: Icon(
                                  Icons.edit_outlined,
                                  color: Colors.grey.shade400,
                                  size: 18,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),

                    // --- 2. ORDER ITEM CARD ---
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Container(
                            height: 85,
                            width: 85,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F6F8),
                              borderRadius: BorderRadius.circular(15),
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
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "${widget.selectedFlavor}, ${widget.selectedSize}",
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "₱ ${_formatPrice(widget.unitPrice)}",
                                      style: GoogleFonts.inter(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    Text(
                                      "x${widget.quantity}",
                                      style: GoogleFonts.inter(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: _petsyNavy,
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
                    const SizedBox(height: 25),

                    // --- 3. SHIPPING OPTION ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Select Shipping",
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Shipping options coming soon!"),
                              ),
                            );
                          },
                          child: Text(
                            "See all options",
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _petsyNavy,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 15,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: _petsyNavy, width: 1.5),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "JNT Express",
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "Estimated arrival 13-14 February",
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
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
                    ),
                    const SizedBox(height: 20),

                    // --- 4. NOTE ---
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          "Note:",
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: TextField(
                            controller: _noteController,
                            style: GoogleFonts.inter(fontSize: 13),
                            textAlign: TextAlign.right,
                            decoration: InputDecoration(
                              hintText: "Type any message...",
                              hintStyle: GoogleFonts.inter(
                                color: Colors.grey.shade400,
                                fontSize: 12,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),

                    // --- 5. SUBTOTAL ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Subtotal, ${widget.quantity} Items",
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          "₱ ${_formatPrice(subtotal)}",
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: _petsyGreen,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 15),
                    Divider(color: _petsyNavy, thickness: 1.5),
                    const SizedBox(height: 15),

                    // --- 6. PAYMENT METHOD CARDS ---
                    Text(
                      "Payment Method",
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 15),

                    SizedBox(
                      height: 90,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        clipBehavior: Clip.none,
                        children: [
                          _buildPaymentCard(
                            id: 'COD',
                            title: 'Cash on Delivery',
                            subtitle:
                                'Pay cash when the item arrives at the destination',
                            icon: Icons.money,
                          ),
                          const SizedBox(width: 12),
                          _buildPaymentCard(
                            id: 'BANK',
                            title: 'Bank Card',
                            subtitle:
                                'Enter your Bank Card details and make a payment.',
                            icon: Icons.credit_card,
                          ),
                          const SizedBox(width: 12),
                          _buildPaymentCard(
                            id: 'GCASH',
                            title: 'GCash',
                            subtitle:
                                'Login to your GCash account and make a payment.',
                            icon: Icons.account_balance_wallet,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),

            // --- 7. BOTTOM FIXED CHECKOUT BAR ---
            Container(
              padding: const EdgeInsets.fromLTRB(25, 15, 25, 30),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F3F5),
                border: Border(
                  top: BorderSide(color: Colors.grey.shade300, width: 1),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Total",
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        "₱ ${_formatPrice(total)}",
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Colors.black87,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 52,
                    width: 150,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _petsyGreen,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      onPressed: _placeOrder,
                      child: Text(
                        "Checkout",
                        style: GoogleFonts.inter(
                          fontSize: 15,
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
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? _petsyGreen.withOpacity(0.4) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? _petsyGreen : Colors.black87,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: _petsyGreen),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? _petsyGreen : Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Expanded(
              child: Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 9,
                  color: isSelected
                      ? _petsyGreen.withOpacity(0.9)
                      : Colors.grey.shade600,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- UI HELPER: LOADING SKELETON ---
  Widget _buildLoadingAddressCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300, width: 1.5),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: CircularProgressIndicator(color: _petsyGreen),
        ),
      ),
    );
  }
}
