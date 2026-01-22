import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart'; // Import Provider
import '../home/theme_mode_provider.dart'; // Import ThemeModeProvider


class RewardApp extends StatelessWidget {
  const RewardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Reward Popup Demo',
      home: const RewardHomePage(),
    );
  }
}

class RewardHomePage extends StatelessWidget {
  const RewardHomePage({super.key});

  void _showRewardDialog(BuildContext context) {
    final themeMode = Provider.of<ThemeModeProvider>(context, listen: false).themeMode;
    final isDarkMode = themeMode == ThemeMode.dark;

    // Define colors based on theme for the dialog
    final Color dialogBackgroundColor = isDarkMode ? Colors.grey[850]! : Colors.white;
    final Color titleColor = isDarkMode ? Colors.white : Colors.black87;
    final Color subtextColor = isDarkMode ? Colors.white70 : Colors.black87;
    final Color orangeCoinsColor = isDarkMode ? Colors.orange[300]! : const Color(0xffEB7720);
    final Color viewRewardsButtonColor = isDarkMode ? Colors.green[700]! : const Color(0xff52B157);
    final Color closeButtonBorderColor = const Color(0xffEB7720); // Always orange
    final Color closeButtonIconColor = const Color(0xffEB7720); // Always orange
    final Color? gifColor = isDarkMode ? Colors.white70 : null; // Adjust GIF color for dark mode


    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: dialogBackgroundColor, // Apply theme color
        child: Stack(
          children: [
            Padding(

              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Reward Image
                  Image.asset(
                    'assets/wings.gif',
                    height: 120,
                    width: 150,
                    fit: BoxFit.contain,
                    color: gifColor, // Apply theme color
                  ),
                  const SizedBox(height: 20),
                  // Title
                  Text(
                    "Congratulations!",
                    style: GoogleFonts.lato(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: titleColor, // Apply theme color
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Subtext
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: GoogleFonts.lato(
                        fontSize: 16,
                        color: subtextColor, // Apply theme color
                        fontWeight: FontWeight.w400,
                      ),
                      children: [
                        TextSpan(text: "You earned ", style: GoogleFonts.poppins(color: subtextColor)), // Apply theme color
                        TextSpan(
                          text: "100 coins",
                          style:  GoogleFonts.poppins(
                            color: orangeCoinsColor, // Apply theme color
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextSpan(text: " through this purchase",style: GoogleFonts.poppins(color: subtextColor)), // Apply theme color
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Button
                  SizedBox(
                    width: double.infinity,
                    height: 45,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: viewRewardsButtonColor, // Apply theme color
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        "View Reward Coins",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Close Icon
            Positioned(
              top: 12,
              right: 12,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  height: 20,
                  width: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: closeButtonBorderColor, width: 1), // Always orange
                  ),
                  child:  Icon(
                    Icons.close,
                    size: 14,
                    color: closeButtonIconColor, // Always orange
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = Provider.of<ThemeModeProvider>(context).themeMode;
    final isDarkMode = themeMode == ThemeMode.dark;

    // Define colors for the Scaffold's AppBar and body
    final Color appBarBgColor = isDarkMode ? Colors.grey[900]! : const Color(0xff38B000);
    final Color appBarTitleColor = isDarkMode ? Colors.white : Colors.white;
    final Color buttonBgColor = isDarkMode ? Colors.orange[700]! : const Color(0xffEB7720);


    return Scaffold(
      appBar: AppBar(
        title: Text('Reward Popup Demo', style: GoogleFonts.poppins(color: appBarTitleColor)), // Apply theme color
        backgroundColor: appBarBgColor, // Apply theme color
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () => _showRewardDialog(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: buttonBgColor, // Apply theme color
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: Text("Show Reward Dialog", style: GoogleFonts.poppins(color: Colors.white)),
        ),
      ),
    );
  }
}
