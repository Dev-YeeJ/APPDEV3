import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:petsy/features/splash/presentation/screens/splash_screen.dart';
import 'firebase_options.dart';
import 'package:provider/provider.dart';
// Note: Double check this path matches exactly where you saved cart_provider.dart!
import 'package:petsy/providers/cart_provider.dart';

void main() async {
  // 1. Ensure Flutter engine is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Initialize Firebase with your platform options
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    // 🚀 FIXED: WRAP YOUR APP IN THE MULTIPROVIDER HERE 🚀
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => CartProvider())],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Petsy',
      home: const PetsySplashScreen(),
    );
  }
}
