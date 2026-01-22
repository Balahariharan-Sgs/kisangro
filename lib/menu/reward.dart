import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:provider/provider.dart';
import 'package:kisangro/home/membership.dart';
import 'package:kisangro/home/myorder.dart';
import 'package:kisangro/home/noti.dart';
import 'package:kisangro/menu/wishlist.dart';
import 'package:kisangro/home/categories.dart';
import 'package:kisangro/home/cart.dart';
// Import your CustomDrawer and CustomAppBar

import 'package:kisangro/models/kyc_business_model.dart';
import 'package:kisangro/models/kyc_image_provider.dart';
import 'package:kisangro/home/bottom.dart';

import '../common/common_app_bar.dart';
import '../home/custom_drawer.dart';
import '../home/theme_mode_provider.dart';
 // Import the new ThemeModeProvider
import 'package:kisangro/login/login.dart'; // Import LoginApp for logout
import 'package:flutter_rating_bar/flutter_rating_bar.dart'; // For rating bar in dialog
import 'package:kisangro/menu/logout.dart'; // For LogoutConfirmationDialog


class RewardScreen extends StatefulWidget {
  const RewardScreen({super.key});

  @override
  State<RewardScreen> createState() => _RewardScreenState();
}

class _RewardScreenState extends State<RewardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // For the Rate Us dialog (re-added as per original context)
  double _rating = 4.0;
  final TextEditingController _reviewController = TextEditingController();
  static const int maxChars = 100;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _reviewController.dispose(); // Ensure controller is disposed
    super.dispose();
  }

  /// Shows a confirmation dialog for logging out, clears navigation stack.
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // User must tap a button to dismiss
      builder: (context) => LogoutConfirmationDialog(
        onCancel: () => Navigator.of(context).pop(), // Close dialog on cancel
        onLogout: () {
          // Perform logout actions and navigate to LoginApp, clearing navigation stack
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LoginApp()),
                (Route<dynamic> route) => false, // Remove all routes below
          );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Logged out successfully!')),
          );
        },
      ),
    );
  }

  /// Shows a dialog for giving ratings and writing a review about the app.
  void showComplaintDialog(BuildContext context) {
    final themeMode = Provider.of<ThemeModeProvider>(context, listen: false).themeMode;
    final isDarkMode = themeMode == ThemeMode.dark;

    final Color dialogBackgroundColor = isDarkMode ? Colors.grey[850]! : Colors.white;
    final Color textColor = isDarkMode ? Colors.white : Colors.black87;
    final Color hintColor = isDarkMode ? Colors.grey[400]! : Colors.grey;
    final Color borderColor = isDarkMode ? Colors.grey[600]! : Colors.grey;
    final Color orangeColor = const Color(0xffEB7720);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: dialogBackgroundColor, // Apply theme color
          content: StatefulBuilder(
            // Use StatefulBuilder to manage dialog's internal state for _rating and _reviewController
            builder: (context, setState) {
              return SizedBox(
                width: 328, // Fixed width for dialog content
                child: Column(
                  mainAxisSize: MainAxisSize.min, // Make column content fit
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Align(
                      alignment: Alignment.topRight,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context), // Close dialog
                        child: const Icon(
                          Icons.close,
                          color: Color(0xffEB7720), // Orange close icon
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Give ratings and write a review about your experience using this app.",
                      style: GoogleFonts.lato(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: textColor, // Apply theme color
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Text("Rate:", style: GoogleFonts.lato(fontSize: 16, color: textColor)), // Apply theme color
                        const SizedBox(width: 12),
                        RatingBar.builder(
                          // Star rating bar
                          initialRating: _rating,
                          minRating: 1,
                          direction: Axis.horizontal,
                          allowHalfRating: false,
                          itemCount: 5,
                          itemSize: 32,
                          unratedColor: isDarkMode ? Colors.grey[700] : Colors.grey[300], // Apply theme color
                          itemBuilder: (context, _) => const Icon(
                            Icons.star,
                            color: Color(0xffEB7720),
                          ),
                          onRatingUpdate: (rating) {
                            setState(() {
                              _rating = rating; // Update rating state
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _reviewController,
                      maxLength: maxChars,
                      maxLines: 3,
                      style: GoogleFonts.lato(color: textColor), // Apply theme color
                      decoration: InputDecoration(
                        hintText: 'Write here',
                        hintStyle: GoogleFonts.lato(color: hintColor), // Apply theme color
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: borderColor), // Apply theme color
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: borderColor), // Apply theme color
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: const Color(0xffEB7720)), // Orange for focused
                        ),
                        counterText: '', // Hide default counter text
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 12,
                        ),
                      ),
                      onChanged: (_) => setState(
                              () {}), // Rebuild to update character count dynamically
                    ),
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        '${_reviewController.text.length}/$maxChars', // Character counter
                        style: GoogleFonts.lato(
                          fontSize: 12,
                          color: hintColor, // Apply theme color
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xffEB7720),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(context); // Close review dialog

                          // Show "Thank you" confirmation dialog
                          showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              backgroundColor: dialogBackgroundColor, // Apply theme color
                              contentPadding: const EdgeInsets.all(24),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.check_circle,
                                    color: Color(0xffEB7720),
                                    size: 48,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Thank you!',
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: textColor, // Apply theme color
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Thanks for rating us.',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: isDarkMode ? Colors.white70 : Colors.black54, // Apply theme color
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: () =>
                                          Navigator.pop(context), // Close thank you dialog
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                        const Color(0xffEB7720),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                          BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: Text(
                                        'OK',
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        child: Text(
                          'Submit',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Access the KycBusinessDataProvider
    final kycBusinessProvider = Provider.of<KycBusinessDataProvider>(context);
    final kycData = kycBusinessProvider.kycBusinessData;
    final themeMode = Provider.of<ThemeModeProvider>(context).themeMode;
    final isDarkMode = themeMode == ThemeMode.dark;

    // Use KYC data for name and WhatsApp number, with "N/A" fallback
    final String displayName = kycData?.fullName?.isNotEmpty == true
        ? "Hi ${kycData!.fullName!.split(' ').first}!"
        : "Hi Smart!"; // Default if no name
    final String displayWhatsAppNumber = kycData?.whatsAppNumber?.isNotEmpty == true
        ? kycData!.whatsAppNumber!
        : "9876543210"; // Default if no number

    // Define colors based on theme
    final Color backgroundColor = isDarkMode ? Colors.black : const Color(0xFFFFF3E9);
    final Color profileCardColor = isDarkMode ? Colors.grey[850]! : Colors.white;
    final Color profileCardShadowColor = isDarkMode ? Colors.transparent : Colors.black12;
    final Color profileTextColor = isDarkMode ? Colors.white : Colors.black;
    final Color orangeColor = const Color(0xffEB7720); // Orange color, remains constant
    final Color dottedBorderColor = isDarkMode ? Colors.red.shade300 : Colors.red;
    final Color logoColor = isDarkMode ? Colors.white70 : Colors.black; // Adjust logo color for dark mode


    return PopScope( // <--- PopScope remains for back gesture control
      canPop: false, // Prevent default back behavior
      onPopInvoked: (didPop) {
        if (didPop) return; // If the pop was successful, do nothing.
        // If pop was not successful (e.g., canPop was false),
        // explicitly navigate back to the home screen.
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const Bot(initialIndex: 0)),
              (Route<dynamic> route) => false, // Remove all previous routes
        );
      },
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: backgroundColor, // Apply theme color
        drawer: CustomDrawer( // Integrate CustomDrawer
          showComplaintDialog: showComplaintDialog, // Pass the method
          showLogoutDialog: _showLogoutDialog, // Pass the method
        ),
        appBar: CustomAppBar( // Integrate CustomAppBar
          title: "Reward Points", // Set the title
          showBackButton: false, // Do NOT show back button
          showMenuButton: true, // Show menu button to open the drawer
          scaffoldKey: _scaffoldKey, // Pass the scaffold key
          isMyOrderActive: false, // Not active
          isWishlistActive: false, // Not active
          isNotiActive: false, // Not active
          // showWhatsAppIcon is false by default, matching original behavior
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Top Profile Card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: profileCardColor, // Apply theme color
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 8,
                      color: profileCardShadowColor, // Apply theme color
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Profile Image (from KYC)
                    DottedBorder(
                      borderType: BorderType.Circle,
                      color: dottedBorderColor, // Apply theme color
                      strokeWidth: 2,
                      dashPattern: const [6, 3],
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(30),
                          child: kycData?.shopImageBytes != null
                              ? Image.memory(
                            kycData!.shopImageBytes!,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                          )
                              : Image.asset(
                            'assets/profile.png',
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            color: isDarkMode ? Colors.white70 : null, // Adjust profile icon color for dark mode
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: profileTextColor), // Apply theme color
                        ),
                        const SizedBox(height: 4),
                        Text(
                          displayWhatsAppNumber,
                          style: GoogleFonts.poppins(fontSize: 16, color: orangeColor), // Always orange
                        ),
                      ],
                    ),
                    const Spacer(),
                    Image.asset(
                      'assets/logo.png',
                      height: 40,
                      width: 40,
                      color: logoColor, // Apply theme color
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              // Wings GIF
              Image.asset(
                'assets/wings.gif',
                height: 100,
                color: isDarkMode ? Colors.white70 : null, // Adjust GIF color for dark mode
              ),
              const SizedBox(height: 10),
              Text(
                "Your Reward Points",
                style: GoogleFonts.poppins(fontSize: 18, color: orangeColor), // Always orange
              ),
              const SizedBox(height: 10),
              Text(
                "500",
                style: GoogleFonts.poppins(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: orangeColor, // Always orange
                ),
              ),
              const SizedBox(height: 20),
              // Conversion Box
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: orangeColor, // Always orange
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "100 Points = 100 ₹",
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 16),
                ),
              ),
              const SizedBox(height: 30),
              // Reward Points Text + Verified GIF
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      "Get Reward Points\nFor Every\nPurchase You Make",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: orangeColor, // Always orange
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Image.asset(
                    'assets/verified.gif',
                    height: 80,
                    width: 80,
                    fit: BoxFit.contain,
                    color: isDarkMode ? Colors.white70 : null, // Adjust GIF color for dark mode
                  ),
                ],
              ),
              const SizedBox(height: 30),
              Text(
                "Reward Conversion Ratio",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: orangeColor, // Always orange
                  decoration: TextDecoration.underline,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "1% Of Total Amount\nBefore Adding GST",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: orangeColor, // Always orange
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
