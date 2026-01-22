import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kisangro/home/bottom.dart';
import 'package:provider/provider.dart'; // Import Provider
import '../home/theme_mode_provider.dart'; // Import ThemeModeProvider


void main() => runApp(KisanProApp());

class KisanProApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: KycSplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class KycSplashScreen extends StatefulWidget {
  @override
  _KycSplashScreenState createState() => _KycSplashScreenState();
}

class _KycSplashScreenState extends State<KycSplashScreen> {
  @override
  void initState() {
    super.initState();
    // Navigate to HomePage after 4 seconds
    Future.delayed(const Duration(seconds: 8), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Bot()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = Provider.of<ThemeModeProvider>(context).themeMode;
    final isDarkMode = themeMode == ThemeMode.dark;

    // Define colors based on theme
    final Color gradientStartColor = isDarkMode ? Colors.black : const Color(0xffFFD9BD);
    final Color gradientEndColor = isDarkMode ? Colors.black : const Color(0xffFFFFFF);
    final Color textColor = isDarkMode ? Colors.white : Colors.black87;
    // Removed logoColor and processGifColor as they're no longer needed for tinting


    return Scaffold(
      backgroundColor: Colors.white,
      // Removed SafeArea to allow content to fill the entire screen
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [gradientStartColor, gradientEndColor], // Apply theme colors
          ),
        ),
        child: Center(
          child: Column(
            // Center the content
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Removed the SizedBox(height: 50) and SizedBox(height: 80)
              // to allow the content to naturally center and fill available space.
              SizedBox(
                height: 130,
                width: 150,
                child: Image.asset("assets/logo.png"), // Removed color property
              ),
              const SizedBox(height: 80), // Keep this spacing for visual balance
              Image.asset(
                "assets/process.gif",
                width: 200,
                height: 200,
                // Removed color property
              ),
              const SizedBox(height: 30),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30.0),
                child: Text(
                  'Your KYC verification is in process.\n\nYou can purchase our products once it is completed.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: textColor, // Apply theme color
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


