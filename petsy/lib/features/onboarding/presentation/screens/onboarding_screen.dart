import 'package:flutter/material.dart';
import 'package:petsy/features/auth/presentation/screens/sign_up_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Data for your 3 onboarding screens
  final List<Map<String, String>> _onboardingData = [
    {
      "text": "Everything your pet needs, delivered to your doorstep.",
      "image": "assets/images/obs1.png",
    },
    {
      "text": "Find food, toys, grooming supplies, and more for yor pet",
      "image": "assets/images/obs2.png",
    },
    {
      "text": "Join our community of happy pet owners today!",
      "image": "assets/images/obs3.png",
    },
  ];

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // 1. Permanent Gradient Background (Matches Splash)
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF339967), Color(0xFF003466)],
              ),
            ),
          ),

          // 2. Swipeable Content
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemCount: _onboardingData.length,
            itemBuilder: (context, index) {
              return Stack(
                children: [
                  // 1. Responsive Background Image (25% Opacity)
                  Opacity(
                    opacity: 0.25,
                    child: Image.asset(
                      _onboardingData[index]["image"]!,
                      width: size.width,
                      height: size.height,
                      fit: BoxFit.cover,
                    ),
                  ),

                  // 2. Text Positioned at the top (matches your image)
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        30,
                        60,
                        30,
                        0,
                      ), // L, T, R, B
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start, // Left aligned
                        children: [
                          Text(
                            _onboardingData[index]["text"]!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 35, // Large font like the reference
                              fontWeight: FontWeight.w600, // Semi-bold
                              height: 1.2, // Adjusts line spacing
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          // 3. Navigation Controls (Bottom Buttons & Indicators)
          Positioned(
            bottom: 50,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Left Button (Skip or Back)
                TextButton(
                  onPressed: () {
                    if (_currentPage > 0) {
                      _pageController.previousPage(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  child: Text(
                    _currentPage == 0 ? "" : "BACK",
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),

                // Center Indicators (Dot Matrix)
                Row(
                  children: List.generate(
                    _onboardingData.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.only(right: 5),
                      height: 10,
                      width: _currentPage == index ? 20 : 10,
                      decoration: BoxDecoration(
                        color: _currentPage == index
                            ? Colors.white
                            : Colors.white38,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
                ),

                // Right Button (Next or Done)
                TextButton(
                  // Inside the 'DONE' button onPressed logic
                  onPressed: () {
                    if (_currentPage < _onboardingData.length - 1) {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.ease,
                      );
                    } else {
                      // Navigate to Sign Up Screen
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => const SignUpScreen(),
                        ),
                      );
                    }
                  },
                  child: Text(
                    _currentPage == _onboardingData.length - 1
                        ? "DONE"
                        : "NEXT",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
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
}
