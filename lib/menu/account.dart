import 'package:flutter/cupertino.dart'; // For CupertinoIcons, if used
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // For custom fonts
import 'package:dotted_border/dotted_border.dart'; // For dotted borders
import 'package:kisangro/home/myorder.dart'; // Assuming this page exists
import 'package:kisangro/home/noti.dart'; // Assuming this page exists
import 'package:kisangro/menu/wishlist.dart'; // Assuming this page exists
import 'package:provider/provider.dart'; // For state management
import 'package:kisangro/models/kyc_image_provider.dart'; // Your custom KYC image provider
import 'dart:typed_data'; // Essential for Uint8List, which holds raw image data
import 'package:kisangro/models/license_provider.dart'; // Import LicenseProvider
import 'package:kisangro/login/licence.dart'; // Import licence1 for "Upload New" button
import 'package:kisangro/common/document_viewer_screen.dart'; // Import DocumentViewerScreen
import 'package:kisangro/models/kyc_business_model.dart';
import 'package:kisangro/login/kyc.dart'; // Import kyc for navigating to KYC edit page

// NEW: Import the VerificationWarningPopup and Helper
import 'package:kisangro/common/verification_warning_popup.dart'; // Adjust path if different
import '../common/common_app_bar.dart';
import '../home/bottom.dart'; // Import Bot for navigation (for back button functionality)
import '../home/theme_mode_provider.dart'; // Import ThemeModeProvider


class MyAccountPage extends StatelessWidget {
  const MyAccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeMode = Provider.of<ThemeModeProvider>(context).themeMode;
    final isDarkMode = themeMode == ThemeMode.dark;

    final orange = const Color(0xFFEB7720); // Your app's orange theme color

    // Define colors based on theme
    final Color gradientStartColor = isDarkMode ? Colors.black : const Color(0xffFFD9BD);
    final Color gradientEndColor = isDarkMode ? Colors.black : const Color(0xffFFFFFF);
    final Color textColor = isDarkMode ? Colors.white : Colors.black87;
    final Color subtitleColor = isDarkMode ? Colors.white70 : Colors.black54;
    final Color dottedBorderColor = isDarkMode ? Colors.red.shade300 : Colors.red;
    final Color businessDetailCheckColor = isDarkMode ? Colors.green.shade300 : Colors.green;
    final Color licenseBorderColor = isDarkMode ? Colors.green.shade300 : Colors.green;
    final Color licenseNotUploadedBgColor = isDarkMode ? Colors.grey[800]! : Colors.grey.shade200;
    final Color licenseNotUploadedIconColor = isDarkMode ? Colors.grey[400]! : Colors.grey[400]!;
    final Color licenseNotUploadedTextColor = isDarkMode ? Colors.grey[500]! : Colors.grey[600]!;


    final licenseProvider = Provider.of<LicenseProvider>(context); // Access LicenseProvider
    final kycBusinessDataProvider = Provider.of<KycBusinessDataProvider>(context); // NEW: Access KycBusinessDataProvider
    final kycData = kycBusinessDataProvider.kycBusinessData; // Get the KYC data

