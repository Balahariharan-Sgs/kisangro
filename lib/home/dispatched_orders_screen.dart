import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kisangro/home/theme_mode_provider.dart';
import 'package:provider/provider.dart'; // Import Provider
// Import the new ThemeModeProvider

// This is a placeholder screen for Dispatched Orders details.
// You can expand this with actual order tracking UI later.
class DispatchedOrdersScreen extends StatelessWidget {
  const DispatchedOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeMode = Provider.of<ThemeModeProvider>(context).themeMode;
    final isDarkMode = themeMode == ThemeMode.dark;

    // Define colors based on theme
    final Color gradientStartColor = isDarkMode ? Colors.black : const Color(0xffFFD9BD);
    final Color gradientEndColor = isDarkMode ? Colors.black : const Color(0xffFFFFFF);
    final Color iconColor = const Color(0xffEB7720); // Icon color remains orange
    final Color titleColor = isDarkMode ? Colors.white : Colors.black87;
    final Color subtitleColor = isDarkMode ? Colors.grey[400]! : Colors.grey[700]!;
    final Color buttonBackgroundColor = const Color(0xffEB7720); // Button background remains orange
    final Color buttonTextColor = Colors.white; // Button text remains white

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xffEB7720),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          "Dispatched Order Details",
          style: GoogleFonts.poppins(color: Colors.white, fontSize: 18),
        ),
        centerTitle: false,
        titleSpacing: 0,
      ),
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
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.local_shipping,
                size: 80,
                color: iconColor, // Always orange
              ),
              const SizedBox(height: 20),
              Text(
                "Your order is on its way!",
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: titleColor, // Apply theme color
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                "Tracking information will be available here soon.",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: subtitleColor, // Apply theme color
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  // Example: Navigate back to MyOrder screen
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonBackgroundColor, // Always orange
                  padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  "Go Back to Orders",
                  style: GoogleFonts.poppins(color: buttonTextColor, fontSize: 16), // Always white
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
