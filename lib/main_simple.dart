import 'package:flutter/material.dart';
import 'ui/screens/home_screen_simple.dart';

void main() {
  runApp(const ZoomCloneApp());
}

class ZoomCloneApp extends StatelessWidget {
  const ZoomCloneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Zoom Clone',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2D8CFF)),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF2D8CFF),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      home: const HomeScreenSimple(),
      debugShowCheckedModeBanner: false,
    );
  }
}
