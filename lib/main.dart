import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(const LocalPulseApp());
}

class LocalPulseApp extends StatelessWidget {
  const LocalPulseApp({super.key});

  @override
  Widget build(BuildContext context) {

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "LocalPulse",

      theme: ThemeData(
        useMaterial3: true,
      ),

      home: const SplashScreen(),
    );
  }
}