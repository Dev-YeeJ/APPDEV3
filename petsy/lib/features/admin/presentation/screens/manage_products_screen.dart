import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// --- Ensure these paths match your project ---
import 'package:petsy/features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:petsy/features/admin/presentation/screens/admin_manage_orders_screen.dart';

// ============================================================================
// 🌟 SCREEN 1: ADMIN DASHBOARD (READ & ARCHIVE) 🌟
// ============================================================================
class ManageProductsScreen extends StatefulWidget {
  const ManageProductsScreen({super.key});

  @override
  State<ManageProductsScreen> createState() => _ManageProductsScreenState();
}

class _ManageProductsScreenState extends State<ManageProductsScreen> {
  final Color _petsyGreen = const Color(0xFF2B8C61);
  final Color _petsyNavy = const Color(0xFF003466);
  final Color _bgColor = const Color(0xFFF8F9FA);

  // --- 🚀 NEW SOFT DELETE (ARCHIVE) LOGIC ---
  Future<void> _toggleArchiveProduct(
    String docId,
    String productName,
    bool isCurrentlyArchived,
  ) async {
    HapticFeedback.mediumImpact();

    String action = isCurrentlyArchived ? "Restore" : "Archive";
    String description = isCurrentlyArchived
        ? "Are you sure you want to restore '$productName'? It will be visible to customers again."
        : "Are you sure you want to archive '$productName'? Customers will no longer see it in the store.";

    bool confirm =
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Colors.white,
            title: Text(
              "$action Product?",
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                color: _petsyNavy,
              ),
            ),
            content: Text(description, style: GoogleFonts.inter()),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  "Cancel",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isCurrentlyArchived
                      ? _petsyGreen
                      : Colors.red,
                ),
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  action,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (confirm) {
      await FirebaseFirestore.instance.collection('products').doc(docId).update(
        {'isArchived': !isCurrentlyArchived},
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isCurrentlyArchived
                  ? "📦 '$productName' Restored!"
                  : "📁 '$productName' Archived!",
            ),
            backgroundColor: isCurrentlyArchived
                ? _petsyGreen
                : Colors.orange.shade700,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          "Manage Products",
          style: GoogleFonts.inter(
            color: _petsyNavy,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: const SizedBox(),
        centerTitle: true,
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: FloatingActionButton.extended(
          backgroundColor: _petsyGreen,
          icon: const Icon(Icons.add, color: Colors.white),
          label: Text(
            "Add Product",
            style: GoogleFonts.inter(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          onPressed: () {
            HapticFeedback.selectionClick();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AdminProductFormScreen(),
              ),
            );
          },
        ),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('products')
            .orderBy('animalCategory')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: _petsyGreen));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                "No products found in the store.",
                style: GoogleFonts.inter(color: Colors.grey, fontSize: 16),
              ),
            );
          }

          final products = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.only(
              top: 15,
              bottom: 100,
              left: 15,
              right: 15,
            ),
            physics: const BouncingScrollPhysics(),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final doc = products[index];
              final data = doc.data() as Map<String, dynamic>;

              final String name = data['name'] ?? 'Unnamed';
              final String price = data['price']?.toString() ?? '0.0';
              final String image = data['image'] ?? '';
              final String category = data['animalCategory'] ?? 'Uncategorized';
              final String type = data['productType'] ?? 'Unknown';

              // 🚀 NEW FLAGS
              final bool isArchived = data['isArchived'] ?? false;
              final bool isOutOfStock = data['isOutOfStock'] ?? false;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: isArchived
                      ? Colors.grey.shade100
                      : Colors.white, // Grey out if archived
                  borderRadius: BorderRadius.circular(16),
                  border: isArchived
                      ? Border.all(color: Colors.grey.shade300)
                      : null,
                  boxShadow: isArchived
                      ? []
                      : [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 8,
                  ),
                  leading: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        height: 50,
                        width: 50,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F6F8),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Opacity(
                          opacity: isArchived ? 0.5 : 1.0,
                          child: image.startsWith('http')
                              ? Image.network(image)
                              : Image.asset(
                                  image,
                                  errorBuilder: (c, e, s) => const Icon(
                                    Icons.image,
                                    color: Colors.grey,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            color: isArchived ? Colors.grey : Colors.black87,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // 🚀 STATUS BADGES
                      if (isArchived)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            "ARCHIVED",
                            style: GoogleFonts.inter(
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              color: Colors.red.shade700,
                            ),
                          ),
                        )
                      else if (isOutOfStock)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            "OUT OF STOCK",
                            style: GoogleFonts.inter(
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade700,
                            ),
                          ),
                        ),
                    ],
                  ),
                  subtitle: Text(
                    "$category • $type \n₱$price",
                    style: GoogleFonts.inter(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.edit_outlined,
                          color: isArchived ? Colors.grey : _petsyGreen,
                        ),
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AdminProductFormScreen(
                                docId: doc.id,
                                productData: data,
                              ),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: Icon(
                          isArchived ? Icons.restore : Icons.archive_outlined,
                          color: isArchived ? Colors.blue : Colors.red,
                        ),
                        onPressed: () =>
                            _toggleArchiveProduct(doc.id, name, isArchived),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),

      // --- ADMIN SPECIFIC BOTTOM NAV ---
      bottomNavigationBar: Container(
        height: 70,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildBottomNavItem(
              Icons.dashboard_outlined,
              "Dashboard",
              false,
              () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdminDashboardScreen(),
                ),
              ),
            ),
            _buildBottomNavItem(Icons.inventory_2, "Products", true, () {}),
            _buildBottomNavItem(
              Icons.receipt_long_outlined,
              "Orders",
              false,
              () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdminManageOrdersScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavItem(
    IconData icon,
    String label,
    bool isActive,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isActive ? _petsyGreen : Colors.grey.shade500,
            size: 26,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
              color: isActive ? _petsyGreen : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 🌟 SCREEN 2: THE DYNAMIC FORM (CREATE & UPDATE) 🌟
// ============================================================================
class AdminProductFormScreen extends StatefulWidget {
  final String? docId;
  final Map<String, dynamic>? productData;

  const AdminProductFormScreen({super.key, this.docId, this.productData});

  @override
  State<AdminProductFormScreen> createState() => _AdminProductFormScreenState();
}

class _AdminProductFormScreenState extends State<AdminProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final Color _petsyGreen = const Color(0xFF2B8C61);
  final Color _petsyNavy = const Color(0xFF003466);

  // Form Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _brandController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _ratingController = TextEditingController();
  final TextEditingController _soldController = TextEditingController();
  final TextEditingController _imageController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _flavorsController = TextEditingController();
  final TextEditingController _sizesController = TextEditingController();

  String _selectedCategory = "Dog";
  String _selectedType = "Food";

  bool _isBestSeller = false;
  bool _isNew = false;
  bool _isFavorite = false;
  bool _isOutOfStock = false; // 🚀 NEW OUT OF STOCK TOGGLE

  final List<String> _categories = [
    "Dog",
    "Cat",
    "Fish",
    "Birds",
    "Small Pets",
  ];
  final List<String> _types = [
    "Food",
    "Treats",
    "Toy",
    "Accessory",
    "Medicine",
    "Grooming",
  ];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.productData != null) {
      final data = widget.productData!;
      _nameController.text = data['name'] ?? '';
      _brandController.text = data['brand'] ?? '';
      _priceController.text = data['price']?.toString() ?? '';
      _ratingController.text = data['rating']?.toString() ?? '5.0';
      _soldController.text = data['sold']?.toString() ?? '0';
      _imageController.text = data['image'] ?? '';
      _descController.text = data['description'] ?? '';

      if (data['flavors'] != null && data['flavors'] is List) {
        _flavorsController.text = (data['flavors'] as List).join(', ');
      }
      if (data['sizes'] != null && data['sizes'] is List) {
        _sizesController.text = (data['sizes'] as List).join(', ');
      }
      if (_categories.contains(data['animalCategory'])) {
        _selectedCategory = data['animalCategory'];
      }
      if (_types.contains(data['productType'])) {
        _selectedType = data['productType'];
      }

      _isBestSeller = data['isBestSeller'] ?? false;
      _isNew = data['isNew'] ?? false;
      _isFavorite = data['isFavorite'] ?? false;
      _isOutOfStock = data['isOutOfStock'] ?? false; // Load existing state
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _priceController.dispose();
    _ratingController.dispose();
    _soldController.dispose();
    _imageController.dispose();
    _descController.dispose();
    _flavorsController.dispose();
    _sizesController.dispose();
    super.dispose();
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      List<String> flavorsList = _flavorsController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      List<String> sizesList = _sizesController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      final productMap = {
        "name": _nameController.text.trim(),
        "brand": _brandController.text.trim(),
        "description": _descController.text.trim(),
        "price": double.tryParse(_priceController.text.trim()) ?? 0.0,
        "rating": double.tryParse(_ratingController.text.trim()) ?? 5.0,
        "sold": _soldController.text.trim(),
        "image": _imageController.text.trim(),
        "animalCategory": _selectedCategory,
        "productType": _selectedType,
        "flavors": flavorsList,
        "sizes": sizesList,
        "isBestSeller": _isBestSeller,
        "isNew": _isNew,
        "isFavorite": _isFavorite,
        "isOutOfStock": _isOutOfStock, // 🚀 Save the out of stock state
        "isArchived":
            widget.productData?['isArchived'] ??
            false, // Preserve archive state if updating
      };

      if (widget.docId == null) {
        await FirebaseFirestore.instance.collection('products').add(productMap);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("✅ New Product Added!"),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        await FirebaseFirestore.instance
            .collection('products')
            .doc(widget.docId)
            .update(productMap);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("✅ Product Updated!"),
              backgroundColor: Colors.blue,
            ),
          );
        }
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isEditing = widget.docId != null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          isEditing ? "Edit Product" : "Add New Product",
          style: GoogleFonts.inter(
            color: _petsyNavy,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: const BackButton(color: Colors.black87),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        physics: const BouncingScrollPhysics(),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Basic Details",
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: _petsyNavy,
                ),
              ),
              const SizedBox(height: 15),
              _buildTextField(
                _nameController,
                "Product Name",
                isRequired: true,
              ),
              _buildTextField(_brandController, "Brand Name (e.g. Purina)"),

              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      _priceController,
                      "Price (₱)",
                      isNumber: true,
                      isRequired: true,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: _buildTextField(_soldController, "Sold (e.g. 1.2k)"),
                  ),
                ],
              ),

              _buildTextField(
                _descController,
                "Full Description",
                isMultiLine: true,
              ),
              _buildTextField(
                _imageController,
                "Image Path (assets/images/... or http...)",
              ),
              const SizedBox(height: 25),

              Text(
                "Categories & Variations",
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: _petsyNavy,
                ),
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: _buildDropdown(
                      "Animal",
                      _categories,
                      _selectedCategory,
                      (v) => setState(() => _selectedCategory = v!),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: _buildDropdown(
                      "Type",
                      _types,
                      _selectedType,
                      (v) => setState(() => _selectedType = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              _buildTextField(
                _flavorsController,
                "Flavors/Variants (comma separated)",
              ),
              Text(
                "Example: Chicken, Beef, Salmon",
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
              const SizedBox(height: 15),
              _buildTextField(_sizesController, "Sizes (comma separated)"),
              Text(
                "Example: 500g, 1kg, 2kg",
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
              const SizedBox(height: 25),

              // --- SECTION: DISPLAY TAGS ---
              Text(
                "Store Front Tags",
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: _petsyNavy,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: Text(
                        "🏆 Best Seller",
                        style: GoogleFonts.inter(fontSize: 14),
                      ),
                      activeColor: _petsyGreen,
                      value: _isBestSeller,
                      onChanged: (val) => setState(() => _isBestSeller = val),
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: Text(
                        "✨ What's New",
                        style: GoogleFonts.inter(fontSize: 14),
                      ),
                      activeColor: _petsyGreen,
                      value: _isNew,
                      onChanged: (val) => setState(() => _isNew = val),
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: Text(
                        "❤️ Petsy Favorite Pick",
                        style: GoogleFonts.inter(fontSize: 14),
                      ),
                      activeColor: _petsyGreen,
                      value: _isFavorite,
                      onChanged: (val) => setState(() => _isFavorite = val),
                    ),
                    const Divider(height: 1),
                    // 🚀 NEW TOGGLE
                    SwitchListTile(
                      title: Text(
                        "🚨 Out of Stock",
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade700,
                        ),
                      ),
                      activeColor: Colors.red,
                      value: _isOutOfStock,
                      onChanged: (val) => setState(() => _isOutOfStock = val),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // --- SUBMIT BUTTON ---
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _petsyGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  onPressed: _isLoading ? null : _saveProduct,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          isEditing ? "Update Product" : "Save New Product",
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
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
    );
  }

  // --- REUSABLE UI BUILDERS ---
  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    bool isNumber = false,
    bool isRequired = false,
    bool isMultiLine = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumber
            ? TextInputType.number
            : (isMultiLine ? TextInputType.multiline : TextInputType.text),
        maxLines: isMultiLine ? 3 : 1,
        style: GoogleFonts.inter(fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.inter(
            color: Colors.grey.shade600,
            fontSize: 13,
          ),
          filled: true,
          fillColor: const Color(0xFFF8F9FA),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: _petsyGreen),
          ),
        ),
        validator: isRequired
            ? (val) => val == null || val.isEmpty ? "Required field" : null
            : null,
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    List<String> items,
    String currentValue,
    Function(String?) onChanged,
  ) {
    return DropdownButtonFormField<String>(
      value: currentValue,
      icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
      style: GoogleFonts.inter(fontSize: 14, color: Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(
          color: Colors.grey.shade600,
          fontSize: 13,
        ),
        filled: true,
        fillColor: const Color(0xFFF8F9FA),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      items: items
          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
          .toList(),
      onChanged: onChanged,
    );
  }
}
