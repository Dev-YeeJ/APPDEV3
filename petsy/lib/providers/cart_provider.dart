import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CartProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _items = [];
  StreamSubscription<QuerySnapshot>? _cartSubscription;

  List<Map<String, dynamic>> get items => _items;

  CartProvider() {
    _listenToCart();
  }

  // --- 🌟 MAGIC: REAL-TIME CLOUD SYNC ---
  // This listens to the user's cart in Firebase. If they add an item on another device,
  // it instantly updates the cart on this device!
  void _listenToCart() {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _cartSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('cart')
        .snapshots()
        .listen((snapshot) {
          _items = snapshot.docs.map((doc) {
            final data = doc.data();
            // We save the document ID so we can easily update/delete it later
            data['id'] = doc.id;
            return data;
          }).toList();

          notifyListeners(); // Tell the UI to rebuild!
        });
  }

  @override
  void dispose() {
    _cartSubscription?.cancel();
    super.dispose();
  }

  // --- ADD TO CLOUD CART ---
  Future<void> addToCart(
    Map<String, dynamic> product,
    int quantity,
    String flavor,
    String size,
    double price,
  ) async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final cartRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('cart');

    // 1. Check if this exact item (same name, flavor, and size) is already in the local cart
    int existingIndex = _items.indexWhere(
      (item) =>
          item['name'] == product['name'] &&
          item['flavor'] == flavor &&
          item['size'] == size,
    );

    if (existingIndex >= 0) {
      // 2. If it exists, update the quantity in Firebase
      String docId = _items[existingIndex]['id'];
      await cartRef.doc(docId).update({
        'quantity': FieldValue.increment(quantity),
      });
    } else {
      // 3. If it doesn't exist, create a new document in Firebase
      await cartRef.add({
        'name': product['name'] ?? 'Unknown Item',
        'brand': product['brand'] ?? 'Petsy',
        'image': product['image'] ?? '',
        'flavor': flavor,
        'size': size,
        'price': price,
        'quantity': quantity,
        'original_product': product,
        'addedAt': FieldValue.serverTimestamp(), // Keeps the cart ordered
      });
    }
  }

  // --- UPDATE CLOUD QUANTITY (+ or -) ---
  Future<void> updateQuantity(int index, int change) async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final item = _items[index];
    final String docId = item['id'];
    final int newQuantity = item['quantity'] + change;

    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('cart')
        .doc(docId);

    if (newQuantity > 0) {
      // Update quantity in Firebase
      await docRef.update({'quantity': newQuantity});
    } else {
      // If it hits 0, delete it from Firebase
      await docRef.delete();
    }
  }

  // --- EMPTY CLOUD CART (Useful after Checkout!) ---
  Future<void> clearCart() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final cartRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('cart');

    // Get all items in the cart and delete them one by one
    final snapshot = await cartRef.get();
    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }

  // --- LIVE SUBTOTAL CALCULATOR ---
  double get subtotal {
    double total = 0;
    for (var item in _items) {
      // Safely handle numbers from Firebase
      double itemPrice = (item['price'] as num).toDouble();
      int itemQty = item['quantity'] as int;
      total += (itemPrice * itemQty);
    }
    return total;
  }
}
