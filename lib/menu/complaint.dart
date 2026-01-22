import 'package:flutter/material.dart';
import 'package:kisangro/menu/logout.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart'; // Import Provider
import '../home/theme_mode_provider.dart'; // Import ThemeModeProvider


void main() {
  runApp(const MaterialApp(
    home: RaiseComplaintScreen(),
    debugShowCheckedModeBanner: false,
  ));
}

class RaiseComplaintScreen extends StatefulWidget {
  const RaiseComplaintScreen({Key? key}) : super(key: key);

  @override
  State<RaiseComplaintScreen> createState() => _RaiseComplaintScreenState();
}

class _RaiseComplaintScreenState extends State<RaiseComplaintScreen> {
  String? selectedReason = 'Wrong Product Delivered';
  final TextEditingController otherController = TextEditingController();

  final List<String> complaintOptions = [
    'Wrong Product Delivered',
    'Damaged Or Expired Items',
    'Late Delivery',
    'Quantity Mismatch',
    'Payment Not Updated Or Failed',
    'Invoice Issues (Missing Or Incorrect)',
    'Refund Not Received',
    'Poor Quality Product',
    'No Response From Customer Support',
    'Others',
  ];

  void alertbox(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => LogoutConfirmationDialog(
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
    final themeMode = Provider.of<ThemeModeProvider>(context).themeMode;
    final isDarkMode = themeMode == ThemeMode.dark;

    // Define colors based on theme
    final Color gradientStartColor = isDarkMode ? Colors.black : const Color(0xffFFD9BD);
    final Color gradientEndColor = isDarkMode ? Colors.black : const Color(0xffFFFFFF);
    final Color appBarIconColor = isDarkMode ? Colors.white : Colors.black;
    final Color appBarTextColor = isDarkMode ? Colors.white : Colors.black;
    final Color radioUnselectedColor = isDarkMode ? Colors.white70 : Colors.black;
    final Color radioActiveColor = isDarkMode ? Colors.white : Colors.black;
    final Color radioTextColor = isDarkMode ? Colors.white : Colors.black;
    final Color dividerColor = isDarkMode ? Colors.grey[700]! : Colors.black;
    final Color textFieldBgColor = isDarkMode ? Colors.grey[800]! : Colors.white;
    final Color textFieldHintColor = isDarkMode ? Colors.grey[400]! : Colors.grey;
    final Color textFieldBorderColor = isDarkMode ? Colors.grey[600]! : Colors.black;
    final Color dialogBgColor = isDarkMode ? Colors.grey[850]! : Colors.white;
    final Color dialogTextColor = isDarkMode ? Colors.white : Colors.black;
    final Color orangeColor = const Color(0xffEB7720); // Orange color, remains constant


    return Scaffold(
      backgroundColor: Colors.transparent, // Important
      body: Container(
        height: double.infinity,
        width: double.infinity,
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
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // App Bar
                Row(
                  children: [
                    IconButton(onPressed: (){
                      Navigator.pop(context);
                    }, icon:Icon(Icons.arrow_back, color: appBarIconColor)), // Apply theme color
                    const SizedBox(width: 10),
                    Text(
                      'Raise Complaint',
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: appBarTextColor, // Apply theme color
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Complaint Options
                Expanded(
                  child: ListView.builder(
                    itemCount: complaintOptions.length,
                    itemBuilder: (context, index) {
                      final option = complaintOptions[index];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Theme(
                            data: Theme.of(context).copyWith(
                              unselectedWidgetColor: radioUnselectedColor, // Apply theme color
                            ),
                            child: RadioListTile<String>(
                              activeColor: radioActiveColor, // Apply theme color
                              value: option,
                              groupValue: selectedReason,
                              onChanged: (value) {
                                setState(() {
                                  selectedReason = value!;
                                });
                              },
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                option,
                                style:  GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: radioTextColor, // Apply theme color
                                ),
                              ),
                            ),
                          ),
                          if (!(option == 'Others' &&
                              selectedReason == 'Others'))
                            Divider(
                              thickness: 1,
                              height: 1,
                              color: dividerColor, // Apply theme color
                            ),
                          if (option == 'Others' &&
                              selectedReason == 'Others')
                            Padding(
                              padding: const EdgeInsets.only(top: 10, bottom: 20),
                              child: TextField(
                                controller: otherController,
                                maxLines: 4,
                                decoration: InputDecoration(
                                  hintText: 'Type Here...',
                                  hintStyle:  GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold,
                                      color: textFieldHintColor), // Apply theme color
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(4),
                                    borderSide:
                                    BorderSide(color: textFieldBorderColor), // Apply theme color
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(4),
                                    borderSide:
                                    BorderSide(color: textFieldBorderColor), // Apply theme color
                                  ),
                                  contentPadding: const EdgeInsets.all(12),
                                  fillColor: textFieldBgColor, // Apply theme color
                                  filled: true,
                                ),
                                style:  GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                    color: radioTextColor), // Apply theme color
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),

                // Submit Button
                Align(
                  alignment: Alignment.center,
                  child: SizedBox(
                    width: 180,
                    child: ElevatedButton(
                      onPressed: () {
                        final complaint = selectedReason == 'Others'
                            ? otherController.text.trim()
                            : selectedReason;

                        if (complaint == null || complaint.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please enter a complaint.')),
                          );
                          return;
                        }

                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: dialogBgColor, // Apply theme color
                            title:Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                GestureDetector(
                                  onTap: () => Navigator.pop(context), // Close dialog
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
                                      color:orangeColor, // Always orange
                                    ),
                                  ),
                                ),
                              ],),


                            actions: [
                              Center(child: Image(image: AssetImage("assets/complaint.gif"))),
                              Center(child: Text("Complaint raised successfully.",style: GoogleFonts.poppins(fontSize:13, color: dialogTextColor ),)), // Apply theme color
                              SizedBox(height: 10,),
                              Text("Soon our support team will resole it shortly ",style: GoogleFonts.poppins(fontSize: 13, color: dialogTextColor),) // Apply theme color

                            ],
                          ),
                        );
                      },

                      style: ElevatedButton.styleFrom(
                        backgroundColor: orangeColor, // Always orange
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child:  Text(
                        'Submit',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
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
