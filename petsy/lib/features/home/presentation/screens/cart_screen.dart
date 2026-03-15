import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

// --- Ensure these paths match your project ---
import 'package:petsy/features/home/presentation/screens/home_screen.dart';
import 'package:petsy/features/home/presentation/screens/profile_page.dart';
import 'package:petsy/features/home/presentation/screens/checkout_screen.dart';
import 'package:petsy/features/home/presentation/screens/orders_screen.dart'; // 🚀 IMPORTED ORDERS SCREEN HERE
import 'package:petsy/providers/cart_provider.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final Color _petsyGreen = const Color(0xFF2B8C61);
  final Color _petsyNavy = const Color(0xFF003466);
  final Color _bgColor = const Color(0xFFF9F9FB);
  final Color _bottomNavBg = const Color(0xFFE2E2E2);

  final double _shippingFee = 100.00;

  String _formatPrice(double price) => price.toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    final cartProvider = context.watch<CartProvider>();
    final cartItems = cartProvider.items;
    final subtotal = cartProvider.subtotal;
    final total = cartItems.isEmpty ? 0.0 : subtotal + _shippingFee;

    return Scaffold(
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
          "Cart",
          style: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: Colors.black87,
          ),
        ),
        centerTitle: false,
        actions: [
          _buildActionCircle(Icons.delete_outline, () {
            HapticFeedback.mediumImpact();
            cartProvider.clearCart();
          }),
          const SizedBox(width: 10),
          _buildActionCircle(Icons.share_outlined, () {}),
          const SizedBox(width: 20),
        ],
      ),

      body: cartItems.isEmpty
          ? _buildEmptyCartState()
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 15,
                    ),
                    child: Column(
                      children: [
                        // 1. Cart Items List
                        ...List.generate(cartItems.length, (index) {
                          return _buildCartItemCard(
                            index,
                            cartItems[index],
                            cartProvider,
                          );
                        }),

                        const SizedBox(height: 20),

                        // 2. Promo Code Box
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
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
                              Icon(
                                Icons.check_circle_outline,
                                color: Colors.grey.shade400,
                                size: 22,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextField(
                                  style: GoogleFonts.inter(fontSize: 14),
                                  decoration: InputDecoration(
                                    hintText: "Enter Promo Code",
                                    hintStyle: GoogleFonts.inter(
                                      color: Colors.grey.shade400,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    border: InputBorder.none,
                                  ),
                                ),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _petsyGreen,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
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
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 30),

                        // 3. Totals Summary
                        _buildSummaryRow(
                          "Sub. Total",
                          "₱${_formatPrice(subtotal)}",
                          isBold: false,
                        ),
                        const SizedBox(height: 10),
                        _buildSummaryRow(
                          "Shipping Fee",
                          "₱${_formatPrice(_shippingFee)}",
                          isBold: false,
                        ),
                        const SizedBox(height: 10),
                        _buildSummaryRow(
                          "Total",
                          "₱${_formatPrice(total)}",
                          isBold: true,
                        ),
                        const SizedBox(height: 30),

                        // 4. Checkout Button
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _petsyGreen,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              elevation: 0,
                            ),
                            onPressed: () {
                              HapticFeedback.heavyImpact();

                              if (cartItems.isNotEmpty) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CheckoutScreen(
                                      product: cartItems[0]['original_product'],
                                      quantity: cartItems[0]['quantity'] as int,
                                      selectedFlavor: cartItems[0]['flavor']
                                          .toString(),
                                      selectedSize: cartItems[0]['size']
                                          .toString(),
                                      unitPrice: (cartItems[0]['price'] as num)
                                          .toDouble(),
                                    ),
                                  ),
                                );
                              }
                            },
                            child: Text(
                              "Checkout",
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
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
      bottomNavigationBar: _buildCustomBottomNav(),
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

  Widget _buildCartItemCard(
    int index,
    Map<String, dynamic> item,
    CartProvider provider,
  ) {
    final double itemPrice = (item['price'] as num).toDouble();
    final int itemQty = item['quantity'] as int;

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(12),
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
      child: Row(
        children: [
          Container(
            height: 80,
            width: 80,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F6F8),
              borderRadius: BorderRadius.circular(15),
            ),
            child: _buildProductImage(item['image'] ?? ''),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['name']?.toString() ?? 'Item',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  item['brand']?.toString() ?? 'Petsy',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _petsyGreen,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "${item['flavor']}, ${item['size']}",
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "₱ ${_formatPrice(itemPrice)}",
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Colors.black87,
                      ),
                    ),
                    Row(
                      children: [
                        _buildQtyBtn(Icons.remove, () {
                          HapticFeedback.lightImpact();
                          provider.updateQuantity(index, -1);
                        }),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            "$itemQty",
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        _buildQtyBtn(Icons.add, () {
                          HapticFeedback.lightImpact();
                          provider.updateQuantity(index, 1);
                        }),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductImage(String imageUrl) {
    if (imageUrl.isEmpty) return const Icon(Icons.image, color: Colors.grey);
    if (imageUrl.startsWith('http'))
      return Image.network(imageUrl, fit: BoxFit.contain);
    return Image.asset(imageUrl, fit: BoxFit.contain);
  }

  Widget _buildQtyBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: _petsyGreen, width: 1.5),
        ),
        child: Icon(icon, size: 16, color: _petsyGreen),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {required bool isBold}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.w900 : FontWeight.w600,
            color: isBold ? Colors.black87 : Colors.grey.shade700,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: isBold ? FontWeight.w900 : FontWeight.w600,
            color: Colors.black87,
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
            padding: const EdgeInsets.all(30),
            decoration: const BoxDecoration(
              color: Color(0xFFF5F6F8),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.shopping_cart_outlined,
              size: 80,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            "Your cart is empty",
            style: GoogleFonts.inter(
              color: Colors.black87,
              fontWeight: FontWeight.w900,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Looks like you haven't added anything yet.",
            style: GoogleFonts.inter(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _petsyGreen,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
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
              ),
            ),
          ),
        ],
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
                    Icons.shopping_cart_outlined,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                _buildNavItem(Icons.format_list_bulleted, "Orders", false, () {
                  // 🚀 FIXED: OrderScreen -> OrdersScreen
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
