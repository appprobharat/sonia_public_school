import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sonia_public_school/Notification/notification_service.dart';

import 'firebase_options.dart';
import 'package:sonia_public_school/splash_screen.dart';
import 'package:sonia_public_school/login_page.dart';
import 'package:sonia_public_school/dashboard/dashboard_screen.dart';
import 'package:sonia_public_school/teacher/teacher_dashboard_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();
/// 🔔 Background notification handler
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseMessaging.onBackgroundMessage(
    _firebaseMessagingBackgroundHandler,
  );
  await NotificationService.initialize();
  runApp(const MyApp());
  
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
        navigatorObservers: [routeObserver], 
      debugShowCheckedModeBanner: false,
      home: const RootDecider(),
    );
  }
}

/// 🔥 ROOT DECIDER (single source of truth)
class RootDecider extends StatefulWidget {
  const RootDecider({super.key});

  @override
  State<RootDecider> createState() => _RootDeciderState();
}

class _RootDeciderState extends State<RootDecider> {
  Widget _screen = const SplashScreen();

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    debugPrint("🔔 Foreground message received");
    NotificationService.display(message);
  });

    _initApp();
  }

  Future<void> _initApp() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final isLoggedIn = prefs.getBool('is_logged_in') ?? false;
      final userType = prefs.getString('user_type') ?? '';

      final secureToken =
          await _secureStorage.read(key: 'auth_token') ?? '';
      final prefsToken = prefs.getString('auth_token') ?? '';

      final token = secureToken.isNotEmpty ? secureToken : prefsToken;

      debugPrint("🧪 isLoggedIn: $isLoggedIn");
      debugPrint("🧪 userType: $userType");
      debugPrint("🧪 tokenExists: ${token.isNotEmpty}");

      if (isLoggedIn && token.isNotEmpty) {
        _screen = _decideDashboard(userType);
      } else {
        // ❌ Not logged in → GO TO LOGIN
        await _secureStorage.delete(key: 'auth_token');
        await prefs.clear();
        _screen = LoginPage();
      }
    } catch (e) {
      debugPrint("ROOT ERROR: $e");
      _screen = LoginPage();
    }

    if (mounted) setState(() {});
  }

  Widget _decideDashboard(String userType) {
    switch (userType) {
      case 'Teacher':
        return const TeacherDashboardScreen();
      case 'Student':
        return const DashboardScreen();
      default:
        return LoginPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return _screen;
  }
}
