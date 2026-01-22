import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart'; // Import Provider
import '../home/theme_mode_provider.dart'; // Import ThemeModeProvider

class RatingPage extends StatefulWidget {
  const RatingPage({Key? key}) : super(key: key);

  @override
  State<RatingPage> createState() => _RatingPageState();
}

class _RatingPageState extends State<RatingPage> {
  double _rating = 4.0;
  final TextEditingController _controller = TextEditingController();
  static const int maxChars = 100;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = Provider.of<ThemeModeProvider>(context).themeMode;
    final isDarkMode = themeMode == ThemeMode.dark;

    // Define colors based on theme
    final Color dialogBackgroundColor = isDarkMode ? Colors.grey[850]! : Colors.white;
    final Color textColor = isDarkMode ? Colors.white : Colors.black87;
    final Color hintColor = isDarkMode ? Colors.grey[400]! : Colors.grey;
    final Color borderColor = isDarkMode ? Colors.grey[600]! : Colors.blueAccent; // Keeping blueAccent for border as per original, but can be themed
    final Color unratedStarColor = isDarkMode ? Colors.grey[700]! : Colors.grey[300]!;
    final Color thankYouDialogTextColor = isDarkMode ? Colors.white : Colors.black;
    final Color thankYouDialogSubtitleColor = isDarkMode ? Colors.white70 : Colors.black54;
    final Color orangeColor = const Color(0xffEB7720); // Orange color, remains constant


    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 328,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: dialogBackgroundColor, // Apply theme color
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 1), // Apply theme color
        ),
        child: Stack(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(Icons.close, color: orangeColor), // Always orange
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Give ratings and write a review about your experience using this app.",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: textColor, // Apply theme color
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Text(
                      "Rate:",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: textColor, // Apply theme color
                      ),
                    ),
                    const SizedBox(width: 12),
                    RatingBar.builder(
                      initialRating: _rating,
                      minRating: 1,
                      direction: Axis.horizontal,
                      allowHalfRating: false,
                      itemCount: 5,
                      itemSize: 32,
                      unratedColor: unratedStarColor, // Apply theme color
                      itemBuilder: (context, _) => Icon(
                        Icons.star,
                        color: orangeColor, // Always orange
                      ),
                      onRatingUpdate: (rating) {
                        setState(() {
                          _rating = rating;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _controller,
                  maxLength: maxChars,
                  maxLines: 3,
                  style: GoogleFonts.lato(color: textColor), // Apply theme color
                  decoration: InputDecoration(
                    hintText: 'Write here',
                    hintStyle: GoogleFonts.poppins(color: hintColor), // Apply theme color
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
                      borderSide: BorderSide(color: orangeColor), // Always orange
                    ),
                    contentPadding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                    counterText: '', // Hide default counter
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '${_controller.text.length}/$maxChars',
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
                      backgroundColor: orangeColor, // Always orange
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            backgroundColor: dialogBackgroundColor, // Apply theme color
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.all(24),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle,
                                    color: orangeColor, size: 48), // Always orange
                                const SizedBox(height: 16),
                                Text(
                                  'Thank you!',
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: thankYouDialogTextColor, // Apply theme color
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Thanks for rating us.',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: thankYouDialogSubtitleColor, // Apply theme color
                                  ),
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: () => Navigator.pop(context),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: orangeColor, // Always orange
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: Text(
                                      'OK',
                                      style: GoogleFonts.poppins(
                                          color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
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
          ],
        ),
      ),
    );
  }
}
