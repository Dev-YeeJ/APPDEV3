import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

// --- Ensure these paths match your project ---
import 'package:petsy/features/home/presentation/screens/home_screen.dart';
import 'package:petsy/features/home/presentation/screens/profile_page.dart';
import 'package:petsy/features/home/presentation/screens/checkout_screen.dart';
import 'package:petsy/features/home/presentation/screens/orders_screen.dart';
import 'package:petsy/providers/cart_provider.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final Color _petsyGreen = const Color(0xFF2B8C61);
  final Color _petsyNavy = const Color(0xFF003466);
  final Color _bgColor = const Color(0xFFF4F6F8);
  final Color _bottomNavBg = const Color(0xFFE2E2E2);

  final double _shippingFee = 100.00;

  // 🚀 STATE: Keeps track of exactly which items are checked!
  Set<int> _selectedIndices = {};

  String _formatPrice(double price) => price.toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    final cartProvider = context.watch<CartProvider>();
    final cartItems = cartProvider.items;

    final screenWidth = MediaQuery.of(context).size.width;
    final bool isSmallScreen = screenWidth < 360;

    // Safety check: Remove indices if an item gets deleted
    _selectedIndices.removeWhere((index) => index >= cartItems.length);

    // 🚀 DYNAMIC CALCULATION: Only calculate price for CHECKED items
    double selectedSubtotal = 0.0;
    for (int i in _selectedIndices) {
      double price = (cartItems[i]['price'] as num).toDouble();
      int qty = cartItems[i]['quantity'] as int;
      selectedSubtotal += (price * qty);
    }

    final double total = _selectedIndices.isEmpty
        ? 0.0
        : selectedSubtotal + _shippingFee;
    final bool isAllSelected =
        _selectedIndices.length == cartItems.length && cartItems.isNotEmpty;

    return Scaffold(
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
          "My Cart",
          style: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: _petsyNavy,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
      ),

      // --- MAIN BODY ---
      body: cartItems.isEmpty
          ? _buildEmptyCartState()
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 15 : 20,
                      vertical: 10,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 🚀 NEW: SELECT ALL & BULK DELETE BAR
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Checkbox(
                                    activeColor: _petsyGreen,
                                    visualDensity: VisualDensity.compact,
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    side: BorderSide(
                                      color: Colors.grey.shade400,
                                      width: 1.5,
                                    ),
                                    value: isAllSelected,
                                    onChanged: (val) {
                                      HapticFeedback.selectionClick();
                                      setState(() {
                                        if (val == true) {
                                          _selectedIndices = Set.from(
                                            Iterable.generate(cartItems.length),
                                          );
                                        } else {
                                          _selectedIndices.clear();
                                        }
                                      });
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      "Select All",
                                      style: GoogleFonts.inter(
                                        color: Colors.grey.shade700,
                                        fontWeight: FontWeight.bold,
                                        fontSize: isSmallScreen ? 12 : 14,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Delete button appears if items are checked
                            if (_selectedIndices.isNotEmpty)
                              TextButton.icon(
                                onPressed: () {
                                  HapticFeedback.mediumImpact();
                                  final sortedIndices =
                                      _selectedIndices.toList()
                                        ..sort((a, b) => b.compareTo(a));
                                  for (int i in sortedIndices) {
                                    int qty = cartItems[i]['quantity'];
                                    cartProvider.updateQuantity(i, -qty);
                                  }
                                  setState(() => _selectedIndices.clear());
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Selected items removed."),
                                    ),
                                  );
                                },
                                icon: Icon(
                                  Icons.delete_outline,
                                  color: Colors.red.shade600,
                                  size: 18,
                                ),
                                label: Text(
                                  "Delete",
                                  style: GoogleFonts.inter(
                                    color: Colors.red.shade600,
                                    fontWeight: FontWeight.bold,
                                    fontSize: isSmallScreen ? 12 : 14,
                                  ),
                                ),
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: const Size(50, 30),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // 1. Cart Items List
                        ...List.generate(cartItems.length, (index) {
                          bool isSelected = _selectedIndices.contains(index);
                          return _buildCartItemRow(
                            index,
                            cartItems[index],
                            cartProvider,
                            isSelected,
                            isSmallScreen,
                          );
                        }),

                        const SizedBox(height: 10),

                        // 2. Promo Code Box
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
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
                              const SizedBox(width: 10),
                              Icon(
                                Icons.local_offer_outlined,
                                color: _petsyGreen,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextField(
                                  style: GoogleFonts.inter(
                                    fontSize: isSmallScreen ? 12 : 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: "Promo Code",
                                    hintStyle: GoogleFonts.inter(
                                      color: Colors.grey.shade400,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    border: InputBorder.none,
                                    isDense: true,
                                  ),
                                ),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _petsyNavy,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isSmallScreen ? 12 : 20,
                                    vertical: 12,
                                  ),
                                ),
                                onPressed: () {
                                  HapticFeedback.selectionClick();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Promo code applied!"),
                                    ),
                                  );
                                },
                                child: Text(
                                  "Apply",
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontSize: isSmallScreen ? 12 : 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 25),

                        // 3. Receipt Style Summary
                        Text(
                          "Order Summary",
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _petsyNavy,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.grey.shade200),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              _buildSummaryRow(
                                "Subtotal (${_selectedIndices.length} items)",
                                "₱${_formatPrice(selectedSubtotal)}",
                                isBold: false,
                                isSmall: isSmallScreen,
                              ),
                              const SizedBox(height: 12),
                              _buildSummaryRow(
                                "Shipping Fee",
                                _selectedIndices.isEmpty
                                    ? "₱0.00"
                                    : "₱${_formatPrice(_shippingFee)}",
                                isBold: false,
                                isSmall: isSmallScreen,
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 15),
                                child: Divider(
                                  height: 1,
                                  color: Colors.black12,
                                ),
                              ),
                              _buildSummaryRow(
                                "Total Amount",
                                "₱${_formatPrice(total)}",
                                isBold: true,
                                isTotal: true,
                                isSmall: isSmallScreen,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 30),

                        // 4. Checkout Button
                        SizedBox(
                          width: double.infinity,
                          height: 58,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _petsyGreen,
                              disabledBackgroundColor: Colors.grey.shade300,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            // Disable button if nothing is checked!
                            onPressed: _selectedIndices.isEmpty
                                ? null
                                : () {
                                    HapticFeedback.heavyImpact();

                                    List<Map<String, dynamic>> itemsToCheckout = [];
                                    final sortedIndices =
                                        _selectedIndices.toList()
                                          ..sort((a, b) => a.compareTo(b));
                                    for (int i in sortedIndices) {
                                      var item = cartItems[i];
                                      itemsToCheckout.add({
                                        'product': item['original_product'],
                                        'quantity': item['quantity'] as int,
                                        'selectedFlavor': item['flavor'].toString(),
                                        'selectedSize': item['size'].toString(),
                                        'unitPrice': (item['price'] as num).toDouble(),
                                      });
                                    }

                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => CheckoutScreen(
                                          checkoutItems: itemsToCheckout,
                                        ),
                                      ),
                                    );
                                  },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Checkout (${_selectedIndices.length})",
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: _selectedIndices.isEmpty
                                        ? Colors.grey.shade500
                                        : Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Icon(
                                  Icons.arrow_forward,
                                  color: _selectedIndices.isEmpty
                                      ? Colors.grey.shade500
                                      : Colors.white,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),

      // --- BOTTOM NAV BAR ---
      bottomNavigationBar: _buildCustomBottomNav(),
    );
  }

  // --- UI HELPER WIDGETS ---

  Widget _buildCartItemRow(
    int index,
    Map<String, dynamic> item,
    CartProvider provider,
    bool isSelected,
    bool isSmallScreen,
  ) {
    final double itemPrice = (item['price'] as num).toDouble();
    final int itemQty = item['quantity'] as int;

    return Dismissible(
      key: ValueKey(item.hashCode.toString() + index.toString()),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        HapticFeedback.mediumImpact();
        setState(() {
          _selectedIndices.remove(index);
          Set<int> updatedIndices = {};
          for (int i in _selectedIndices) {
            updatedIndices.add(i > index ? i - 1 : i);
          }
          _selectedIndices = updatedIndices;
        });
        provider.updateQuantity(index, -itemQty);
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.centerRight,
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 30),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 🚀 SELECTION CHECKBOX
          Padding(
            padding: EdgeInsets.only(right: isSmallScreen ? 4 : 8, bottom: 15),
            child: Checkbox(
              activeColor: _petsyGreen,
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              side: BorderSide(color: Colors.grey.shade400, width: 1.5),
              value: isSelected,
              onChanged: (val) {
                HapticFeedback.selectionClick();
                setState(() {
                  if (val == true) {
                    _selectedIndices.add(index);
                  } else {
                    _selectedIndices.remove(index);
                  }
                });
              },
            ),
          ),

          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 15),
              padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? _petsyGreen.withOpacity(0.03)
                    : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? _petsyGreen.withOpacity(0.5)
                      : Colors.grey.shade200,
                  width: isSelected ? 1.5 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    height: isSmallScreen ? 65 : 75,
                    width: isSmallScreen ? 65 : 75,
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: _buildProductImage(item['image'] ?? ''),
                  ),
                  SizedBox(width: isSmallScreen ? 8 : 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['name']?.toString() ?? 'Item',
                          style: GoogleFonts.inter(
                            fontSize: isSmallScreen ? 13 : 14,
                            fontWeight: FontWeight.w800,
                            color: _petsyNavy,
                            letterSpacing: -0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${item['brand']} • ${item['flavor']}, ${item['size']}",
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  "₱ ${_formatPrice(itemPrice)}",
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                    color: _petsyGreen,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 5),
                            Container(
                              height: 30,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF4F6F8),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildPillBtn(
                                    Icons.remove,
                                    isSmallScreen,
                                    () {
                                      if (itemQty > 1) {
                                        HapticFeedback.lightImpact();
                                        provider.updateQuantity(index, -1);
                                      }
                                    },
                                  ),
                                  Container(
                                    width: isSmallScreen ? 20 : 25,
                                    alignment: Alignment.center,
                                    child: Text(
                                      "$itemQty",
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                  _buildPillBtn(Icons.add, isSmallScreen, () {
                                    HapticFeedback.lightImpact();
                                    provider.updateQuantity(index, 1);
                                  }),
                                ],
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
        ],
      ),
    );
  }

  Widget _buildProductImage(String imageUrl) {
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

  Widget _buildPillBtn(IconData icon, bool isSmallScreen, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: isSmallScreen ? 26 : 30,
        height: 30,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.transparent,
        ),
        child: Icon(icon, size: 16, color: Colors.grey.shade700),
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    required bool isBold,
    bool isTotal = false,
    required bool isSmall,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: isTotal ? (isSmall ? 14 : 16) : (isSmall ? 12 : 14),
              fontWeight: isBold ? FontWeight.w900 : FontWeight.w600,
              color: isBold ? _petsyNavy : Colors.grey.shade500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: isTotal ? (isSmall ? 18 : 20) : (isSmall ? 14 : 15),
            fontWeight: isBold ? FontWeight.w900 : FontWeight.w700,
            color: isTotal ? _petsyGreen : Colors.black87,
            letterSpacing: isTotal ? -0.5 : 0,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyCartState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(35),
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
            child: Image.asset(
              'assets/images/petsylogo.png',
              height: 60,
              color: Colors.grey.shade300,
              errorBuilder: (c, e, s) => Icon(
                Icons.shopping_cart_outlined,
                size: 80,
                color: Colors.grey.shade300,
              ),
            ),
          ),
          const SizedBox(height: 25),
          Text(
            "Your cart is empty",
            style: GoogleFonts.inter(
              color: _petsyNavy,
              fontWeight: FontWeight.w900,
              fontSize: 22,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Looks like you haven't added anything yet.",
            style: GoogleFonts.inter(
              color: Colors.grey.shade500,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 35),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _petsyGreen,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            ),
            child: Text(
              "Start Shopping",
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
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

                Expanded(
                  child: Container(
                    height: 65,
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      height: 65,
                      width: 65,
                      margin: const EdgeInsets.only(bottom: 5),
                      decoration: BoxDecoration(
                        color: _petsyGreen,
                        shape: BoxShape.circle,
                        border: Border.all(color: _bottomNavBg, width: 4),
                      ),
                      child: const Icon(
                        Icons.shopping_cart_outlined,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ),

                _buildNavItem(Icons.format_list_bulleted, "Orders", false, () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const OrdersScreen()),
                  );
                }),
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
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
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
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
