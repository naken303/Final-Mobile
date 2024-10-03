import 'package:flutter/material.dart';
// import 'package:flutter_svg/flutter_svg.dart';
import 'Pages/welcome.dart';
void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'BeVietnamPro'),
      home: const WelcomePage(),
    );
  }
}
