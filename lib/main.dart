// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/auth_screen.dart';
import 'screens/main_screen.dart'; // ← ИМПОРТИРУЕМ MAIN_SCREEN
import 'api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const NavokeApp());
}

class NavokeApp extends StatelessWidget {
  const NavokeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'НаVoke',
      theme: ThemeData(
        primaryColor: const Color(0xFFEF7F1A),
        colorScheme: ColorScheme.fromSwatch().copyWith(primary: const Color(0xFFEF7F1A)),
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFEF7F1A),
          foregroundColor: Colors.white,
        ),
      ),
      home: const MainScreen(), // ✅ ИЗМЕНЕНО: теперь Главная страница
      debugShowCheckedModeBanner: false,
    );
  }
}