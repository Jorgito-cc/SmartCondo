import 'package:flutter/material.dart';
import 'shared/theme.dart';
import 'features/auth/login_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart Condominium',
      theme: buildTheme(),
      home: const LoginPage(),
    );
  }
}
 