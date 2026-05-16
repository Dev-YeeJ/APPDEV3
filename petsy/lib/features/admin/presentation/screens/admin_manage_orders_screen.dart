import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminManageOrdersScreen extends StatefulWidget {
  const AdminManageOrdersScreen({super.key});

  @override
  State<AdminManageOrdersScreen> createState() =>
      _AdminManageOrdersScreenState();
}

class _AdminManageOrdersScreenState extends State<AdminManageOrdersScreen> {
  final Color _petsyGreen = const Color(0xFF2B8C61);
  final Color _petsyNavy = const Color(0xFF003466);
  final Color _bgColor = const Color(0xFFF4F6F8);

  String _formatPrice(double price) => price.toStringAsFixed(2);

  // 🚀 LOGIC: Admin updates order status
  Future<void> _updateStatus(DocumentReference docRef, String newStatus) async {
    HapticFeedback.lightImpact();
    try {
      await docRef.update({'status': newStatus});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Order status updated to: $newStatus"),
            backgroundColor: _petsyGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
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
        leading: const BackButton(color: Colors.black87),
        title: Text(
          "Global Order Manager",
          style: GoogleFonts.inter(
            color: _petsyNavy,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      // 🚀 MAGIC: collectionGroup grabs ALL orders from EVERY user instantly!
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collectionGroup('orders')
            .orderBy('orderDate', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            // 🚀 FIX: This forces Flutter to print the magic URL into your VS Code Console!
            print("🔥 FIREBASE MAGIC LINK ERROR: ${snapshot.error}");

            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  "Database Index Required. Check your debug console for the Firebase link to create the index.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                "No customer orders found in the database.",
                style: GoogleFonts.inter(color: Colors.grey),
              ),
            );
          }

          final orders = snapshot.data!.docs;

          return ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(20),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final doc = orders[index];
              final data = doc.data() as Map<String, dynamic>;

              final orderId = doc.id.substring(0, 8).toUpperCase();
              // Extract the user ID from the document path!
              final customerId =
                  doc.reference.parent.parent?.id
                      .substring(0, 8)
                      .toUpperCase() ??
                  "Unknown";
              final status = data['status'] ?? 'toPay';
              final total = (data['totalPrice'] as num?)?.toDouble() ?? 0.0;
              final paymentMethod = data['paymentMethod'] ?? 'COD';

              // Safely extract items summary
              List<dynamic> items = data['items'] ?? [];
              String itemSummary = items.isEmpty
                  ? "No items"
                  : "${items.length} item(s) - e.g., ${items[0]['name']}";

              return Container(
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: _petsyNavy.withOpacity(0.03),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "ORDER #$orderId",
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.bold,
                                  color: _petsyNavy,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                "Customer ID: $customerId",
                                style: GoogleFonts.inter(
                                  color: Colors.grey.shade600,
                                  fontSize: 11,
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
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              paymentMethod,
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Details
                    Padding(
                      padding: const EdgeInsets.all(15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.inventory_2_outlined,
                                size: 16,
                                color: Colors.grey.shade500,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  itemSummary,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: Colors.black87,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Icon(
                                Icons.payments_outlined,
                                size: 16,
                                color: Colors.grey.shade500,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "Total Value: ₱${_formatPrice(total)}",
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: _petsyGreen,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: Colors.black12),

                    // Admin Action Footer
                    Padding(
                      padding: const EdgeInsets.all(15),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Update Status:",
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          Container(
                            height: 35,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              border: Border.all(color: _petsyGreen),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: status,
                                icon: Icon(
                                  Icons.keyboard_arrow_down,
                                  color: _petsyGreen,
                                ),
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: _petsyGreen,
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'toPay',
                                    child: Text("To Pay / Pending"),
                                  ),
                                  DropdownMenuItem(
                                    value: 'toShip',
                                    child: Text("To Ship (Preparing)"),
                                  ),
                                  DropdownMenuItem(
                                    value: 'toReceive',
                                    child: Text("To Receive (Shipped)"),
                                  ),
                                  DropdownMenuItem(
                                    value: 'completed',
                                    child: Text("Completed"),
                                  ),
                                  DropdownMenuItem(
                                    value: 'cancelled',
                                    child: Text("Cancelled"),
                                  ),
                                ],
                                onChanged: (newStatus) {
                                  if (newStatus != null) {
                                    _updateStatus(doc.reference, newStatus);
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
