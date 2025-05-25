import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:wildfocus/screens/detection.dart';
import 'package:wildfocus/screens/collection.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wildfocus/customs/customcolors.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => DetectionScreen()),
        );
        break;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CollectionScreen()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              CustomColors.background,
              CustomColors.background.withAlpha(230),
              CustomColors.textfieldFill,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'WildFocus',
                style: GoogleFonts.poppins(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFF9D77E),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Mantar Keşfi',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  color: CustomColors.primaryText.withAlpha(179),
                ),
              ),
              Lottie.asset('images/magnifier.json'),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: CustomColors.textfieldFill,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(26),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.camera_alt),
              label: 'Tespit',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.collections),
              label: 'Koleksiyon',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: CustomColors.primaryText,
          unselectedItemColor: CustomColors.primaryText,
          backgroundColor: Colors.transparent,
          elevation: 0,
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}
