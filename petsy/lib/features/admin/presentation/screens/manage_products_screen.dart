import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class ManageProductsScreen extends StatefulWidget {
  const ManageProductsScreen({super.key});

  @override
  State<ManageProductsScreen> createState() => _ManageProductsScreenState();
}

class _ManageProductsScreenState extends State<ManageProductsScreen> {
  final _formKey = GlobalKey<FormState>();

  // Theme Colors
  final Color _petsyGreen = const Color(0xFF2B8C61);
  final Color _petsyNavy = const Color(0xFF003466);

  // Form Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _ratingController = TextEditingController(
    text: "5.0",
  );
  final TextEditingController _soldController = TextEditingController(
    text: "0",
  );
  final TextEditingController _imageController = TextEditingController(
    text: "assets/images/category_dog.png",
  );

  // Dropdown & Booleans
  String _selectedCategory = "Dog";
  String _selectedType = "Food";
  bool _isBestSeller = false;
  bool _isNew = true;
  bool _isFavorite = false;

  final List<String> _categories = ["Dog", "Cat", "Fish", "Birds"];
  final List<String> _types = ["Food", "Toy", "Accessories", "Medicine"];

  bool _isLoading = false;

  // --- 1. ADD SINGLE PRODUCT TO FIREBASE ---
  Future<void> _addProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance.collection('products').add({
        "name": _nameController.text.trim(),
        "price": double.tryParse(_priceController.text.trim()) ?? 0.0,
        "rating": double.tryParse(_ratingController.text.trim()) ?? 5.0,
        "sold": _soldController.text.trim(),
        "image": _imageController.text.trim(),
        "animalCategory": _selectedCategory,
        "productType": _selectedType,
        "isBestSeller": _isBestSeller,
        "isNew": _isNew,
        "isFavorite": _isFavorite,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Product added successfully!"),
            backgroundColor: Colors.green,
          ),
        );
        _formKey.currentState!.reset(); // Clear the form
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // --- 2. BULK UPLOAD DUMMY DATA (Developer Tool) ---
  Future<void> _uploadDummyProducts() async {
    final CollectionReference productsRef = FirebaseFirestore.instance
        .collection('products');

    final List<Map<String, dynamic>> dummyProducts = [
      // ================= 1. BEST SELLERS (6 Items) =================
      {
        "name": "Baked Dog Treats",
        "price": 150.00,
        "rating": 4.8,
        "sold": "2.1k",
        "image": "assets/images/products/baked_dog_treats.jpg",
        "animalCategory": "Dog",
        "productType": "Food",
        "isBestSeller": true,
        "isNew": false,
        "isFavorite": false,
      },
      {
        "name": "Tough Bone Dog Toy",
        "price": 220.00,
        "rating": 4.9,
        "sold": "3.4k",
        "image": "assets/images/products/bone_dog_toy.jpg",
        "animalCategory": "Dog",
        "productType": "Toy",
        "isBestSeller": true,
        "isNew": false,
        "isFavorite": false,
      },
      {
        "name": "Canned Cat Food",
        "price": 85.00,
        "rating": 4.7,
        "sold": "5.2k",
        "image": "assets/images/products/canned_catfood.jpg",
        "animalCategory": "Cat",
        "productType": "Food",
        "isBestSeller": true,
        "isNew": false,
        "isFavorite": false,
      },
      {
        "name": "Cooked Dog Food",
        "price": 170.00,
        "rating": 4.8,
        "sold": "2.2k",
        "image": "assets/images/products/cooked_dog_food.jpg",
        "animalCategory": "Dog",
        "productType": "Food",
        "isBestSeller": true,
        "isNew": false,
        "isFavorite": false,
      },
      {
        "name": "Plant Based Cat Litter",
        "price": 250.00,
        "rating": 4.9,
        "sold": "800",
        "image": "assets/images/products/plant_based_cat_litter.jpg",
        "animalCategory": "Cat",
        "productType": "Accessories",
        "isBestSeller": true,
        "isNew": false,
        "isFavorite": false,
      },
      {
        "name": "Dog Training Treats",
        "price": 120.00,
        "rating": 4.7,
        "sold": "5.1k",
        "image": "assets/images/products/dog_training_treats.jpg",
        "animalCategory": "Dog",
        "productType": "Food",
        "isBestSeller": true,
        "isNew": false,
        "isFavorite": false,
      },

      // ================= 2. WHAT'S NEW (6 Items) =================
      {
        "name": "Pet Cleansing Wipes",
        "price": 110.00,
        "rating": 5.0,
        "sold": "150",
        "image": "assets/images/products/cleansing_wipes.jpg",
        "animalCategory": "Dog",
        "productType": "Accessories",
        "isBestSeller": false,
        "isNew": true,
        "isFavorite": false,
      },
      {
        "name": "Dental Wipes",
        "price": 130.00,
        "rating": 4.9,
        "sold": "230",
        "image": "assets/images/products/dental_wipes.jpg",
        "animalCategory": "Cat",
        "productType": "Accessories",
        "isBestSeller": false,
        "isNew": true,
        "isFavorite": false,
      },
      {
        "name": "Digestive Aid Stick",
        "price": 95.00,
        "rating": 4.8,
        "sold": "410",
        "image": "assets/images/products/digestive_aid_stick.jpg",
        "animalCategory": "Dog",
        "productType": "Medicine",
        "isBestSeller": false,
        "isNew": true,
        "isFavorite": false,
      },
      {
        "name": "Dental Chew Treat",
        "price": 145.00,
        "rating": 4.6,
        "sold": "320",
        "image": "assets/images/products/dog_dental_chew_treat.jpg",
        "animalCategory": "Dog",
        "productType": "Food",
        "isBestSeller": false,
        "isNew": true,
        "isFavorite": false,
      },
      {
        "name": "Dried Raw Dog Treats",
        "price": 210.00,
        "rating": 4.9,
        "sold": "500",
        "image": "assets/images/products/dried_raw_dog_treats.jpg",
        "animalCategory": "Dog",
        "productType": "Food",
        "isBestSeller": false,
        "isNew": true,
        "isFavorite": false,
      },
      {
        "name": "Reversible Dog Jacket",
        "price": 450.00,
        "rating": 5.0,
        "sold": "85",
        "image": "assets/images/products/reversable_dog_jacket.jpg",
        "animalCategory": "Dog",
        "productType": "Accessories",
        "isBestSeller": false,
        "isNew": true,
        "isFavorite": false,
      },

      // ================= 3. PETSY FAVORITE PICKS (6 Items) =================
      {
        "name": "Premium Dry Dog Food",
        "price": 850.00,
        "rating": 4.9,
        "sold": "1.8k",
        "image": "assets/images/products/dry_dog_food.jpg",
        "animalCategory": "Dog",
        "productType": "Food",
        "isBestSeller": false,
        "isNew": false,
        "isFavorite": true,
      },
      {
        "name": "Frozen Goat Milk",
        "price": 180.00,
        "rating": 5.0,
        "sold": "950",
        "image": "assets/images/products/frozen_goat_milk.jpg",
        "animalCategory": "Cat",
        "productType": "Food",
        "isBestSeller": false,
        "isNew": false,
        "isFavorite": true,
      },
      {
        "name": "Lickable Cat Treats",
        "price": 125.00,
        "rating": 4.8,
        "sold": "2.7k",
        "image": "assets/images/products/lickable_cat_treats.jpg",
        "animalCategory": "Cat",
        "productType": "Food",
        "isBestSeller": false,
        "isNew": false,
        "isFavorite": true,
      },
      {
        "name": "Original Dog Treats",
        "price": 140.00,
        "rating": 4.7,
        "sold": "1.5k",
        "image": "assets/images/products/original_regular_dog_treats.jpg",
        "animalCategory": "Dog",
        "productType": "Food",
        "isBestSeller": false,
        "isNew": false,
        "isFavorite": true,
      },
      {
        "name": "PetAg Nursing Kit",
        "price": 320.00,
        "rating": 4.9,
        "sold": "430",
        "image": "assets/images/products/petag_nursing_kit.jpg",
        "animalCategory": "Cat",
        "productType": "Accessories",
        "isBestSeller": false,
        "isNew": false,
        "isFavorite": true,
      },
      {
        "name": "Eco Poop Bags",
        "price": 99.00,
        "rating": 4.9,
        "sold": "6.8k",
        "image": "assets/images/products/poop_bags.jpg",
        "animalCategory": "Dog",
        "productType": "Accessories",
        "isBestSeller": false,
        "isNew": false,
        "isFavorite": true,
      },
    ];

    try {
      for (var product in dummyProducts) {
        await productsRef.add(product);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Dummy Products uploaded!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print("Error uploading products: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          "Manage Products",
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        backgroundColor: _petsyNavy,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Add New Product",
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _petsyNavy,
                ),
              ),
              const SizedBox(height: 15),

              // --- TEXT INPUTS ---
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: "Product Name",
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value!.isEmpty ? "Enter a name" : null,
              ),
              const SizedBox(height: 15),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Price (₱)",
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value!.isEmpty ? "Enter price" : null,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: TextFormField(
                      controller: _soldController,
                      decoration: const InputDecoration(
                        labelText: "Sold (e.g. 1.2k)",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: _imageController,
                decoration: const InputDecoration(
                  labelText:
                      "Image Path (e.g. assets/images/dog.png or http...)",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),

              // --- DROPDOWNS ---
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(
                        labelText: "Pet Category",
                        border: OutlineInputBorder(),
                      ),
                      items: _categories
                          .map(
                            (c) => DropdownMenuItem(value: c, child: Text(c)),
                          )
                          .toList(),
                      onChanged: (val) =>
                          setState(() => _selectedCategory = val!),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedType,
                      decoration: const InputDecoration(
                        labelText: "Item Type",
                        border: OutlineInputBorder(),
                      ),
                      items: _types
                          .map(
                            (t) => DropdownMenuItem(value: t, child: Text(t)),
                          )
                          .toList(),
                      onChanged: (val) => setState(() => _selectedType = val!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // --- TOGGLES (TAGS) ---
              Text(
                "Product Tags",
                style: GoogleFonts.inter(fontWeight: FontWeight.bold),
              ),
              Container(
                margin: const EdgeInsets.only(top: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text("Best Seller"),
                      activeColor: _petsyGreen,
                      value: _isBestSeller,
                      onChanged: (val) => setState(() => _isBestSeller = val),
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: const Text("What's New"),
                      activeColor: _petsyGreen,
                      value: _isNew,
                      onChanged: (val) => setState(() => _isNew = val),
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: const Text("Favorite Pick"),
                      activeColor: _petsyGreen,
                      value: _isFavorite,
                      onChanged: (val) => setState(() => _isFavorite = val),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // --- SUBMIT BUTTON ---
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _petsyGreen,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _isLoading ? null : _addProduct,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Save Product to Firebase",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 50),
              const Divider(thickness: 2),
              const SizedBox(height: 20),

              // --- DEVELOPER BULK UPLOAD ---
              Center(
                child: TextButton.icon(
                  icon: const Icon(Icons.warning, color: Colors.orange),
                  label: const Text(
                    "Dev Tool: Upload Dummy Data Batch",
                    style: TextStyle(color: Colors.orange),
                  ),
                  onPressed: _uploadDummyProducts,
                ),
              ),
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }
}
