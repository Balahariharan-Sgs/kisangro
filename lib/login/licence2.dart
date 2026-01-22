import 'package:flutter/material.dart';
import 'package:kisangro/login/onprocess.dart'; // Keep if KisanProApp is used elsewhere
import 'package:shared_preferences/shared_preferences.dart'; // Keep if SharedPreferences is used elsewhere
import 'package:google_fonts/google_fonts.dart';
import 'package:kisangro/login/licence4.dart'; // Import licence4
import 'package:provider/provider.dart'; // Import Provider
import '../home/theme_mode_provider.dart'; // Import ThemeModeProvider


class licence2 extends StatefulWidget {
  @override
  _licence2State createState() => _licence2State();
}

class _licence2State extends State<licence2> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const licence4(licenseTypeToDisplay: 'pesticide')), // Pass 'pesticide'
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = Provider.of<ThemeModeProvider>(context).themeMode;
    final isDarkMode = themeMode == ThemeMode.dark;

    // Define colors based on theme
    final Color backgroundColor = isDarkMode ? Colors.black : Colors.white;
    final Color appBarColor = const Color(0xffEB7720); // Always orange
    final Color appBarIconColor = Colors.white;
    final Color appBarTextColor = Colors.white;
    final Color progressIndicatorColor = const Color(0xffEB7720); // Always orange
    final Color textColor = isDarkMode ? Colors.white : Colors.black;


    return Scaffold(
      backgroundColor: backgroundColor, // Apply theme color
      appBar: AppBar(
        backgroundColor: appBarColor, // Always orange
        leading: const BackButton(color: Colors.white),
        title: Transform.translate(offset: const Offset(-25, 0), // Use const Offset
          child: Text("Upload License",style: GoogleFonts.poppins(color: appBarTextColor,fontSize: 18),),),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: progressIndicatorColor), // Always orange
            const SizedBox(height: 20),
            Text(
              'Loading license details...',
              style: GoogleFonts.poppins(fontSize: 16, color: textColor), // Apply theme color
            ),
          ],
        ),
      ),
    );
  }
}
