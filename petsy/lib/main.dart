import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:petsy/features/splash/presentation/screens/splash_screen.dart';
import 'firebase_options.dart';
import 'package:provider/provider.dart';
// Note: Double check this path matches exactly where you saved cart_provider.dart!
import 'package:petsy/providers/cart_provider.dart';
import 'package:petsy/providers/chat_provider.dart';

// 🚀 ENHANCED NOTIFICATION SERVICE
import 'package:petsy/services/notification_service_enhanced.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// 🚀 BACKGROUND MESSAGE HANDLER - MUST BE TOP-LEVEL
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('🔔 Background message handled: ${message.notification?.title}');
}

void main() async {
  // 1. Ensure Flutter engine is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Register background message handler BEFORE initializing Firebase
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // 3. Initialize Firebase with your platform options
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 🚀 4. Initialize Enhanced Notification Service
  await NotificationService().initialize();

  runApp(
    // 🚀 WRAP YOUR APP IN THE MULTIPROVIDER HERE 🚀
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Set app context for notification overlays
    NotificationService.setAppContext(context);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Petsy',
      home: const PetsySplashScreen(),
    );
  }
}
