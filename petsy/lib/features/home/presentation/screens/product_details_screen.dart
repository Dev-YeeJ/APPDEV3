import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';

// --- Ensure these paths match your project ---
import 'package:petsy/features/home/presentation/screens/checkout_screen.dart';
import 'package:petsy/features/home/presentation/screens/cart_screen.dart';
import 'package:petsy/features/home/presentation/screens/customer_chat_list_screen.dart';
import 'package:petsy/features/home/presentation/screens/home_screen.dart'; // To use PersonalFavoriteButton
import 'package:petsy/providers/cart_provider.dart';

class ProductDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> product;

  const ProductDetailsScreen({super.key, required this.product});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  final Color _petsyGreen = const Color(0xFF2B8C61);
  final Color _petsyNavy = const Color(0xFF003466);
  final Color _appBackground = const Color(0xFFF8F9FA);

  int _quantity = 1;
  bool _isDescExpanded = false;

  late String _opt1Title;
  late List<String> _opt1List;
  late String _selectedOpt1;

  late String _opt2Title;
  late List<String> _opt2List;
  late String _selectedOpt2;

  late double _basePrice;
  late double _currentUnitPrice;

  // 🚀 NEW: Check if the product is out of stock
  late bool _isOutOfStock;

  @override
  void initState() {
    super.initState();
    _setupProductData();
  }

  void _setupProductData() {
    // 🚀 READS EXACT PRICE FROM FIREBASE
    _basePrice = (widget.product['price'] as num?)?.toDouble() ?? 0.0;
    _currentUnitPrice = _basePrice;

    // 🚀 READ OUT OF STOCK STATUS
    _isOutOfStock = widget.product['isOutOfStock'] ?? false;

    final String pType =
        widget.product['productType']?.toString() ?? 'Accessory';

    // 🚀 READS EXACT FLAVORS/COLORS FROM FIREBASE
    List<dynamic> dbFlavors = widget.product['flavors'] ?? [];
    if (dbFlavors.isNotEmpty) {
      _opt1Title = (pType == 'Food' || pType == 'Treats')
          ? "Flavor"
          : "Variant";
      _opt1List = dbFlavors.map((e) => e.toString()).toList();
    } else {
      _opt1Title = "Variant";
      _opt1List = ['Standard'];
    }

    // 🚀 READS EXACT SIZES FROM FIREBASE
    List<dynamic> dbSizes = widget.product['sizes'] ?? [];
    if (dbSizes.isNotEmpty) {
      _opt2Title = "Size";
      _opt2List = dbSizes.map((e) => e.toString()).toList();
    } else {
      _opt2Title = "Size";
      _opt2List = ['Standard'];
    }

    _selectedOpt1 = _opt1List.first;
    _selectedOpt2 = _opt2List.first;
  }

  void _updateSizeAndPrice(String newSize) {
    setState(() {
      _selectedOpt2 = newSize;
      int sizeIndex = _opt2List.indexOf(newSize);

      // Simple price scaling based on size selection
      if (sizeIndex == 0) {
        _currentUnitPrice = _basePrice;
      } else if (sizeIndex == 1) {
        _currentUnitPrice = _basePrice * 1.5;
      } else if (sizeIndex == 2) {
        _currentUnitPrice = _basePrice * 2.0;
      } else if (sizeIndex == 3) {
        _currentUnitPrice = _basePrice * 3.0;
      }
    });
  }

  String _formatPrice(double price) => price.toStringAsFixed(2);

  void _shareProduct() {
    final String name = widget.product['name'] ?? 'this amazing product';
    Share.share(
      'Check out $name on the Petsy App! Get it now starting at just ₱${_formatPrice(_currentUnitPrice)}. 🐾',
    );
  }

  void _addToCart() {
    HapticFeedback.mediumImpact();

    // Send to global cart!
    context.read<CartProvider>().addToCart(
      widget.product,
      _quantity,
      _selectedOpt1,
      _selectedOpt2,
      _currentUnitPrice,
    );

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "✅ Added $_quantity item(s) to your cart!",
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        backgroundColor: _petsyGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        action: SnackBarAction(
          label: 'VIEW CART',
          textColor: Colors.white,
          onPressed: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const CartScreen()),
          ),
        ),
      ),
    );
  }

  Widget _buildProductImage(String imageUrl) {
    if (imageUrl.isEmpty) {
      return const Center(
        child: Icon(Icons.image, size: 100, color: Colors.grey),
      );
    }
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

  @override
  Widget build(BuildContext context) {
    final String name = widget.product['name'] ?? 'Petsy Product';
    final String rating = widget.product['rating']?.toString() ?? '0.0';
    final String sold = widget.product['sold']?.toString() ?? '0';
    final String imageUrl = widget.product['image'] ?? '';
    final String brand = widget.product['brand'] ?? 'Petsy Partner';

    // 🚀 READS EXACT DESCRIPTION FROM FIREBASE
    final String description =
        widget.product['description'] ??
        "Premium selection crafted with high-quality ingredients to ensure the health and happiness of your pet. Formulated by experts to provide balanced nutrition and everyday satisfaction.";

    return Scaffold(
      backgroundColor: _appBackground,
      appBar: AppBar(
        backgroundColor: _appBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        leadingWidth: 70,
        leading: Padding(
          padding: const EdgeInsets.only(left: 20, top: 8, bottom: 8),
          child: _buildHomeStyleActionButton(
            icon: Icons.arrow_back,
            iconColor: Colors.black87,
            onTap: () => Navigator.pop(context),
          ),
        ),
        title: Image.asset(
          'assets/images/petsylogo.png',
          height: 22,
          errorBuilder: (c, e, s) => Text(
            "Details",
            style: GoogleFonts.inter(
              color: _petsyNavy,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
        ),
        centerTitle: true,
        actions: [
          // Uses the exact same smart personal favorites button we added to Home!
          PersonalFavoriteButton(product: widget.product),
          const SizedBox(width: 10),
          _buildHomeStyleActionButton(
            icon: Icons.forum_outlined,
            iconColor: _petsyNavy,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CustomerChatListScreen(),
              ),
            ),
          ),
          const SizedBox(width: 10),
          _buildHomeStyleActionButton(
            icon: Icons.share_outlined,
            iconColor: _petsyNavy,
            onTap: _shareProduct,
          ),
          const SizedBox(width: 20),
        ],
      ),

      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 280,
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 15,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 15,
                          spreadRadius: 2,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Padding(
                            padding: const EdgeInsets.all(30),
                            child: Hero(
                              tag: imageUrl.isNotEmpty
                                  ? imageUrl
                                  : 'product_image',
                              child: _buildProductImage(imageUrl),
                            ),
                          ),
                        ),
                        // 🚀 BIG SOLD OUT BADGE IF OUT OF STOCK
                        if (_isOutOfStock)
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.65),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade700,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.red.withOpacity(0.3),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    "SOLD OUT",
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 25,
                      vertical: 10,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: GoogleFonts.inter(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: _petsyNavy,
                            height: 1.1,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 10),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            RichText(
                              text: TextSpan(
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w600,
                                ),
                                children: [
                                  const TextSpan(text: "By "),
                                  TextSpan(
                                    text: brand,
                                    style: TextStyle(
                                      color: _petsyGreen,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                const Icon(
                                  Icons.star,
                                  color: Colors.amber,
                                  size: 18,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  "$rating ($sold)",
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade700,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 25),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "₱ ${_formatPrice(_currentUnitPrice)}",
                              style: GoogleFonts.inter(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                color: _isOutOfStock
                                    ? Colors.grey.shade400
                                    : Colors.black87,
                                letterSpacing: -1,
                              ),
                            ),
                            // 🚀 QUANTITY SELECTOR (Disabled if out of stock)
                            Opacity(
                              opacity: _isOutOfStock ? 0.5 : 1.0,
                              child: Row(
                                children: [
                                  GestureDetector(
                                    onTap: _isOutOfStock
                                        ? null
                                        : () {
                                            if (_quantity > 1) {
                                              HapticFeedback.lightImpact();
                                              setState(() => _quantity--);
                                            }
                                          },
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.grey.shade400,
                                          width: 1.5,
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.remove,
                                        size: 18,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 45,
                                    child: Center(
                                      child: Text(
                                        "$_quantity",
                                        style: GoogleFonts.inter(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: _isOutOfStock
                                        ? null
                                        : () {
                                            HapticFeedback.lightImpact();
                                            setState(() => _quantity++);
                                          },
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: _petsyGreen,
                                          width: 1.5,
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.add,
                                        size: 18,
                                        color: _petsyGreen,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 35),

                        _buildVariationGrid(
                          title: _opt1Title,
                          options: _opt1List,
                          selected: _selectedOpt1,
                          isTwoColumns: true,
                          onSelect: (val) {
                            HapticFeedback.selectionClick();
                            setState(() => _selectedOpt1 = val);
                          },
                        ),
                        _buildVariationGrid(
                          title: _opt2Title,
                          options: _opt2List,
                          selected: _selectedOpt2,
                          isTwoColumns: false,
                          onSelect: (val) {
                            HapticFeedback.selectionClick();
                            _updateSizeAndPrice(val);
                          },
                        ),

                        // 🚀 NEW: Store Profile Section
                        _buildStoreProfile(brand),
                        const SizedBox(height: 25),

                        Text(
                          widget.product['productType'] == 'Food'
                              ? "Ingredients & Description"
                              : "Description",
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        AnimatedSize(
                          duration: const Duration(milliseconds: 300),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                description,
                                maxLines: _isDescExpanded ? null : 3,
                                overflow: _isDescExpanded
                                    ? TextOverflow.visible
                                    : TextOverflow.fade,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                  height: 1.6,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (description.length > 100)
                                GestureDetector(
                                  onTap: () => setState(
                                    () => _isDescExpanded = !_isDescExpanded,
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      _isDescExpanded
                                          ? "Read less"
                                          : "Read more...",
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        color: _petsyGreen,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 25),

                        // 🚀 NEW: Shipping Info
                        _buildShippingInfo(),
                        const SizedBox(height: 25),

                        // 🚀 NEW: Review Summary
                        _buildReviewSummary(rating, sold),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // --- BOTTOM ACTION BAR ---
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      // 🚀 GREY OUT IF OUT OF STOCK
                      side: BorderSide(
                        color: _isOutOfStock
                            ? Colors.grey.shade300
                            : _petsyGreen,
                        width: 2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: _isOutOfStock ? null : _addToCart,
                    child: Text(
                      _isOutOfStock ? "Unavailable" : "Add To Cart",
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _isOutOfStock
                            ? Colors.grey.shade400
                            : _petsyNavy,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      // 🚀 GREY OUT IF OUT OF STOCK
                      backgroundColor: _isOutOfStock
                          ? Colors.grey.shade300
                          : _petsyGreen,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: _isOutOfStock
                        ? null
                        : () {
                            HapticFeedback.heavyImpact();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CheckoutScreen(
                                  checkoutItems: [
                                    {
                                      'product': widget.product,
                                      'quantity': _quantity,
                                      'selectedFlavor': _selectedOpt1,
                                      'selectedSize': _selectedOpt2,
                                      'unitPrice': _currentUnitPrice,
                                    },
                                  ],
                                ),
                              ),
                            );
                          },
                    child: Text(
                      _isOutOfStock
                          ? "Out of Stock"
                          : "Check Out  •  ₱${_formatPrice(_currentUnitPrice * _quantity)}",
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _isOutOfStock
                            ? Colors.grey.shade500
                            : Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeStyleActionButton({
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
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
        child: Icon(icon, color: iconColor, size: 20),
      ),
    );
  }

  Widget _buildVariationGrid({
    required String title,
    required List<String> options,
    required String selected,
    required bool isTwoColumns,
    required Function(String) onSelect,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isTwoColumns ? 2 : 4,
            childAspectRatio: isTwoColumns ? 3.5 : 2.5,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: options.length,
          itemBuilder: (context, index) {
            final String option = options[index];
            final bool isSelected = selected == option;
            return GestureDetector(
              onTap: () => onSelect(option),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : const Color(0xFFF1F1F1),
                  border: Border.all(
                    color: isSelected ? _petsyNavy : Colors.transparent,
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  option,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: isTwoColumns ? 13 : 11,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? _petsyNavy : Colors.grey.shade700,
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 25),
      ],
    );
  }

  Widget _buildStoreProfile(String brand) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: _petsyGreen.withOpacity(0.1),
            child: Icon(Icons.storefront, color: _petsyGreen, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  brand,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: _petsyNavy,
                  ),
                ),
                Text(
                  "Official Store",
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: _petsyGreen),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: Text(
              "View Shop",
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: _petsyGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShippingInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Delivery Options",
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _petsyNavy,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.local_shipping_outlined, color: _petsyGreen, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Standard Delivery",
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      "Receive by tomorrow with Prime",
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                "₱50.00",
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, thickness: 1),
          ),
          Row(
            children: [
              Icon(
                Icons.assignment_return_outlined,
                color: _petsyGreen,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "7 Days Return",
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      "Change of mind is not applicable",
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReviewSummary(String rating, String sold) {
    double parsedRating = double.tryParse(rating) ?? 0.0;
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Ratings & Reviews",
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      rating,
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      children: List.generate(5, (index) {
                        return Icon(
                          index < parsedRating.floor()
                              ? Icons.star
                              : (index < parsedRating
                                    ? Icons.star_half
                                    : Icons.star_border),
                          color: Colors.amber,
                          size: 20,
                        );
                      }),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "($sold sold)",
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 28),
          ],
        ),
      ),
    );
  }
}
