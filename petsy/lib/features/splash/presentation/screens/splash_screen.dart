import 'package:flutter/material.dart';
import 'package:petsy/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'dart:math' as math; // Required for the diagonal calculation

class PetsySplashScreen extends StatefulWidget {
  const PetsySplashScreen({super.key});

  @override
  State<PetsySplashScreen> createState() => _PetsySplashScreenState();
}

class _PetsySplashScreenState extends State<PetsySplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _expansionController;
  late AnimationController _logoFadeController;

  late Animation<double> _circleScale;
  late Animation<double> _firstLogoOpacity; // The Paw + P
  late Animation<double> _secondLogoOpacity; // The Petsy Wordmark

  @override
  void initState() {
    super.initState();

    // 1. Circle Expansion (1.2 seconds)
    _expansionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // 2. Fade sequence (3.5 seconds total)
    _logoFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    );

    /// Expansion: Starts slow and finishes fast to "pop" onto the screen
    _circleScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _expansionController, curve: Curves.easeInCirc),
    );

    // Image 1 (Paw P) fades in quickly after expansion starts
    _firstLogoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoFadeController,
        curve: const Interval(0.0, 0.45, curve: Curves.easeIn),
      ),
    );

    // Image 2 (Petsy Wordmark) fades in while Image 1 fades out
    _secondLogoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoFadeController,
        curve: const Interval(0.55, 1.0, curve: Curves.easeIn),
      ),
    );

    _runAnimationSequence();
  }

  Future<void> _runAnimationSequence() async {
    // Phase 1: Expand the circle
    await _expansionController.forward();

    // Phase 2: Run the logo fade animations
    await _logoFadeController.forward();

    // Navigate to onboarding screen
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const OnboardingScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    // Math logic: Calculate the diagonal of the screen to ensure
    // the circle covers the corners completely.
    final double diagonal = math.sqrt(
      math.pow(screenSize.width, 2) + math.pow(screenSize.height, 2),
    );

    return Scaffold(
      // The starting background color (matches Image 1)
      backgroundColor: const Color(0xFFF5F5F5),
      body: Stack(
        alignment: Alignment.center,
        children: [
          // 1. The Expanding Gradient Circle
          AnimatedBuilder(
            animation: _circleScale,
            builder: (context, child) {
              return Transform.scale(
                // Use a 1.1 multiplier to overshoot the corners for a solid look
                scale: _circleScale.value * 2.5,
                child: Container(
                  width: diagonal,
                  height: diagonal,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFF339967), // Greenish Top
                        Color(0xFF003466), // Deep Blue Bottom
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          // 2. The Paw-P Logo (Fades out when Wordmark appears)
          FadeTransition(
            opacity: ReverseAnimation(_secondLogoOpacity),
            child: FadeTransition(
              opacity: _firstLogoOpacity,
              child: Image.asset(
                'assets/images/splash1.png',
                width: screenSize.width * 0.3,
              ),
            ),
          ),

          // 3. The Full Petsy Wordmark
          FadeTransition(
            opacity: _secondLogoOpacity,
            child: Image.asset(
              'assets/images/splash2.png',
              width: screenSize.width * 0.6,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _expansionController.dispose();
    _logoFadeController.dispose();
    super.dispose();
  }
}
