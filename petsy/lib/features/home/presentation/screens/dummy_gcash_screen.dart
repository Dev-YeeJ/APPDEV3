import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class DummyGCashScreen extends StatefulWidget {
  final double amountToPay;

  const DummyGCashScreen({super.key, required this.amountToPay});

  @override
  State<DummyGCashScreen> createState() => _DummyGCashScreenState();
}

class _DummyGCashScreenState extends State<DummyGCashScreen> {
  // --- GCASH BRAND COLORS ---
  final Color _gcashBlue = const Color(0xFF007DFE);
  final Color _gcashDarkBlue = const Color(0xFF005BBF);
  final Color _petsyNavy = const Color(0xFF003466);

  final _formKey = GlobalKey<FormState>();

  String mobileNumber = '';
  String mpin = '';

  bool _isProcessing = false;

  void _processPayment() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isProcessing = true);
      HapticFeedback.mediumImpact();

      // Simulate contacting GCash servers
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
        backgroundColor: _gcashBlue,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        title: Text(
          "GCash Payment",
          style: GoogleFonts.inter(
            color: Colors.white,
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
                child: Column(
                  children: [
                    // --- BLUE HEADER SECTION ---
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                      decoration: BoxDecoration(
                        color: _gcashBlue,
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(30),
                          bottomRight: Radius.circular(30),
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(15),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.account_balance_wallet,
                              color: _gcashBlue,
                              size: 40,
                            ),
                          ),
                          const SizedBox(height: 15),
                          Text(
                            "Petsy Store",
                            style: GoogleFonts.inter(
                              color: Colors.white70,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            "₱ ${widget.amountToPay.toStringAsFixed(2)}",
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // --- INPUT FORM ---
                    Transform.translate(
                      offset: const Offset(0, -20),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        padding: const EdgeInsets.all(25),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 20,
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
                                "Login to pay",
                                style: GoogleFonts.inter(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: _petsyNavy,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Enter your GCash mobile number and MPIN to authorize this transaction.",
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 25),

                              // Mobile Number Input
                              TextFormField(
                                keyboardType: TextInputType.phone,
                                maxLength: 11,
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                decoration: InputDecoration(
                                  labelText: "Mobile Number",
                                  hintText: "09XX XXX XXXX",
                                  counterText: "",
                                  prefixIcon: Icon(
                                    Icons.phone_android,
                                    color: _gcashBlue,
                                  ),
                                  filled: true,
                                  fillColor: const Color(0xFFF8F9FA),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: _gcashBlue,
                                      width: 1.5,
                                    ),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Colors.red.shade300,
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                                onChanged: (val) =>
                                    setState(() => mobileNumber = val),
                                validator: (val) {
                                  if (val == null || val.isEmpty) {
                                    return "Required";
                                  }
                                  if (val.length != 11 ||
                                      !val.startsWith('09')) {
                                    return "Enter a valid 11-digit number";
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),

                              // MPIN Input
                              TextFormField(
                                keyboardType: TextInputType.number,
                                maxLength: 4,
                                obscureText: true,
                                // 🚀 FIXED: Changed from obscureCharacter to obscuringCharacter
                                obscuringCharacter: '●',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                  letterSpacing: 5,
                                ),
                                decoration: InputDecoration(
                                  labelText: "4-Digit MPIN",
                                  hintText: "••••",
                                  counterText: "",
                                  prefixIcon: Icon(
                                    Icons.lock_outline,
                                    color: _gcashBlue,
                                  ),
                                  filled: true,
                                  fillColor: const Color(0xFFF8F9FA),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: _gcashBlue,
                                      width: 1.5,
                                    ),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Colors.red.shade300,
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                                onChanged: (val) => setState(() => mpin = val),
                                validator: (val) {
                                  if (val == null || val.length != 4) {
                                    return "Enter 4-digit MPIN";
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Secure Footer
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.security,
                          color: Colors.grey.shade500,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "Secured by GCash",
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w600,
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
                    backgroundColor: _gcashBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    elevation: 0,
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
}
