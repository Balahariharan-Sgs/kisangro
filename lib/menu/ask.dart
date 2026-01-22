import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kisangro/menu/chat.dart';
import 'package:kisangro/home/cart.dart'; // Import Cart for box.png
import 'package:kisangro/menu/wishlist.dart'; // Import WishlistPage for heart.png
import 'package:kisangro/home/noti.dart'; // Import noti for noti.png
import 'package:provider/provider.dart'; // Import Provider
import '../home/theme_mode_provider.dart'; // Import ThemeModeProvider


import '../common/common_app_bar.dart';


class AskUsPage extends StatefulWidget {
  @override
  _AskUsPageState createState() => _AskUsPageState();
}

class _AskUsPageState extends State<AskUsPage> {
  final List<bool> _commonExpanded = [false, false, false, false];
  final List<bool> _buyersExpanded = [false, false, false, false];

  final String sampleAnswer =
      "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut";

  @override
  Widget build(BuildContext context) {
    final themeMode = Provider.of<ThemeModeProvider>(context).themeMode;
    final isDarkMode = themeMode == ThemeMode.dark;

    // Define colors based on theme
    final Color gradientStartColor = isDarkMode ? Colors.black : const Color(0xffFFD9BD);
    final Color gradientEndColor = isDarkMode ? Colors.black : const Color(0xffFFFFFF);
    final Color textColor = isDarkMode ? Colors.white : Colors.black87;
    final Color titleColor = isDarkMode ? Colors.white : Colors.black;
    final Color dividerColor = isDarkMode ? Colors.grey[700]! : Colors.grey;
    final Color expansionTileBgColor = isDarkMode ? Colors.grey[850]! : Colors.white;
    final Color expansionTileShadowColor = isDarkMode ? Colors.transparent : Colors.black.withOpacity(0.03);
    final Color expansionTileIconColor = isDarkMode ? Colors.white70 : Colors.black54;


    return Scaffold(
      appBar: CustomAppBar( // Integrated CustomAppBar
        title: "Ask Us!", // Set the title
        showBackButton: true, // Show back button
        showMenuButton: false, // Do NOT show menu button (drawer icon)
        // scaffoldKey is not needed here as there's no drawer
        isMyOrderActive: false, // Not active
        isWishlistActive: false, // Not active
        isNotiActive: false, // Not active
        // showWhatsAppIcon is false by default, matching original behavior
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
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row with image and text
                  Padding(
                    padding: const EdgeInsets.only(left: 50),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/ask1.png',
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                          // Removed color property
                        ),

                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(left: 20),
                            child: RichText(
                              text: TextSpan(
                                style: GoogleFonts.lato(
                                  fontSize: 17,
                                  color: textColor, // Apply theme color
                                  height: 1.3,
                                ),
                                children: [
                                  TextSpan(text: "‘Stuck?\nLet Us Untangle It\n",style: GoogleFonts.poppins(fontSize: 14)),
                                  TextSpan(
                                    text: "For You!’",
                                    style: GoogleFonts.lato(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                      color: titleColor, // Apply theme color
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Contact box as an image
                  Align(
                    alignment: Alignment.centerLeft,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Center(
                        child: Image.asset(
                          'assets/ask2.png',
                          width: 267,
                          height: 58,
                          fit: BoxFit.cover,
                          // Removed color property
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Divider(color: dividerColor), // Apply theme color

                  _buildSectionTitle('Common Queries', textColor), // Pass textColor
                  const SizedBox(height: 12,),
                  ...List.generate(4, (index) {
                    return _buildCustomExpansionTile(
                      title: '${index + 1}. How to sell the product on Kisangro?',
                      isExpanded: _commonExpanded[index],
                      onExpansionChanged: (expanded) {
                        setState(() {
                          _commonExpanded[index] = expanded;
                        });
                      },
                      answer: sampleAnswer,
                      isDarkMode: isDarkMode, // Pass isDarkMode
                    );
                  }),
                  const SizedBox(height: 32),

                  // Buyers Queries Section (centered with underline)
                  _buildSectionTitle('Buyers Queries', textColor), // Pass textColor
                  const SizedBox(height: 12),
                  ...List.generate(4, (index) {
                    return _buildCustomExpansionTile(
                      title: '${index + 1}. How to sell the product on Kisangro?',
                      isExpanded: _buyersExpanded[index],
                      onExpansionChanged: (expanded) {
                        setState(() {
                          _buyersExpanded[index] = expanded;
                        });
                      },
                      answer: sampleAnswer,
                      isDarkMode: isDarkMode, // Pass isDarkMode
                    );
                  }),
                  const SizedBox(height: 100), // Extra space for button
                ],
              ),
            ),

            // Fixed bottom button
            Positioned(
              bottom: 16,
              left: 24,
              right: 24,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xffEB7720), // Always orange
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () {
                  Navigator.push(context,MaterialPageRoute(builder: (context)=>ChatScreen()));// Handle start asking action
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Start Asking',
                      style: GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.w600,color: Colors.white),
                    ),
                    const SizedBox(width: 8),
                    const Row(
                      children: [
                        Icon(Icons.arrow_forward,color: Colors.white,),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color textColor) {
    return Column(
      children: [
        Center(
          child: Text(
            title,
            style: GoogleFonts.lato(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: textColor, // Apply theme color
            ),
          ),
        ),
        const SizedBox(height: 4),
        Center(
          child: Container(
            width: 60,
            height: 2,
            decoration: BoxDecoration(
              color: textColor.withOpacity(0.6), // Apply theme color
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCustomExpansionTile({
    required String title,
    required bool isExpanded,
    required ValueChanged<bool> onExpansionChanged,
    required String answer,
    required bool isDarkMode, // New parameter
  }) {
    final Color textColor = isDarkMode ? Colors.white : Colors.black87;
    final Color expansionTileBgColor = isDarkMode ? Colors.grey[850]! : Colors.white;
    final Color expansionTileShadowColor = isDarkMode ? Colors.transparent : Colors.black.withOpacity(0.03);
    final Color expansionTileIconColor = isDarkMode ? Colors.white70 : Colors.black54;
    final Color dividerColor = isDarkMode ? Colors.grey[700]! : Colors.grey.shade400;


    if (!isExpanded) {
      return ListTile(
        title: Text(
          title,
          style: GoogleFonts.lato(fontSize: 12, fontWeight: FontWeight.w500, color: textColor), // Apply theme color
        ),
        trailing: Icon(
          Icons.keyboard_arrow_down,
          color: expansionTileIconColor, // Apply theme color
        ),
        onTap: () => onExpansionChanged(true),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
        dense: true,
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: expansionTileBgColor, // Apply theme color
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: expansionTileShadowColor, // Apply theme color
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            title: Text(
              title,
              style: GoogleFonts.lato(fontSize: 12, fontWeight: FontWeight.w500, color: textColor), // Apply theme color
            ),
            trailing: Icon(
              Icons.keyboard_arrow_up,
              color: expansionTileIconColor, // Apply theme color
            ),
            onTap: () => onExpansionChanged(false),
            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
            dense: true,
          ),
          Divider(
            color: dividerColor, // Apply theme color
            thickness: 1,
            height: 1,
            indent: 16,
            endIndent: 16,
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              answer,
              style: GoogleFonts.lato(fontSize: 12, color: textColor), // Apply theme color
            ),
          ),
        ],
      ),
    );
  }
}
