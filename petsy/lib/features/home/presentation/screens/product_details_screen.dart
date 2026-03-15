import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

// --- Ensure these paths match your project folder structure ---
import 'package:petsy/features/home/presentation/screens/checkout_screen.dart';
import 'package:petsy/features/home/presentation/screens/cart_screen.dart'; // 🚀 ADDED CART SCREEN IMPORT
import 'package:provider/provider.dart';
import 'package:petsy/providers/cart_provider.dart';

class ProductDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> product;

  const ProductDetailsScreen({super.key, required this.product});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  // --- MATCHING HOME SCREEN COLORS ---
  final Color _petsyGreen = const Color(0xFF2B8C61);
  final Color _petsyNavy = const Color(0xFF003466);
  final Color _appBackground = const Color(0xFFF8F9FA);

  // State Variables
  int _quantity = 1;
  bool _isFavorite = false;
  bool _isDescExpanded = false;

  // Dynamic Variation Variables
  late String _opt1Title;
  late List<String> _opt1List;
  late String _selectedOpt1;

  late String _opt2Title;
  late List<String> _opt2List;
  late String _selectedOpt2;

  // Pricing Logic
  late double _basePrice;
  late double _currentUnitPrice;

  @override
  void initState() {
    super.initState();
    _setupProductData();
  }

  void _setupProductData() {
    _basePrice =
        double.tryParse(widget.product['price']?.toString() ?? '0.0') ?? 0.0;
    _currentUnitPrice = _basePrice;
    _isFavorite = widget.product['isFavorite'] == true;

    final String pType = widget.product['productType']?.toString() ?? 'Food';

    if (pType == 'Food') {
      _opt1Title = "Flavor";
      _opt1List = ['Chicken and White Rice', 'Sweet Potato', 'Banana', 'Apple'];
      _opt2Title = "Size";
      _opt2List = ['250 g', '500 g', '1 kg', '5 kg'];
    } else if (pType == 'Toy') {
      _opt1Title = "Color";
      _opt1List = ['Classic Red', 'Ocean Blue', 'Neon Yellow'];
      _opt2Title = "Size";
      _opt2List = ['Small', 'Medium', 'Large'];
    } else {
      _opt1Title = "Color";
      _opt1List = ['Midnight Black', 'Rose Pink', 'Cloud Grey'];
      _opt2Title = "Size";
      _opt2List = ['Small', 'Medium', 'Large', 'Extra Large'];
    }

    _selectedOpt1 = _opt1List.first;
    _selectedOpt2 = _opt2List.first;
  }

  void _updateSizeAndPrice(String newSize) {
    setState(() {
      _selectedOpt2 = newSize;
      int sizeIndex = _opt2List.indexOf(newSize);

      if (sizeIndex == 0)
        _currentUnitPrice = _basePrice;
      else if (sizeIndex == 1)
        _currentUnitPrice = _basePrice * 1.8;
      else if (sizeIndex == 2)
        _currentUnitPrice = _basePrice * 3.5;
      else if (sizeIndex == 3)
        _currentUnitPrice = _basePrice * 15.0;
    });
  }

  String _formatPrice(double price) => price.toStringAsFixed(2);

  void _shareProduct() {
    final String name = widget.product['name'] ?? 'this amazing product';
    Share.share(
      'Check out $name on the Petsy App! Get it now starting at just ₱${_formatPrice(_currentUnitPrice)}. 🐾',
    );
  }

  // 🌟 LOGICAL FUNCTION: Advanced Add To Cart Notification
  void _addToCart() {
    HapticFeedback.mediumImpact();

    // 🚀 STEP 4: SEND DATA TO THE GLOBAL BRAIN (PROVIDER) 🚀
    context.read<CartProvider>().addToCart(
      widget.product,
      _quantity,
      _selectedOpt1, // Selected Flavor
      _selectedOpt2, // Selected Size
      _currentUnitPrice,
    );

    // Hide any previous snackbars so they don't pile up
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    // Show the Success Notification
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
          onPressed: () {
            // Instantly jump to the Cart Screen
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const CartScreen()),
            );
          },
        ),
      ),
    );
  }

  Widget _buildProductImage(String imageUrl) {
    if (imageUrl.isEmpty)
      return const Center(
        child: Icon(Icons.image, size: 100, color: Colors.grey),
      );
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

  @override
  Widget build(BuildContext context) {
    final String name = widget.product['name'] ?? 'Petsy Product';
    final String rating = widget.product['rating']?.toString() ?? '0.0';
    final String sold = widget.product['sold']?.toString() ?? '0';
    final String imageUrl = widget.product['image'] ?? '';
    final String brand = widget.product['brand'] ?? 'Natural Balance';

    final String description =
        (widget.product['description']?.toString().isNotEmpty == true)
        ? widget.product['description']
        : "Premium selection crafted with high-quality ingredients to ensure the health and happiness of your pet. Formulated by experts to provide balanced nutrition and everyday satisfaction.";

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
          _buildHomeStyleActionButton(
            icon: _isFavorite ? Icons.favorite : Icons.favorite_border,
            iconColor: _isFavorite ? Colors.red : _petsyNavy,
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _isFavorite = !_isFavorite);
            },
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
                    padding: const EdgeInsets.all(30),
                    child: Hero(
                      tag: imageUrl.isNotEmpty ? imageUrl : 'product_image',
                      child: _buildProductImage(imageUrl),
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
                                color: Colors.black87,
                                letterSpacing: -1,
                              ),
                            ),
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: () {
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
                                  onTap: () {
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

                        Text(
                          widget.product['productType'] == 'Food'
                              ? "Ingredients"
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
                      side: BorderSide(color: _petsyGreen, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: _addToCart,
                    child: Text(
                      "Add To Cart",
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _petsyNavy,
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
                      backgroundColor: _petsyGreen,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () {
                      HapticFeedback.heavyImpact();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CheckoutScreen(
                            product: widget.product,
                            quantity: _quantity,
                            selectedFlavor: _selectedOpt1,
                            selectedSize: _selectedOpt2,
                            unitPrice: _currentUnitPrice,
                          ),
                        ),
                      );
                    },
                    child: Text(
                      "Check Out  •  ₱${_formatPrice(_currentUnitPrice * _quantity)}",
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
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
    );
  }

  // --- UI HELPER WIDGETS ---

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
}
