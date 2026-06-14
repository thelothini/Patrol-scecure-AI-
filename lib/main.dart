import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF0A1628),
  ));
  runApp(const PatrolSecureApp());
}

class PatrolSecureApp extends StatelessWidget {
  const PatrolSecureApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PatrolSecure',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A1628),
        primaryColor: const Color(0xFF00C2FF),
        fontFamily: 'Rajdhani',
        snackBarTheme: SnackBarThemeData(
          backgroundColor: const Color(0xFF142035),
          contentTextStyle: const TextStyle(color: Colors.white, fontFamily: 'Rajdhani'),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          behavior: SnackBarBehavior.floating,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
