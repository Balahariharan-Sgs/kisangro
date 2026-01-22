import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kisangro/home/reward_screen.dart';
import 'package:kisangro/home/bottom.dart'; // Import the Bot class
import 'package:provider/provider.dart'; // Import Provider
import '../home/theme_mode_provider.dart'; // Import ThemeModeProvider

class RewardsPopup extends StatelessWidget {
  final int coinsEarned;

  const RewardsPopup({
    super.key,
    this.coinsEarned = 100,
  });

  @override
  Widget build(BuildContext context) {
    final themeMode = Provider.of<ThemeModeProvider>(context).themeMode;
    final isDarkMode = themeMode == ThemeMode.dark;

    // Define colors based on theme
    final Color dialogBackgroundColor = isDarkMode ? Colors.grey[850]! : Colors.white;
    final Color closeButtonBgColor = isDarkMode ? Colors.grey[700]! : Colors.grey[300]!;
    final Color closeButtonIconColor = isDarkMode ? Colors.white : Colors.grey;
    final Color congratulationsTextColor = isDarkMode ? Colors.white : Colors.black87;
    final Color coinsEarnedTextColor = isDarkMode ? Colors.white : Colors.black87;
    final Color orangeCoinsColor = isDarkMode ? Colors.orange[300]! : Colors.orange[600]!;
    final Color starColor1 = isDarkMode ? Colors.orange[200]! : Colors.orange[300]!;
    final Color starColor2 = isDarkMode ? Colors.orange[100]! : Colors.orange[200]!;
    final Color starColor3 = isDarkMode ? Colors.orange[50]! : Colors.orange[100]!;
    final Color viewRewardsButtonColor = isDarkMode ? Colors.green[700]! : Colors.green[600]!;
    // Removed gifColor as it's no longer needed for tinting


    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: dialogBackgroundColor, // Apply theme color
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Close button
            Padding(
              padding: const EdgeInsets.only(top: 12, right: 12),
              child: Align(
                alignment: Alignment.topRight,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: closeButtonBgColor, // Apply theme color
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close,
                      size: 18,
                      color: closeButtonIconColor, // Apply theme color
                    ),
                  ),
                ),
              ),
            ),

            // Coin animation area with stars
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  // Decorative stars
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      // Decorative stars
                      Positioned(
                        left: 20,
                        top: 10,
                        child: _buildStar(12, starColor1), // Apply theme color
                      ),
                      Positioned(
                        right: 15,
                        top: 5,
                        child: _buildStar(8, starColor2), // Apply theme color
                      ),
                      Positioned(
                        left: 60,
                        bottom: 5,
                        child: _buildStar(6, starColor3), // Apply theme color
                      ),
                      Positioned(
                        right: 45,
                        bottom: 15,
                        child: _buildStar(10, starColor1), // Apply theme color
                      ),

                      // Main coin icon
                      Image.asset('assets/wings.gif', scale: 1), // Removed 'color' property
                    ],
                  ),

                  const SizedBox(height: 30),

                  // Congratulations text
                  Text(
                    "Congratulations!",
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: congratulationsTextColor, // Apply theme color
                    ),
                  ),

                  const SizedBox(height: 15),

                  // Coins earned text
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: coinsEarnedTextColor, // Apply theme color
                        height: 1.4,
                      ),
                      children: [
                        TextSpan(text: "You earned ", style: TextStyle(color: coinsEarnedTextColor)), // Apply theme color
                        TextSpan(
                          text: "$coinsEarned coins",
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            color: orangeCoinsColor, // Apply theme color
                          ),
                        ),
                        TextSpan(text: " through this\npurchase", style: TextStyle(color: coinsEarnedTextColor)), // Apply theme color
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),

            // View Reward Coins button - positioned at bottom with no padding
            Container(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  // Close the current dialog
                  Navigator.pop(context);
                  // Navigate to the Bot (BottomNavigationBar) and select the Rewards tab (index 2)
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const Bot(initialIndex: 2), // Set initialIndex to 2 for Rewards tab
                    ),
                        (Route<dynamic> route) => false, // Remove all previous routes
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: viewRewardsButtonColor, // Apply theme color
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  elevation: 2,
                ),
                child: Text(
                  "View Reward Coins",
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a decorative star
  Widget _buildStar(double size, Color color) {
    return Icon(
      Icons.star,
      size: size,
      color: color,
    );
  }
}
