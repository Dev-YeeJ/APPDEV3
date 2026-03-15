import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'sign_up_screen.dart'; // Import for Navigation & Shared Widgets
// Ensure this path is correct for your ProfilePage
import 'package:petsy/features/home/presentation/screens/profile_page.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // State
  bool _isLoading = false;
  bool _isPasswordVisible = false;

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

  Future<void> _handleSignIn() async {
    if (!_formKey.currentState!.validate()) {
      _showModernToast("Please fix the errors", isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (mounted) {
        _showModernToast("Welcome back!", isError: false);
        // Navigate to Profile Page (or Home)
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ProfilePage()),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        String msg = "Login Failed";
        if (e.code == 'user-not-found') msg = "No user found for that email.";
        if (e.code == 'wrong-password') msg = "Wrong password provided.";
        if (e.code == 'invalid-credential') msg = "Invalid email or password.";
        _showModernToast(msg, isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- SMART ANIMATION NAVIGATOR ---
  void _navigateToSignUp() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const SignUpScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bool isSmallScreen = size.height < 700;
    final double logoHeight = isSmallScreen ? 104 : 128;

    return Scaffold(
      backgroundColor: _screenBg,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // Background Wave
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
                          children: [
                            const Text(
                              "Welcome Back",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Email
                            Align(
                              alignment: Alignment.centerLeft,
                              child: _buildLabel("Email"),
                            ),
                            FloatingValidatorField(
                              hint: "yourname@gmail.com",
                              icon: Icons.mail_outline,
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              validator: (val) =>
                                  (val == null || !val.contains('@'))
                                  ? "Invalid email"
                                  : null,
                            ),
                            const SizedBox(height: 10),

                            // Password
                            Align(
                              alignment: Alignment.centerLeft,
                              child: _buildLabel("Password"),
                            ),
                            FloatingValidatorField(
                              hint: "your password",
                              icon: Icons.lock_outline,
                              controller: _passwordController,
                              obscureText: !_isPasswordVisible,
                              onToggleVisibility: () => setState(
                                () => _isPasswordVisible = !_isPasswordVisible,
                              ),
                              showVisibilityToggle: true,
                              validator: (val) => (val == null || val.isEmpty)
                                  ? "Required"
                                  : null,
                            ),

                            // Forgot Password
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  _showModernToast(
                                    "Forgot Password feature coming soon!",
                                    isError: false,
                                  );
                                },
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: const Size(50, 30),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  "Forgot Password?",
                                  style: TextStyle(
                                    color: _petsyNavy,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 5),

                            // Sign In Button
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
                                onPressed: _isLoading ? null : _handleSignIn,
                                child: _isLoading
                                    ? const CircularProgressIndicator(
                                        color: Colors.white,
                                      )
                                    : const Text(
                                        "Log In",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),

                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Text(
                                "- OR -",
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black54,
                                ),
                              ),
                            ),

                            // Social Buttons
                            _buildSocialButton(
                              "Log in with Google",
                              "assets/images/google_icon.png",
                            ),
                            const SizedBox(height: 8),
                            _buildSocialButton(
                              "Log in with Facebook",
                              "assets/images/facebook_icon.png",
                            ),

                            const SizedBox(height: 20),

                            // Navigation to Sign Up
                            GestureDetector(
                              onTap: _navigateToSignUp,
                              child: const Text.rich(
                                TextSpan(
                                  text: "Not have an Account? ",
                                  style: TextStyle(
                                    color: Colors.black54,
                                    fontSize: 12,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: "Sign Up",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
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
    padding: const EdgeInsets.only(left: 5, bottom: 4),
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
