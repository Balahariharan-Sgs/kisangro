import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // Import GoogleFonts for consistent styling
import 'package:provider/provider.dart'; // Import Provider
import '../home/theme_mode_provider.dart'; // Import ThemeModeProvider

class VerificationWarningPopup extends StatelessWidget {
  final VoidCallback? onProceed;
  final VoidCallback? onCancel;

  const VerificationWarningPopup({
    Key? key,
    this.onProceed,
    this.onCancel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeMode = Provider.of<ThemeModeProvider>(context).themeMode;
    final isDarkMode = themeMode == ThemeMode.dark;

    // Define colors based on theme
    final Color overlayColor = Colors.black.withOpacity(0.5);
    final Color dialogBackgroundColor = isDarkMode ? Colors.grey[850]! : Colors.white;
    final Color boxShadowColor = isDarkMode ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.1);
    final Color warningIconBgColor = (isDarkMode ? const Color(0xFFE87722).withOpacity(0.2) : const Color(0xFFE87722).withOpacity(0.1));
    final Color warningIconBorderColor = const Color(0xFFE87722); // Always orange
    final Color warningIconColor = const Color(0xFFE87722); // Always orange
    final Color noteTextColor = isDarkMode ? Colors.white : const Color(0xFF1A1A1A);
    final Color questionTextColor = isDarkMode ? Colors.white : const Color(0xFF1A1A1A);
    final Color proceedButtonColor = const Color(0xFFE87722); // Always orange
    final Color closeButtonBgColor = const Color(0xFFE87722); // Always orange
    final Color closeButtonIconColor = Colors.white;


    return Material(
      color: overlayColor, // Apply theme color
      child: Center(
        child: Stack( // Use a Stack to position the close button relative to the dialog
          alignment: Alignment.topRight, // Align close button to top right of the stack
          children: [
            Container(
              // Adjusted dimensions for a more compact, square look
              width: MediaQuery.of(context).size.width * 0.8, // 80% of screen width
              constraints: const BoxConstraints(maxWidth: 320), // Max width to prevent it from getting too large
              margin: const EdgeInsets.only(top: 18), // Added top margin to make space for the close button
              decoration: BoxDecoration(
                color: dialogBackgroundColor, // Apply theme color
                borderRadius: BorderRadius.circular(16), // Slightly reduced border radius
                boxShadow: [
                  BoxShadow(
                    color: boxShadowColor, // Apply theme color
                    blurRadius: 15, // Reduced blur for a cleaner look
                    offset: const Offset(0, 8), // Adjusted offset
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min, // Keep column size to minimum required
                children: [
                  // Warning icon (now the top element within the main content column)
                  Container(
                    margin: const EdgeInsets.only(top: 15, bottom: 10), // Reduced top margin
                    child: Container(
                      width: 80, // Reduced icon container size
                      height: 80,
                      decoration: BoxDecoration(
                        color: warningIconBgColor, // Apply theme color
                        shape: BoxShape.circle,
                      ),
                      child: Container(
                        margin: const EdgeInsets.all(6), // Reduced margin
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: warningIconBorderColor, // Always orange
                            width: 2, // Slightly thinner border
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.warning_outlined,
                          color: warningIconColor, // Always orange
                          size: 38, // Adjusted icon size
                        ),
                      ),
                    ),
                  ),

                  // Main content
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20), // Reduced padding
                    child: Column(
                      children: [
                        // Note text
                        RichText(
                          textAlign: TextAlign.center, // Centered text for compact look
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: 'Note: ',
                                style: GoogleFonts.poppins(
                                  fontSize: 14, // Reduced font size
                                  fontWeight: FontWeight.w600,
                                  color: noteTextColor, // Apply theme color
                                  height: 1.4, // Adjusted line height
                                ),
                              ),
                              TextSpan(
                                text: 'After editing your details, the re-verification process will begin. You won\'t be able to make purchases in the app until the verification is complete.',
                                style: GoogleFonts.poppins(
                                  fontSize: 14, // Reduced font size
                                  fontWeight: FontWeight.w400,
                                  color: noteTextColor, // Apply theme color
                                  height: 1.4, // Adjusted line height
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20), // Reduced spacing

                        // Question text
                        Text(
                          'Are you sure you want to proceed?',
                          style: GoogleFonts.poppins(
                            fontSize: 15, // Reduced font size
                            fontWeight: FontWeight.w500,
                            color: questionTextColor, // Apply theme color
                            height: 1.4, // Adjusted line height
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 24), // Reduced spacing

                        // Proceed button
                        SizedBox(
                          width: double.infinity,
                          height: 48, // Slightly reduced button height
                          child: ElevatedButton(
                            onPressed: onProceed ?? () => Navigator.of(context).pop(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: proceedButtonColor, // Always orange
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12), // Slightly reduced border radius
                              ),
                            ),
                            child: Text(
                              'Yes, Proceed',
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Close button (positioned on top of the main dialog container)
            Positioned(
              top: 30, // Position it at the very top of the stack
              right: 10, // Position it at the very right of the stack
              child: GestureDetector(
                onTap: onCancel ?? () => Navigator.of(context).pop(),
                child: Container(
                  width: 36, // Size of the close button circle
                  height: 36,
                  decoration: BoxDecoration(
                    color: closeButtonBgColor, // Always orange
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close,
                    color: closeButtonIconColor,
                    size: 20, // Icon size
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

// Helper class to show the popup (remains unchanged)
class VerificationPopupHelper {
  static Future<void> show(
      BuildContext context, {
        VoidCallback? onProceed,
        VoidCallback? onCancel,
      }) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.transparent,
      builder: (BuildContext context) {
        return VerificationWarningPopup(
          onProceed: onProceed,
          onCancel: onCancel,
        );
      },
    );
  }
}
