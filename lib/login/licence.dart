import 'package:flutter/material.dart';
import 'package:kisangro/login/licence4.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../home/theme_mode_provider.dart';

class licence1 extends StatefulWidget {
  @override
  _licence1State createState() => _licence1State();
}

class _licence1State extends State<licence1> {
  bool isPesticideSelected = false;
  bool isFertilizerSelected = false;

  @override
  Widget build(BuildContext context) {
    final themeMode = Provider.of<ThemeModeProvider>(context).themeMode;
    final isDarkMode = themeMode == ThemeMode.dark;

    // Define colors based on theme
    final Color backgroundColor = isDarkMode ? Colors.black : const Color(0xffFFD9BD);
    final Color appBarColor = const Color(0xffEB7720);
    final Color appBarIconColor = Colors.white;
    
    final Color appBarTextColor = Colors.white;
    final Color textColor = isDarkMode ? Colors.white : Colors.black87;
    final Color orangeColor = const Color(0xffEB7720);
    final Color categoryButtonColor = isDarkMode ? Colors.grey[800]! : Colors.white;
    final Color categoryBorderColor = const Color(0xffEB7720);
    final Color selectedCategoryColor = const Color(0xffEB7720);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        // leading: IconButton(
        //   icon: Icon(Icons.arrow_back, color: appBarIconColor),
        //   onPressed: () {
        //     Navigator.pop(context);
        //   },
        // ),
        backgroundColor: appBarColor,
        title: Transform.translate(
          offset: const Offset(-25, 0),
          child: Text(
            "          Upload License",
            style: GoogleFonts.poppins(
              color: appBarTextColor,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        elevation: 0,
      ),
      body: Container(
        height: double.infinity,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              isDarkMode ? Colors.black : const Color(0xffFFD9BD),
              isDarkMode ? Colors.black : const Color(0xffFFFFFF),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Step indicator
              Text(
                'Step 1/2',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: orangeColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),

              // Main heading
              Text(
                'Select Category You Are Selling',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  color: orangeColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 30),

              // Category selection buttons
              Row(
                children: [
                  // Pesticide button
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          isPesticideSelected = !isPesticideSelected;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                        decoration: BoxDecoration(
                          color: isPesticideSelected ? selectedCategoryColor : categoryButtonColor,
                          border: Border.all(
                            color: categoryBorderColor,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Center(
                          child: Text(
                            'Pesticide',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: isPesticideSelected ? Colors.white : orangeColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Fertilizer button
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          isFertilizerSelected = !isFertilizerSelected;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                        decoration: BoxDecoration(
                          color: isFertilizerSelected ? selectedCategoryColor : categoryButtonColor,
                          border: Border.all(
                            color: categoryBorderColor,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Center(
                          child: Text(
                            'Fertilizers',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: isFertilizerSelected ? Colors.white : orangeColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const Spacer(),

              // Note text
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  'Note: A verification team will visit your address within 48 hrs for business verification.',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: textColor.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              // Proceed Button
              ElevatedButton(
                onPressed: (isPesticideSelected || isFertilizerSelected)
                    ? () {
                  String? typeToDisplay;
                  if (isPesticideSelected && isFertilizerSelected) {
                    typeToDisplay = 'all';
                  } else if (isPesticideSelected) {
                    typeToDisplay = 'pesticide';
                  } else if (isFertilizerSelected) {
                    typeToDisplay = 'fertilizer';
                  }

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => licence4(licenseTypeToDisplay: typeToDisplay),
                    ),
                  );
                }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: orangeColor,
                  disabledBackgroundColor: orangeColor.withOpacity(0.5),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  'Proceed',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}