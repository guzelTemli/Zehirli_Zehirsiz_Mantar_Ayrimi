import 'package:flutter/material.dart';
import 'dart:async';
import 'login.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(seconds: 1), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff1d4b0b),
      body: Center(
        child: Image.asset(
          'images/splashh.png',
          width: MediaQuery.of(context).size.width * 1.1, // %10 büyütüldü
          height: MediaQuery.of(context).size.height * 1.1, // %10 büyütüldü
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
