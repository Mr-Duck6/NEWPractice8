import 'package:flutter/material.dart';

import 'screens/greenhouse_screen.dart';

void main() {
  runApp(const GreenhouseApp());
}

class GreenhouseApp extends StatelessWidget {
  const GreenhouseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Моніторинг теплиці',
      theme: ThemeData(primarySwatch: Colors.green),
      home: const GreenhouseScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
