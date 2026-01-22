import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:kisangro/login/fourthscreen.dart';
import 'package:kisangro/login/login.dart';
import 'package:kisangro/login/thirdscreen.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart'; // Import Provider
import '../home/theme_mode_provider.dart'; // Import ThemeModeProvider


class secondscreen extends StatefulWidget {
  const secondscreen({super.key});

  @override
  State<secondscreen> createState() => _secondscreenState();
}

class _secondscreenState extends State<secondscreen> {
  PageController _controller = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var screenWidth = MediaQuery.of(context).size.width;
    var screenHeight = MediaQuery.of(context).size.height;
    final isTablet = screenWidth > 600;
    final themeMode = Provider.of<ThemeModeProvider>(context).themeMode;
    final isDarkMode = themeMode == ThemeMode.dark;

    // Define colors based on theme
    final Color gradientStartColor = isDarkMode ? Colors.black : const Color(0xffFFD9BD);
    final Color gradientEndColor = isDarkMode ? Colors.black : const Color(0xffFFFFFF);
    final Color skipButtonBgColor = isDarkMode ? Colors.white24 : Colors.black45;
    final Color skipButtonTextColor = Colors.white;
    final Color welcomeTextColor = isDarkMode ? Colors.white : Colors.black;
    // Removed svgColor as it's no longer needed for tinting
    final Color dotColor = isDarkMode ? Colors.white.withOpacity(0.3) : const Color(0xffEB7720).withOpacity(0.3);
    final Color activeDotColor = isDarkMode ? Colors.white : const Color(0xffEB7720);


    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: _controller,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            children: [
              buildPage1(screenWidth, screenHeight, isTablet, isDarkMode), // Pass isDarkMode
              thirdscreen(),
              fourthscreen(),
            ],
          ),
          Positioned(
            bottom: isTablet ? 30 : 20,
            left: 0,
            right: 0,
            child: Center(
              child: SmoothPageIndicator(
                controller: _controller,
                count: 3,
                effect: ExpandingDotsEffect(
                  dotColor: dotColor, // Apply theme color
                  activeDotColor: activeDotColor, // Apply theme color
                  dotHeight: isTablet ? 6.0 : 5.0,
                  dotWidth: isTablet ? 10.0 : 8.0,
                  spacing: 6.0,
                ),
                onDotClicked: (index) {
                  _controller.animateToPage(
                    index,
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildPage1(double screenWidth, double screenHeight, bool isTablet, bool isDarkMode) {
    final Color gradientStartColor = isDarkMode ? Colors.black : const Color(0xffFFD9BD);
    final Color gradientEndColor = isDarkMode ? Colors.black : const Color(0xffFFFFFF);
    final Color skipButtonBgColor = isDarkMode ? Colors.white24 : Colors.black45;
    final Color skipButtonTextColor = Colors.white;
    final Color welcomeTextColor = isDarkMode ? Colors.white : Colors.black;
    // Removed svgColor as it's no longer needed for tinting


    return Container(
      width: screenWidth,
      height: screenHeight,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [gradientStartColor, gradientEndColor], // Apply theme colors
        ),
      ),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.07),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginApp()));
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        margin: EdgeInsets.only(top: screenHeight * 0.01),
                        decoration: BoxDecoration(
                          color: skipButtonBgColor, // Apply theme color
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text("Skip", style: TextStyle(color: skipButtonTextColor)), // Apply theme color
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.05),
                  Center(
                    child: Text(
                      "Welcome To KISANGRO",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: isTablet ? 32 : 24,
                        fontWeight: FontWeight.bold,
                        color: welcomeTextColor, // Apply theme color
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.035),
                  Center(
                    child: SvgPicture.asset(
                      'assets/Welcome1.svg',
                      height: screenHeight * 0.18,
                      fit: BoxFit.contain,
                      // Removed colorFilter property
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.04),
                  Center(
                    child: Text(
                      "Your “One-Stop Shop”",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(fontSize: isTablet ? 20 : 16, color: welcomeTextColor), // Apply theme color
                    ),
                  ),
                  Center(
                    child: Text(
                      "For All Agricultural Needs!",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(fontSize: isTablet ? 20 : 16, color: welcomeTextColor), // Apply theme color
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.045),
                  Center(
                    child: SvgPicture.asset(
                      'assets/welcome2.svg',
                      height: screenHeight * 0.23,
                      fit: BoxFit.contain,
                      // Removed colorFilter property
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.045),
                  Center(
                    child: Column(
                      children: [
                        RichText(
                          text: TextSpan(
                            style: GoogleFonts.poppins(
                              fontSize: isTablet ? 18 : 14,
                              color: welcomeTextColor, // Apply theme color
                            ),
                            children: [
                              TextSpan(
                                text: "Agri-Products ",
                                style: TextStyle(fontWeight: FontWeight.bold, color: welcomeTextColor), // Apply theme color
                              ),
                              TextSpan(text: "Delivered", style: TextStyle(color: welcomeTextColor)), // Apply theme color
                            ],
                          ),
                        ),
                        RichText(
                          text: TextSpan(
                            style: GoogleFonts.poppins(
                              fontSize: isTablet ? 18 : 14,
                              color: welcomeTextColor, // Apply theme color
                            ),
                            children: [
                              TextSpan(text: "To Your ", style: TextStyle(color: welcomeTextColor)), // Apply theme color
                              TextSpan(
                                text: "Door Step",
                                style: TextStyle(fontWeight: FontWeight.bold, color: welcomeTextColor), // Apply theme color
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
