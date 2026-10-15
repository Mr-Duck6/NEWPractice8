import 'package:flutter/material.dart';

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

class GreenhouseScreen extends StatelessWidget {
  const GreenhouseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Моніторинг теплиці')),
      body: const Center(child: Text('Дані теплиці')),
    );
  }
}
