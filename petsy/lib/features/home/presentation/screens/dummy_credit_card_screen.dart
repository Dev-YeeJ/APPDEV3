import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class DummyCreditCardScreen extends StatefulWidget {
  final double amountToPay;

  const DummyCreditCardScreen({super.key, required this.amountToPay});

  @override
  State<DummyCreditCardScreen> createState() => _DummyCreditCardScreenState();
}

class _DummyCreditCardScreenState extends State<DummyCreditCardScreen> {
  final Color _petsyGreen = const Color(0xFF2B8C61);
  final Color _petsyNavy = const Color(0xFF003466);

  final _formKey = GlobalKey<FormState>();

  String cardNumber = '';
  String expiryDate = '';
  String cardHolderName = '';
  String cvvCode = '';
  bool isCvvFocused = false;

  bool _isProcessing = false;

  void _processPayment() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isProcessing = true);
      HapticFeedback.mediumImpact();

      // Simulate a network request to a payment gateway
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        setState(() => _isProcessing = false);
        HapticFeedback.heavyImpact();
        // Return 'true' to tell the Checkout Screen the payment was successful!
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.black87),
        title: Text(
          "Secure Payment",
          style: GoogleFonts.inter(
            color: _petsyNavy,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // --- THE VISUAL CREDIT CARD ---
                    _buildVisualCard(),
                    const SizedBox(height: 30),

                    // --- THE INPUT FORM ---
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Card Details",
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: _petsyNavy,
                              ),
                            ),
                            const SizedBox(height: 20),

                            _buildTextField(
                              label: "Card Number",
                              hint: "4242 4242 4242 4242",
                              icon: Icons.credit_card,
                              keyboardType: TextInputType.number,
                              maxLength: 19,
                              onChanged: (val) =>
                                  setState(() => cardNumber = val),
                              validator: (val) => val == null || val.length < 16
                                  ? "Invalid Card Number"
                                  : null,
                            ),
                            const SizedBox(height: 15),

                            _buildTextField(
                              label: "Cardholder Name",
                              hint: "JAIME YEE II",
                              icon: Icons.person_outline,
                              onChanged: (val) => setState(
                                () => cardHolderName = val.toUpperCase(),
                              ),
                              validator: (val) => val == null || val.isEmpty
                                  ? "Name is required"
                                  : null,
                            ),
                            const SizedBox(height: 15),

                            Row(
                              children: [
                                Expanded(
                                  child: _buildTextField(
                                    label: "Expiry Date",
                                    hint: "MM/YY",
                                    icon: Icons.calendar_today,
                                    keyboardType: TextInputType.number,
                                    maxLength: 5,
                                    onChanged: (val) =>
                                        setState(() => expiryDate = val),
                                    validator: (val) =>
                                        val == null || val.length < 5
                                        ? "Invalid Date"
                                        : null,
                                  ),
                                ),
                                const SizedBox(width: 15),
                                Expanded(
                                  child: Focus(
                                    onFocusChange: (hasFocus) =>
                                        setState(() => isCvvFocused = hasFocus),
                                    child: _buildTextField(
                                      label: "CVV",
                                      hint: "123",
                                      icon: Icons.lock_outline,
                                      keyboardType: TextInputType.number,
                                      maxLength: 3,
                                      obscureText: true,
                                      onChanged: (val) =>
                                          setState(() => cvvCode = val),
                                      validator: (val) =>
                                          val == null || val.length < 3
                                          ? "Invalid CVV"
                                          : null,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.lock,
                          color: Colors.green.shade600,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "Payments are secure and encrypted.",
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // --- PAY BUTTON ---
            Container(
              padding: const EdgeInsets.all(25),
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
              child: SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _petsyGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: _isProcessing ? null : _processPayment,
                  child: _isProcessing
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                      : Text(
                          "Pay ₱${widget.amountToPay.toStringAsFixed(2)}",
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- UI WIDGET: THE VISUAL CARD ---
  Widget _buildVisualCard() {
    return Container(
      height: 200,
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_petsyNavy, const Color(0xFF1A5F99)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _petsyNavy.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Image.asset(
                'assets/images/petsylogowhite.png',
                height: 20,
                errorBuilder: (c, e, s) => Text(
                  "Petsy Pay",
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Icon(Icons.contactless, color: Colors.white70, size: 28),
            ],
          ),
          Text(
            cardNumber.isEmpty ? "XXXX XXXX XXXX XXXX" : cardNumber,
            // 🚀 FIX: Used robotoMono instead of monospace!
            style: GoogleFonts.robotoMono(
              color: Colors.white,
              fontSize: 22,
              letterSpacing: 2,
              fontWeight: FontWeight.w600,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "CARDHOLDER",
                    style: GoogleFonts.inter(
                      color: Colors.white54,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    cardHolderName.isEmpty ? "YOUR NAME" : cardHolderName,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "EXPIRES",
                    style: GoogleFonts.inter(
                      color: Colors.white54,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    expiryDate.isEmpty ? "MM/YY" : expiryDate,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- UI WIDGET: TEXT FIELDS ---
  Widget _buildTextField({
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    int? maxLength,
    bool obscureText = false,
    required Function(String) onChanged,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      keyboardType: keyboardType,
      maxLength: maxLength,
      obscureText: obscureText,
      onChanged: onChanged,
      validator: validator,
      style: GoogleFonts.inter(
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        counterText: "", // Hides the character counter
        prefixIcon: Icon(icon, color: _petsyGreen),
        filled: true,
        fillColor: const Color(0xFFF4F6F8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _petsyGreen, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade300, width: 1.5),
        ),
      ),
    );
  }
}
