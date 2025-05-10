import 'package:flutter/material.dart';
import 'package:wildfocus/screens/detection.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Tam ekran görsel
          Positioned.fill(
            child: Image.asset(
              'images/mushroomm.jpg',
              fit: BoxFit.cover,
            ),
          ),

          // Sol üstte "Keşfe başla" yazısı
  Positioned(
  top: 60,
  left: 20,
  child: Text(
    'Keşfe\n     Başla',
    style:  GoogleFonts.cinzel(
      fontSize: 48,
      fontWeight: FontWeight.bold,
      foreground: Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFE082), // açık altın sarısı
            Color(0xFFFFC107), // sıcak kehribar
            Color(0xFFB26500), // koyu altın/turuncu
          ],
        ).createShader(Rect.fromLTWH(0.0, 0.0, 300.0, 100.0)),
    ),
  ),
),


          // Sağ altta beyaz ok simgesi
          Positioned(
            bottom: 30,
            right: 30,
            child: IconButton(
              icon: const Icon(Icons.arrow_forward, 
              color:  Color(0xFFF9D77E), // mantar üstü ışık tonu
              size: 40),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => DetectionScreen()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
