import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart'; // Import Provider
import '../home/theme_mode_provider.dart'; // Import ThemeModeProvider


class thirdscreen extends StatefulWidget {
  const thirdscreen({super.key});

  @override
  State<thirdscreen> createState() => _thirdscreenState();
}

class _thirdscreenState extends State<thirdscreen> {
  @override
  Widget build(BuildContext context) {
    var screenWidth = MediaQuery.of(context).size.width;
    var screenHeight = MediaQuery.of(context).size.height;
    final isTablet = screenWidth > 600;
    final scale = isTablet ? 1.5 : 1.0;
    final themeMode = Provider.of<ThemeModeProvider>(context).themeMode;
    final isDarkMode = themeMode == ThemeMode.dark;

    // Define colors based on theme
    final Color gradientStartColor = isDarkMode ? Colors.black : const Color(0xffFFD9BD);
    final Color gradientEndColor = isDarkMode ? Colors.black : const Color(0xffFFFFFF);
    final Color textColor = isDarkMode ? Colors.white : Colors.black;
    // Removed svgColor as it's no longer needed for tinting


    return Scaffold(
      body: Container( // Removed SafeArea
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
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20 * scale),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset(
                  "assets/welcome3.svg",
                  height: screenHeight * 0.35,
                  width: screenWidth * 0.8,
                  fit: BoxFit.contain,
                  // Removed colorFilter property
                ),
                const SizedBox(height: 20),
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: GoogleFonts.poppins(
                      fontSize: screenWidth * 0.045,
                      color: textColor, // Apply theme color
                    ),
                    children: [
                      TextSpan(
                        text: 'B2B: ',
                        style: TextStyle(fontWeight: FontWeight.bold, color: textColor), // Apply theme color
                      ),
                      TextSpan(text: 'Effortless Ordering With Exclusive ', style: TextStyle(color: textColor)), // Apply theme color
                      TextSpan(
                        text: 'Membership',
                        style: TextStyle(fontWeight: FontWeight.bold, color: textColor), // Apply theme color
                      ),
                      TextSpan(text: ' Discounts.', style: TextStyle(color: textColor)), // Apply theme color
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
