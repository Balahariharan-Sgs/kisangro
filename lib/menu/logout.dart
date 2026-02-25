import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kisangro/login/splashscreen.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import SharedPreferences
import 'package:provider/provider.dart'; // Import Provider
import '../home/theme_mode_provider.dart'; // Import ThemeModeProvider

void main() {
  runApp(const logout());
}

class logout extends StatelessWidget {
  const logout({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Logout Dialog Demo',
      home: const HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => LogoutConfirmationDialog(
        onCancel: () => Navigator.of(context).pop(),
        onLogout: () async {
          Navigator.of(context).pop();
          
          // Clear all user data from SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          
          // Clear all login-related data
          await prefs.remove('isLoggedIn');
          await prefs.remove('cus_id');
          await prefs.remove('hasUploadedLicenses');
          await prefs.remove('fcm_token');
          await prefs.remove('fcm_token_synced');
          // Optional: Clear location data if you want fresh location on next login
          // await prefs.remove('latitude');
          // await prefs.remove('longitude');
          // await prefs.remove('device_id');
          
          // Clear any other user-specific data
          // You can add more keys to remove as needed
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Logged out successfully')),
          );
          
          // Navigate to splashscreen after logout
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const splashscreen()),
            (Route<dynamic> route) => false,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Logout Dialog Demo')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => _showLogoutDialog(context),
          child: const Text('Show Logout Dialog'),
        ),
      ),
    );
  }
}

class LogoutConfirmationDialog extends StatelessWidget {
  final VoidCallback onCancel;
  final VoidCallback onLogout;

  const LogoutConfirmationDialog({
    super.key,
    required this.onCancel,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final themeMode = Provider.of<ThemeModeProvider>(context).themeMode;
    final isDarkMode = themeMode == ThemeMode.dark;

    // Define colors based on theme
    final Color dialogBackgroundColor = isDarkMode ? Colors.grey[850]! : Colors.white;
    final Color textColor = isDarkMode ? Colors.white : Colors.black87;
    final Color orangeColor = const Color(0xFFEB7720); // Always orange
    final Color cancelBtnBgColor = orangeColor; // Always orange
    final Color cancelBtnTextColor = Colors.white;
    final Color logoutBtnBgColor = isDarkMode ? Colors.grey[700]! : const Color(0xffF0F0F0);
    final Color logoutBtnTextColor = isDarkMode ? Colors.white : Colors.black;
    final Color closeIconColor = orangeColor; // Always orange
    // Removed gifColor as it's no longer needed for tinting


    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      backgroundColor: dialogBackgroundColor, // Apply theme color
      child: SizedBox(
        width: 340,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Illustration placeholder (replace with your asset)
                  SizedBox(
                    height: 138,
                    width: 138,
                    child: Image.asset(
                      'assets/logout.gif', // Replace with your image path
                      fit: BoxFit.contain,
                      // Removed color property
                    ),
                    // If no image, uncomment below:
                    // child: Icon(Icons.account_circle, size: 80, color: orange),
                  ),
                  const SizedBox(height: 16),
                  // Text with icon
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        decoration: const BoxDecoration(
                          // border: Border.all(color: Color(0xffEB7720), width: 1.8),
                          // borderRadius: BorderRadius.circular(6),
                        ),
                        padding: const EdgeInsets.all(2),
                        child: Icon(Icons.delete_forever_outlined, color: orangeColor, size: 22), // Always orange
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: GoogleFonts.lato(
                              fontSize: 17,
                              color: textColor, // Apply theme color
                              fontWeight: FontWeight.w400,
                            ),
                            children: [
                              TextSpan(text: "Are you sure you want to\n",style: GoogleFonts.poppins(color: textColor)), // Apply theme color
                              TextSpan(
                                text: "Logout?",
                                style: GoogleFonts.poppins(
                                  color: orangeColor, // Always orange
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  // Buttons row
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          width: 130,
                          child: ElevatedButton(
                            onPressed: onCancel,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: cancelBtnBgColor, // Apply theme color
                              foregroundColor: cancelBtnTextColor, // Apply theme color
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              "Cancel",
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                color: cancelBtnTextColor, // Apply theme color
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      SizedBox(
                        height: 50,
                        width: 100,
                        child: ElevatedButton(
                          onPressed: onLogout, // Changed to call onLogout callback
                          style: ElevatedButton.styleFrom(
                            backgroundColor: logoutBtnBgColor, // Apply theme color
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            "Logout",
                            style: GoogleFonts.poppins(
                                fontSize: 16,color: logoutBtnTextColor // Apply theme color
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Close icon inside orange border circle
            Positioned(
              top: 12,
              right: 12,
              child: GestureDetector(
                onTap: onCancel,
                child: Container(
                  height: 15,
                  width: 15,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: orangeColor, width: 1), // Always orange
                  ),
                  padding: const EdgeInsets.only(right: 1),
                  child: Icon(
                    Icons.close,
                    size: 12,
                    color:closeIconColor, // Always orange
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}