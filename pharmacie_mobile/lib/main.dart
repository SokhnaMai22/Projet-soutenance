// lib/main.dart

import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'theme/app_theme.dart';

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
      theme: buildAppTheme(),
            builder: (context, child) {
        final mq = MediaQuery.of(context);
        return MediaQuery(
          data: mq.copyWith(
              textScaler: mq.textScaler
                  .clamp(minScaleFactor: 0.85, maxScaleFactor: 1.0)),
          child: child!,
        );
      },
      home: const LoginScreen(),
    );
  }
} 