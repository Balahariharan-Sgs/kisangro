import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kisangro/home/myorder.dart';
import 'package:kisangro/home/noti.dart';
import 'package:kisangro/login/login.dart';
import 'package:kisangro/menu/delete.dart';
import 'package:kisangro/menu/logout.dart';
import 'package:kisangro/menu/wishlist.dart';
import 'package:provider/provider.dart'; // Import Provider
import '../common/common_app_bar.dart';
import 'package:kisangro/home/bottom.dart'; // Import Bot for navigation (for back button functionality)
import '../home/theme_mode_provider.dart';
 // Import the new ThemeModeProvider

class SettingsPage extends StatefulWidget {
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // Removed isNotificationOn, replaced with specific notification types
  bool _isEmailNotificationOn = true;
  bool _isSmsNotificationOn = true;
  bool _isWhatsappNotificationOn = true;

  void _deleteAccount(BuildContext context) {
    // Access the theme mode to style the dialog
    final themeMode = Provider.of<ThemeModeProvider>(context, listen: false).themeMode;
    final isDarkMode = themeMode == ThemeMode.dark;

    final Color dialogBackgroundColor = isDarkMode ? Colors.grey[850]! : Colors.white;
    final Color textColor = isDarkMode ? Colors.white : Colors.black;
    final Color buttonColor = const Color(0xffEB7720); // Orange

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        backgroundColor: dialogBackgroundColor, // Apply theme color
        title: Text(
          'Confirm Delete Account',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: textColor, // Apply theme color
          ),
        ),
        content: Text(
          'Are you sure you want to delete your account? This action cannot be undone.',
          style: GoogleFonts.poppins(color: textColor), // Apply theme color
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(), // Close dialog on cancel
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: buttonColor),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LoginApp()), // replace 'login()' with your LoginScreen
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Account deleted successfully!')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: buttonColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Delete',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeModeProvider = Provider.of<ThemeModeProvider>(context);
    final isDarkMode = themeModeProvider.themeMode == ThemeMode.dark;

    // Define colors based on theme
    final Color backgroundColor = isDarkMode ? Colors.black : const Color(0xFFFDF3E7);
    final Color gradientStartColor = isDarkMode ? Colors.black : const Color(0xffFFD9BD);
    final Color gradientEndColor = isDarkMode ? Colors.black : const Color(0xffFFFFFF);
    final Color textColor = isDarkMode ? Colors.white : Colors.black87;
    final Color orangeColor = const Color(0xffEB7720); // Orange color, remains constant
    final Color switchActiveColor = orangeColor;
    final Color switchInactiveThumbColor = isDarkMode ? Colors.grey[700]! : Colors.grey[300]!;
    final Color switchInactiveTrackColor = isDarkMode ? Colors.grey[800]! : Colors.grey[400]!;
    final Color dividerColor = isDarkMode ? Colors.grey[700]! : Colors.grey[300]!;
    final Color languageContainerColor = isDarkMode ? Colors.grey[800]! : Colors.grey[200]!;
    final Color languageBorderColor = isDarkMode ? Colors.grey[600]! : Colors.grey[400]!;
    final Color deleteButtonBackgroundColor = isDarkMode ? Colors.grey[800]! : Colors.grey[300]!;
    final Color deleteButtonForegroundColor = isDarkMode ? Colors.white70 : Colors.black87;

    return PopScope(
      // Allow popping if not on the main home screen, otherwise navigate to Bot
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const Bot(initialIndex: 0)),
              (Route<dynamic> route) => false,
        );
      },
      child: Scaffold(
        backgroundColor: backgroundColor, // Apply theme color
        appBar: CustomAppBar(
          title: "Settings",
          showBackButton: true,
          showMenuButton: false,
          isMyOrderActive: false,
          isWishlistActive: false,
          isNotiActive: false,
        ),
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                gradientStartColor, // Apply theme color
                gradientEndColor, // Apply theme color
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Terms & Conditions
                RichText(
                  text: TextSpan(
                    text: 'Read Kisangro ',
                    style: GoogleFonts.poppins(
                      color: textColor, // Apply theme color
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                    children: [
                      TextSpan(
                        text: 'Terms & Conditions',
                        style: GoogleFonts.lato(
                          color: orangeColor,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Preferred Language
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Preferred Language',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        color: textColor, // Apply theme color
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: languageContainerColor, // Apply theme color
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: languageBorderColor), // Apply theme color
                      ),
                      child: Text(
                        'English',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textColor, // Apply theme color
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Dark Theme Toggle
                /*Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Dark Theme',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        color: textColor, // Apply theme color
                      ),
                    ),
                    Switch(
                      value: isDarkMode,
                      activeColor: switchActiveColor,
                      inactiveThumbColor: switchInactiveThumbColor,
                      inactiveTrackColor: switchInactiveTrackColor,
                      onChanged: (val) {
                        themeModeProvider.toggleThemeMode(); // Toggle theme using the provider
                      },
                    ),
                  ],
                ),
                Divider(color: dividerColor, height: 20, thickness: 1), // Apply theme color
                const SizedBox(height: 16), // Added some spacing*/

                // Notification Section Title
                Text(
                  'Notification',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: textColor, // Apply theme color
                  ),
                ),
                const SizedBox(height: 8),

                // Email Notifications
                Row(
                  children: [
                    Text(
                      'Email',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textColor, // Apply theme color
                      ),
                    ),
                    const Spacer(),
                    Switch(
                      value: _isEmailNotificationOn,
                      activeColor: switchActiveColor,
                      inactiveThumbColor: switchInactiveThumbColor,
                      inactiveTrackColor: switchInactiveTrackColor,
                      onChanged: (val) {
                        setState(() {
                          _isEmailNotificationOn = val;
                        });
                      },
                    ),
                  ],
                ),
                Divider(color: dividerColor, height: 20, thickness: 1), // Apply theme color

                // SMS Notifications
                Row(
                  children: [
                    Text(
                      'SMS',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textColor, // Apply theme color
                      ),
                    ),
                    const Spacer(),
                    Switch(
                      value: _isSmsNotificationOn,
                      activeColor: switchActiveColor,
                      inactiveThumbColor: switchInactiveThumbColor,
                      inactiveTrackColor: switchInactiveTrackColor,
                      onChanged: (val) {
                        setState(() {
                          _isSmsNotificationOn = val;
                        });
                      },
                    ),
                  ],
                ),
                Divider(color: dividerColor, height: 20, thickness: 1), // Apply theme color

                // WhatsApp Notifications
                Row(
                  children: [
                    Text(
                      'WhatsApp',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textColor, // Apply theme color
                      ),
                    ),
                    const Spacer(),
                    Switch(
                      value: _isWhatsappNotificationOn,
                      activeColor: switchActiveColor,
                      inactiveThumbColor: switchInactiveThumbColor,
                      inactiveTrackColor: switchInactiveTrackColor,
                      onChanged: (val) {
                        setState(() {
                          _isWhatsappNotificationOn = val;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 48), // Spacing before delete button

                // Delete Account Button
                Center(
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: deleteButtonBackgroundColor, // Apply theme color
                        foregroundColor: deleteButtonForegroundColor, // Apply theme color
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () {
                        _deleteAccount(context);
                      },
                      child: Text(
                        'Delete Account',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
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