    return Scaffold(
      appBar: CustomAppBar( // Integrated CustomAppBar
        title: "My Account", // Set the title
        showBackButton: true, // Show back button
        showMenuButton: false, // Do NOT show menu button (drawer icon)
        // scaffoldKey is not needed here as there's no drawer
        isMyOrderActive: false, // Not active
        isWishlistActive: false, // Not active
        isNotiActive: false, // Not active
        // showWhatsAppIcon is false by default, matching original behavior
      ),
      body: Container( // Added Container for the gradient background
        height: double.infinity,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [gradientStartColor, gradientEndColor], // Consistent theme
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 24, bottom: 8),
                  child: Stack(
                    children: [
                      DottedBorder(
                        borderType: BorderType.Circle,
                        color: dottedBorderColor, // Apply theme color
                        strokeWidth: 2,
                        dashPattern: const [6, 3],
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(50),
                            // Use Consumer to listen for changes in KycImageProvider
                            // and display the image dynamically.
                            child: kycData?.shopImageBytes != null
                                ? Image.memory( // Use Image.memory for Uint8List display
                              kycData!.shopImageBytes!,
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            )
                                : Image.asset(
                              'assets/profile.png', // Fallback to default profile image if no image is uploaded
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                              color: isDarkMode ? Colors.white70 : null, // Adjust profile icon color for dark mode
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 1,
                        bottom: 0,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // Show the VerificationWarningPopup when the edit button is pressed
                            VerificationPopupHelper.show(
                              context,
                              onProceed: () {
                                Navigator.of(context).pop(); // Dismiss the popup
                                // Navigate to KYC edit page (kyc.dart)
                                Navigator.push(context, MaterialPageRoute(builder: (context) => kyc()));
                              },
                              onCancel: () {
                                Navigator.of(context).pop(); // Dismiss the popup
                                // Optional: Show a message if cancelled
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('KYC update cancelled.', style: GoogleFonts.poppins())),
                                );
                              },
                            );
                          },
                          icon: const Icon(
                            Icons.edit,
                            color: Colors.white,
                            size: 16,
                          ),
                          label: const SizedBox.shrink(), // Use SizedBox.shrink() to provide an empty widget
                          style: ElevatedButton.styleFrom(
                            backgroundColor: orange, // Ensure 'orange' is defined (e.g., const Color(0xffEB7720))
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Primary Details",
                        style: GoogleFonts.poppins(
                            color: orange, // Always orange
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    _buildIconTextRow(Icons.person_outline, "Full Name", kycData?.fullName ?? "N/A", textColor, subtitleColor), // Pass theme colors
                    _buildIconTextRow(Icons.email_outlined, "Mail Id", kycData?.mailId ?? "N/A", textColor, subtitleColor), // Pass theme colors
                    _buildIconTextRow(CupertinoIcons.phone_circle, "WhatsApp Number", kycData?.whatsAppNumber ?? "N/A", textColor, subtitleColor), // Pass theme colors
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Business Details",
                        style: GoogleFonts.poppins(
                            color: orange, // Always orange
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    _buildBusinessDetail("Business Name", kycData?.businessName ?? "N/A", textColor, subtitleColor, businessDetailCheckColor), // Pass theme colors
                    _buildBusinessDetail("GSTIN", kycData?.gstin ?? "N/A", textColor, subtitleColor, businessDetailCheckColor), // Pass theme colors
                    _buildBusinessDetail("Aadhaar Number (Owner)", kycData?.aadhaarNumber ?? "N/A", textColor, subtitleColor, businessDetailCheckColor), // Pass theme colors
                    _buildBusinessDetail("PAN Number", kycData?.panNumber ?? "N/A", textColor, subtitleColor, businessDetailCheckColor), // Pass theme colors
                    _buildBusinessDetail("Nature Of Core Business", kycData?.natureOfBusiness ?? "N/A", textColor, subtitleColor, businessDetailCheckColor), // Pass theme colors
                    _buildBusinessDetail("Business Contact Number", kycData?.businessContactNumber ?? "N/A", textColor, subtitleColor, businessDetailCheckColor), // Pass theme colors
                    // NEW: Conditionally display Business Address
                    if (kycData?.businessAddress != null && kycData!.businessAddress!.isNotEmpty)
                      _buildBusinessDetail("Business Address", kycData.businessAddress!, textColor, subtitleColor, businessDetailCheckColor), // Pass theme colors
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  "License Details",
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: orange, // Always orange
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Display Pesticide License
              _buildLicenseCard(
                context,
                index: 1,
                title: "Pesticide",
                licenseData: licenseProvider.pesticideLicense, // Pass pesticide data
                onUploadNew: () {
                  // --- MODIFIED HERE: Show popup before navigating to licence1() ---
                  VerificationPopupHelper.show(
                    context,
                    onProceed: () {
                      Navigator.of(context).pop(); // Dismiss the popup
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => licence1()), // Go to licence1 to select type
                      );
                    },
                    onCancel: () {
                      Navigator.of(context).pop(); // Dismiss the popup
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('License update cancelled.', style: GoogleFonts.poppins())),
                      );
                    },
                  );
                  // --- END MODIFICATION ---
                },
                isDarkMode: isDarkMode, // Pass isDarkMode
              ),
              const SizedBox(height: 20),
              Divider(color: isDarkMode ? Colors.grey[700] : Colors.grey), // Apply theme color
              const SizedBox(height: 20),
              // Display Fertilizer License
              _buildLicenseCard(
                context,
                index: 2,
                title: "Fertilizer", // Changed from "Insecticide" to "Fertilizer" as per context
                licenseData: licenseProvider.fertilizerLicense, // Pass fertilizer data
                onUploadNew: () {
                  // --- MODIFIED HERE: Show popup before navigating to licence1() ---
                  VerificationPopupHelper.show(
                    context,
                    onProceed: () {
                      Navigator.of(context).pop(); // Dismiss the popup
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => licence1()), // Go to licence1 to select type
                      );
                    },
                    onCancel: () {
                      Navigator.of(context).pop(); // Dismiss the popup
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('License update cancelled.', style: GoogleFonts.poppins())),
                      );
                    },
                  );
                  // --- END MODIFICATION ---
                },
                isDarkMode: isDarkMode, // Pass isDarkMode
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  /// Helper method to build a row with an icon, label, and value for primary details.
  Widget _buildIconTextRow(IconData icon, String label, String value, Color textColor, Color subtitleColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: subtitleColor), // Apply subtitleColor
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: GoogleFonts.poppins(
                      color: subtitleColor, fontSize: 14)), // Apply subtitleColor
              Text(value,
                  style: GoogleFonts.poppins(
                      color: textColor, // Apply textColor
                      fontSize: 16,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }

  /// Helper method to build a row for business details with a checkmark.
  Widget _buildBusinessDetail(String title, String value, Color textColor, Color subtitleColor, Color checkColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle, size: 20, color: checkColor), // Apply checkColor
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.poppins(
                        color: subtitleColor, fontSize: 14)), // Apply subtitleColor
                Text(value,
                    style: GoogleFonts.poppins(
                        color: textColor, // Apply textColor
                        fontSize: 16,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Helper method to build a license card with dynamic data.
  Widget _buildLicenseCard(BuildContext context,
      {required int index,
        required String title,
        LicenseData? licenseData, // Make licenseData nullable
        required VoidCallback onUploadNew,
        required bool isDarkMode}) { // Add isDarkMode parameter
    const orange = Color(0xFFEB7720);
    bool isUploaded = licenseData?.imageBytes != null;
    // MODIFIED: Directly use licenseData?.licenseNumber and licenseData?.displayDate
    String licenseNumber = licenseData?.licenseNumber ?? 'N/A';
    String expiryDisplay = licenseData?.displayDate ?? 'N/A';

    // Define colors based on theme for the license card
    final Color licenseCardBgColor = isDarkMode ? Colors.grey[850]! : Colors.grey.shade200;
    final Color licenseCardBorderColor = isDarkMode ? Colors.grey[700]! : Colors.black26;
    final Color licenseCardUploadedBorderColor = isDarkMode ? Colors.green.shade300 : Colors.green;
    final Color licenseCardTextColor = isDarkMode ? Colors.white : Colors.black;
    final Color licenseCardPlaceholderIconColor = isDarkMode ? Colors.grey[400]! : Colors.grey[400]!;
    final Color licenseCardPlaceholderTextColor = isDarkMode ? Colors.grey[500]! : Colors.grey[600]!;


    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("$index. $title License", // Updated title for clarity
              style: GoogleFonts.poppins(
                  fontSize: 16, fontWeight: FontWeight.w500, color: licenseCardTextColor)), // Apply theme color
          const SizedBox(height: 10),
          GestureDetector( // Added GestureDetector to make the container tappable
            onTap: isUploaded
                ? () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DocumentViewerScreen(
                    documentBytes: licenseData!.imageBytes,
                    isImage: licenseData.isImage,
                    title: '$title License Document',
                  ),
                ),
              );
            }
                : null, // Disable tap if no document is uploaded
            child: Center(
              child: Container(
                width: 160,
                height: 200,
                decoration: BoxDecoration(
                  color: licenseCardBgColor, // Apply theme color
                  border: Border.all(color: isUploaded ? licenseCardUploadedBorderColor : licenseCardBorderColor), // Apply theme color
                  borderRadius: BorderRadius.circular(6),
                ),
                child: isUploaded
                    ? (licenseData!.isImage
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.memory(
                    licenseData.imageBytes!,
                    fit: BoxFit.cover,
                  ),
                )
                    : Center(
                    child: Icon(Icons.picture_as_pdf, color: orange, size: 60))) // Always orange
                    : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt, color: licenseCardPlaceholderIconColor, size: 40), // Apply theme color
                      const SizedBox(height: 8),
                      Text(
                        'No document uploaded',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(color: licenseCardPlaceholderTextColor, fontSize: 12), // Apply theme color
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Display License Number and Expiry Date
          if (isUploaded) ...[
            Text('License Number: ${licenseNumber}', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: licenseCardTextColor)), // Apply theme color
            const SizedBox(height: 4),
            Text('Expiry Date: ${licenseData!.noExpiry ? 'Permanent' : expiryDisplay}', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: licenseCardTextColor)), // Apply theme color
            const SizedBox(height: 10),
          ],
          Center(
            child: ElevatedButton(
              onPressed: onUploadNew, // Use the provided callback for "Upload New"
              style: ElevatedButton.styleFrom(
                backgroundColor: orange, // Always orange
                padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              child: Text(
                isUploaded ? "Re-upload" : "Upload Now", // Change button text based on upload status
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
