import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kisangro/login/login.dart';
import 'package:provider/provider.dart'; // Import Provider
import '../home/theme_mode_provider.dart'; // Import ThemeModeProvider


class fourthscreen extends StatefulWidget {
  const fourthscreen({super.key});

  @override
  State<fourthscreen> createState() => _fourthscreenState();
}

class _fourthscreenState extends State<fourthscreen> {
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
    final Color iconColor = isDarkMode ? Colors.white70 : Colors.black; // Adjust icon color for dark mode
    final Color underlineColor = isDarkMode ? Colors.white : Colors.black;
    // Removed cartGifColor as it's no longer needed for tinting


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
        child: LayoutBuilder( // Use LayoutBuilder to get the parent constraints
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox( // Constrain the Column's height
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight, // Ensure it's at least as tall as the screen
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20 * scale), // Base horizontal padding
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center, // Vertically center content
                    crossAxisAlignment: CrossAxisAlignment.center, // Default for horizontal centering of some items
                    children: [
                      // SVG Picture - Aligned to the left and shifted right
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding( // Added padding to shift it right
                          padding: const EdgeInsets.only(left: 20.0), // Adjust this value to move it more/less right
                          child: SvgPicture.asset(
                            "assets/welcome4.svg",
                            height: screenHeight * 0.32,
                            width: screenWidth * 0.8,
                            // Removed colorFilter property
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Safe & Secure Payments Section - Aligned to the left and shifted right
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding( // Added padding to shift it right
                          padding: const EdgeInsets.only(left: 20.0), // Adjust this value
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.gpp_good, size: 22 * scale, color: iconColor), // Apply theme color
                              const SizedBox(width: 10),
                              Text(
                                "Safe & Secure Payments",
                                style: GoogleFonts.poppins(
                                  fontSize: screenWidth * 0.042,
                                  fontWeight: FontWeight.w600, // Changed to w600 for slightly thicker
                                  color: textColor, // Apply theme color
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 24/7 Customer Support Section - Aligned to the left and shifted right
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding( // Added padding to shift it right
                          padding: const EdgeInsets.only(left: 20.0), // Adjust this value
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.headset_mic_outlined, size: 22 * scale, color: iconColor), // Apply theme color
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "24/7 Customer Support",
                                    style: GoogleFonts.poppins(
                                      fontSize: screenWidth * 0.042,
                                      fontWeight: FontWeight.w600, // Changed to w600 for slightly thicker
                                      color: textColor, // Apply theme color
                                    ),
                                    textAlign: TextAlign.start,
                                  ),
                                  Text(
                                    "- Reach Out Us Anytime",
                                    style: GoogleFonts.poppins(
                                      fontSize: screenWidth * 0.042,
                                      fontWeight: FontWeight.w600, // Changed to w600 for slightly thicker
                                      color: textColor, // Apply theme color
                                    ),
                                    textAlign: TextAlign.start,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Ready To Shop! Section (remains centered)
                      Center(
                        child: IntrinsicWidth(
                          child: Column(
                            children: [
                              Transform.translate(
                                offset: const Offset(0.0, 1.5 / 2),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Image.asset(
                                      'assets/cart.gif',
                                      height: 58 * scale,
                                      width: 99 * scale,
                                      // Removed color property
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      "Ready To Shop!",
                                      style: GoogleFonts.poppins(
                                        fontSize: screenWidth * 0.045,
                                        fontWeight: FontWeight.bold, // Keep this bold as it was
                                        color: textColor, // Apply theme color
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                height: 1.5,
                                width: double.infinity,
                                color: underlineColor, // Apply theme color
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Dive In Button (remains centered)
                      Center(
                        child: Container(
                          height: 50 * scale,
                          width: 300 * scale,
                          decoration: BoxDecoration(
                            color: const Color(0xffEB7720), // Always orange
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const LoginApp(),
                                ),
                              );
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Dive In ",
                                  style: GoogleFonts.poppins(
                                    fontSize: screenWidth * 0.045,
                                    color: Colors.white,
                                  ),
                                ),
                                const Icon(
                                  Icons.arrow_forward_ios_outlined,
                                  color: Colors.white,
                                  size: 14,
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
