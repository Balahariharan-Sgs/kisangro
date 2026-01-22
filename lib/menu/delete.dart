import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kisangro/login/login.dart';
import 'package:provider/provider.dart'; // Import Provider
import '../home/theme_mode_provider.dart'; // Import ThemeModeProvider


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

  void _deleteAccount(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => deleteAccount(
        onCancel: () => Navigator.of(context).pop(),
        onLogout: () {
          Navigator.of(context).pop();
          // Add your logout logic here
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Logged out')),
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
          onPressed: () => _deleteAccount(context),
          child: const Text('Show Logout Dialog'),
        ),
      ),
    );
  }
}

class deleteAccount extends StatelessWidget {
  final VoidCallback onCancel;
  final VoidCallback onLogout;

  const deleteAccount({
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
    final Color redColor = Colors.red; // Always red
    final Color cancelBtnBgColor = orangeColor; // Always orange
    final Color cancelBtnTextColor = Colors.white;
    final Color deleteBtnBgColor = isDarkMode ? Colors.grey[700]! : const Color(0xffF0F0F0);
    final Color deleteBtnTextColor = isDarkMode ? Colors.white : Colors.black;
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
                    height: 100,
                    width: 100,
                    child: Image.asset(
                      'assets/delete.gif', // Replace with your image path
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
                        child: Icon(Icons.delete_forever_outlined, color: redColor, size: 22), // Always red
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
                              TextSpan(text: "Are you sure you want to",style: GoogleFonts.poppins(color: textColor)), // Apply theme color
                              TextSpan(
                                text: "Delete Account?",
                                style: GoogleFonts.poppins(
                                  color:redColor, // Always red
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
                          onPressed: (){
                            Navigator.push(context,MaterialPageRoute(builder: (context)=>const LoginApp())); // Added const
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: deleteBtnBgColor, // Apply theme color
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            "delete",
                            style: GoogleFonts.poppins(
                                fontSize: 16,color: deleteBtnTextColor // Apply theme color
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
