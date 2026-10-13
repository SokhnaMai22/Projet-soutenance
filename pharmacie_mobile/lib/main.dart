// lib/main.dart

import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const PharmaSanteApp());
}

class PharmaSanteApp extends StatelessWidget {
  const PharmaSanteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PharmaSanté Sénégal',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          primary: Colors.teal.shade700,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const LoginScreen(),
    );
  }
}