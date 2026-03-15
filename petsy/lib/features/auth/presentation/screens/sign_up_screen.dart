import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'complete_profile_screen.dart';
// Ensure you import the new sign_in_screen
import 'sign_in_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // State
  bool _isAccepted = false;
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmVisible = false;

  // Colors
  final Color _petsyGreen = const Color(0xFF339967);
  final Color _petsyNavy = const Color(0xFF003466);
  final Color _cardColor = const Color(0xFFE6E6E6);
  final Color _screenBg = const Color(0xFFF2F2F2);

  // --- MODERN TOAST HELPER ---
  void _showModernToast(String message, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? Colors.red.shade600 : _petsyGreen,
        behavior: SnackBarBehavior.floating,
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        margin: const EdgeInsets.all(20),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _handleSignUp() async {
    // 1. Validation check
    if (!_formKey.currentState!.validate()) {
      _showModernToast("Please fix the errors in the form", isError: true);
      return;
    }

    if (!_isAccepted) {
      _showModernToast("Please accept the Terms of Use", isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
            'username': _usernameController.text.trim(),
            'email': _emailController.text.trim(),
            'createdAt': FieldValue.serverTimestamp(),
            'role': 'user',
            'profileCompleted': false,
          });

      if (mounted) {
        // Success Toast
        _showModernToast("Account Created Successfully!", isError: false);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const CompleteProfileScreen(),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        String msg = "Registration Failed";
        if (e.code == 'email-already-in-use') msg = "Email is already taken";
        if (e.code == 'weak-password') msg = "Password is too weak";
        _showModernToast(msg, isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bool isSmallScreen = size.height < 700;
    final double logoHeight = isSmallScreen ? 104 : 80;

    return Scaffold(
      backgroundColor: _screenBg,
      // Enable resizing so keyboard pushes content up
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: GradientWavePainter(
                colorStart: _petsyGreen,
                colorEnd: _petsyNavy,
              ),
            ),
          ),
          SafeArea(
            child: Center(
              // Wrap content in SingleChildScrollView for scrolling
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // --- LOGO ---
                    Image.asset(
                      'assets/images/petsylogo.png',
                      height: logoHeight,
                      fit: BoxFit.contain,
                      errorBuilder: (c, e, s) =>
                          Icon(Icons.pets, size: 80, color: _petsyGreen),
                    ),

                    const SizedBox(height: 10),

                    // --- MAIN CARD ---
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _cardColor.withOpacity(0.65),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Center(
                              child: Text(
                                "Create Your Account",
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(height: 15),

                            _buildLabel("Username"),
                            FloatingValidatorField(
                              hint: "your name",
                              icon: Icons.person_outline,
                              controller: _usernameController,
                              validator: (val) => (val == null || val.isEmpty)
                                  ? "Required"
                                  : null,
                            ),
                            const SizedBox(height: 8),

                            _buildLabel("Email"),
                            FloatingValidatorField(
                              hint: "yourname@gmail.com",
                              icon: Icons.mail_outline,
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              validator: (val) => (!val!.contains('@'))
                                  ? "Invalid email"
                                  : null,
                            ),
                            const SizedBox(height: 8),

                            _buildLabel("Password"),
                            FloatingValidatorField(
                              hint: "your password",
                              icon: Icons.lock_outline,
                              controller: _passwordController,
                              obscureText: !_isPasswordVisible,
                              onToggleVisibility: () => setState(
                                () => _isPasswordVisible = !_isPasswordVisible,
                              ),
                              showVisibilityToggle: true,
                              validator: (val) =>
                                  (val!.length < 6) ? "Min 6 chars" : null,
                            ),
                            const SizedBox(height: 8),

                            _buildLabel("Confirm Password"),
                            FloatingValidatorField(
                              hint: "confirm password",
                              icon: Icons.lock_outline,
                              controller: _confirmPasswordController,
                              obscureText: !_isConfirmVisible,
                              onToggleVisibility: () => setState(
                                () => _isConfirmVisible = !_isConfirmVisible,
                              ),
                              showVisibilityToggle: true,
                              validator: (val) =>
                                  (val != _passwordController.text)
                                  ? "No match"
                                  : null,
                            ),
                            const SizedBox(height: 12),

                            Row(
                              children: [
                                SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: Checkbox(
                                    value: _isAccepted,
                                    onChanged: (v) =>
                                        setState(() => _isAccepted = v!),
                                    activeColor: _petsyGreen,
                                  ),
                                ),
                                const Text(
                                  " I accept Privacy & Term of Use",
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            SizedBox(
                              width: double.infinity,
                              height: 44,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _petsyGreen,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                ),
                                onPressed: _isLoading ? null : _handleSignUp,
                                child: _isLoading
                                    ? const CircularProgressIndicator(
                                        color: Colors.white,
                                      )
                                    : const Text(
                                        "Sign Up",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),

                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Center(
                                child: Text(
                                  "- OR -",
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black54,
                                  ),
                                ),
                              ),
                            ),

                            _buildSocialButton(
                              "Sign up with Google",
                              "assets/images/google_icon.png",
                            ),
                            const SizedBox(height: 6),
                            _buildSocialButton(
                              "Sign up with Facebook",
                              "assets/images/facebook_icon.png",
                            ),

                            const SizedBox(height: 12),

                            // Navigation to Sign In with Smart Animate (Crossfade)
                            Center(
                              child: GestureDetector(
                                onTap: () {
                                  // FIX: PushReplacement prevents the Navigator.pop crash
                                  Navigator.pushReplacement(
                                    context,
                                    PageRouteBuilder(
                                      pageBuilder:
                                          (
                                            context,
                                            animation,
                                            secondaryAnimation,
                                          ) => const SignInScreen(),
                                      transitionsBuilder:
                                          (
                                            context,
                                            animation,
                                            secondaryAnimation,
                                            child,
                                          ) {
                                            return FadeTransition(
                                              opacity: animation,
                                              child: child,
                                            );
                                          },
                                      transitionDuration: const Duration(
                                        milliseconds: 400,
                                      ),
                                    ),
                                  );
                                },
                                child: const Text.rich(
                                  TextSpan(
                                    text: "Already have an Account? ",
                                    style: TextStyle(
                                      color: Colors.black54,
                                      fontSize: 11,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: "Sign In",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) => Padding(
    padding: const EdgeInsets.only(left: 5, bottom: 2),
    child: Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 12,
        color: Colors.black87,
      ),
    ),
  );

  Widget _buildSocialButton(String text, String asset) => Container(
    height: 38,
    decoration: BoxDecoration(
      border: Border.all(color: _petsyGreen, width: 1.5),
      borderRadius: BorderRadius.circular(25),
    ),
    child: InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(25),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            asset,
            height: 16,
            errorBuilder: (c, e, s) => const Icon(Icons.public, size: 16),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: _petsyGreen,
            ),
          ),
        ],
      ),
    ),
  );
}

// --- CUSTOM WIDGETS ---

class FloatingValidatorField extends StatefulWidget {
  final String hint;
  final IconData icon;
  final TextEditingController controller;
  final bool obscureText;
  final VoidCallback? onToggleVisibility;
  final bool showVisibilityToggle;
  final String? Function(String?) validator;
  final TextInputType? keyboardType;

  const FloatingValidatorField({
    super.key,
    required this.hint,
    required this.icon,
    required this.controller,
    required this.validator,
    this.obscureText = false,
    this.onToggleVisibility,
    this.showVisibilityToggle = false,
    this.keyboardType,
  });

  @override
  State<FloatingValidatorField> createState() => _FloatingValidatorFieldState();
}

class _FloatingValidatorFieldState extends State<FloatingValidatorField> {
  String? _errorMessage;
  bool _showError = false;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus && widget.controller.text.isNotEmpty) {
        _validate();
      }
    });
  }

  void _validate() {
    final error = widget.validator(widget.controller.text);
    if (error != null) {
      setState(() {
        _errorMessage = error;
        _showError = true;
      });
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _showError = false);
      });
    } else {
      setState(() => _showError = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        TextFormField(
          controller: widget.controller,
          focusNode: _focusNode,
          obscureText: widget.obscureText,
          keyboardType: widget.keyboardType,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: Colors.white,
            prefixIcon: Icon(
              widget.icon,
              size: 18,
              color: _showError ? Colors.red : Colors.grey,
            ),
            suffixIcon: widget.showVisibilityToggle
                ? IconButton(
                    icon: Icon(
                      widget.obscureText
                          ? Icons.visibility_off
                          : Icons.visibility,
                      size: 18,
                    ),
                    onPressed: widget.onToggleVisibility,
                  )
                : null,
            hintText: widget.hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(25),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(25),
              borderSide: BorderSide(
                color: _showError ? Colors.red : const Color(0xFF339967),
                width: 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 10,
            ),
          ),
          validator: (val) {
            final err = widget.validator(val);
            if (err != null) {
              setState(() {
                _errorMessage = err;
                _showError = true;
              });
              return "";
            }
            return null;
          },
        ),
        if (_showError && _errorMessage != null) ...[
          Positioned(
            top: -30,
            right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red.shade500,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                _errorMessage!,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Positioned(
            top: -8,
            right: 20,
            child: CustomPaint(
              size: const Size(10, 6),
              painter: TrianglePainter(Colors.red.shade500),
            ),
          ),
        ],
      ],
    );
  }
}

class TrianglePainter extends CustomPainter {
  final Color color;
  TrianglePainter(this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class GradientWavePainter extends CustomPainter {
  final Color colorStart;
  final Color colorEnd;
  GradientWavePainter({required this.colorStart, required this.colorEnd});

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Rect.fromLTWH(
      0,
      size.height * 0.5,
      size.width,
      size.height * 0.5,
    );
    final Paint paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [colorStart, colorEnd],
      ).createShader(rect)
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, size.height * 0.75)
      ..cubicTo(
        size.width * 0.35,
        size.height * 0.60,
        size.width * 0.65,
        size.height * 0.95,
        size.width,
        size.height * 0.70,
      )
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
