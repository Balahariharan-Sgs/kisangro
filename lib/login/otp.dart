import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kisangro/models/kyc_business_model.dart';
import 'package:kisangro/models/kyc_image_provider.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'dart:async';
import 'package:kisangro/login/kyc.dart'; // Update the path if needed
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http; // Import the http package
import 'dart:convert'; // For JSON encoding/decoding
import 'package:shared_preferences/shared_preferences.dart'; // Import for SharedPreferences
import 'package:kisangro/home/bottom.dart'; // Import the Bot widget for home navigation
import 'package:provider/provider.dart'; // Import Provider
import '../home/theme_mode_provider.dart'; // Import ThemeModeProvider


class OtpScreen extends StatefulWidget {
  // Added phoneNumber as a required parameter
  final String phoneNumber;

  const OtpScreen({super.key, required this.phoneNumber});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  TextEditingController otpController = TextEditingController();
  Timer? _timer;
  int _start = 30;
  bool canResend = false;
  bool isOtpFilled = false;
  bool _isVerifying = false; // To show loading state during verification

  // Define your API URL as a constant for easy modification
  static const String _verifyOtpApiUrl = 'https://sgserp.in/erp/api/m_api/';

  @override
  void initState() {
    super.initState();
    startTimer();
  }

  void startTimer() {
    setState(() {
      _start = 30;
      canResend = false;
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_start == 0) {
        setState(() {
          canResend = true;
        });
        timer.cancel();
      } else {
        setState(() {
          _start--;
        });
      }
    });
  }

  Future<void> _verifyOtp() async {
    if (!isOtpFilled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter the complete OTP.',
              style: GoogleFonts.poppins()),
        ),
      );
      return;
    }

    setState(() {
      _isVerifying = true; // Start loading
    });

    try {
      Uri url = Uri.parse(_verifyOtpApiUrl);

      // Construct the body with the verification parameters from the user's request
      Map<String, String> body = {
        'cid': '23262954',
        'type': '1003',
        'ln': '322334',
        'lt': '233432',
        'device_id': '122334',
        'mobile': widget.phoneNumber,
        'otp': otpController.text,
      };

      debugPrint("Sending OTP verification request to $_verifyOtpApiUrl with body: $body");

      final response = await http.post(
        url,
        headers: <String, String>{
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: body,
      ).timeout(const Duration(seconds: 10)); // Add a timeout for network requests

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        debugPrint('OTP Verification API Response: $responseData'); // Debug print

        if (responseData['error'] == false) {
          // OTP verification successful
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('isLoggedIn', true); // Set isLoggedIn to true upon successful OTP verification

          // IMPORTANT: Clear existing KYC data for new user login
       // In otp.dart, inside _verifyOtp() method:
try {
  // Get the providers and clear their data
  WidgetsBinding.instance.addPostFrameCallback((_) {
    try {
      final kycBusinessDataProvider = Provider.of<KycBusinessDataProvider>(context, listen: false);
      final kycImageProvider = Provider.of<KycImageProvider>(context, listen: false);
      
      // Clear existing data - NOTE: Use clearKycData() not clearKycBusinessData()
      kycBusinessDataProvider.clearKycData(); // Changed this
      kycImageProvider.clearKycImage();
      
      debugPrint('Cleared existing KYC data for new user login');
    } catch (e) {
      debugPrint('Error clearing KYC data: $e. This is normal if providers are not initialized yet.');
    }
  });
} catch (e) {
  debugPrint('Error in clearing KYC data flow: $e');
}
          // Extract user_data
          final userData = responseData['user_data'];
          if (userData != null && userData is Map<String, dynamic>) {
            final int? cusId = userData['cus_id'] as int?;

            if (cusId != null) {
              await prefs.setInt('cus_id', cusId); // Store cus_id
              debugPrint('Stored cus_id: $cusId');
            }

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(responseData['error_msg'] ?? 'OTP verified successfully!',
                    style: GoogleFonts.poppins()),
              ),
            );

            // MODIFIED: Always navigate to KYC screen after successful OTP verification
            debugPrint('OTP verified successfully. Navigating to KYC screen.');
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => kyc()),
            );
          } else {
            debugPrint('User data not found or invalid in API response. Navigating to KYC screen.');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('User data missing. Proceeding to KYC.',
                    style: GoogleFonts.poppins()),
              ),
            );
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => kyc()),
            );
          }
        } else {
          // OTP verification failed
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(responseData['error_msg'] ?? 'Invalid OTP. Please try again.',
                  style: GoogleFonts.poppins()),
            ),
          );

          // Clear the OTP field for retry
          otpController.clear();
          setState(() {
            isOtpFilled = false;
          });
        }
      } else {
        // Handle non-200 status codes
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to verify OTP. Status Code: ${response.statusCode}',
                style: GoogleFonts.poppins()),
          ),
        );
      }
    } catch (e) {
      // Handle network errors
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Network Error: $e. Please check your internet connection.',
              style: GoogleFonts.poppins()),
        ),
      );
      debugPrint('Network/API Error: $e'); // Print error for debugging
    } finally {
      setState(() {
        _isVerifying = false; // End loading
      });
    }
  }

  Future<void> _resendOtp() async {
    // Reuse the same logic from login screen to resend OTP
    try {
      Uri url = Uri.parse(_verifyOtpApiUrl);

      Map<String, String> body = {
        'cid': '23262954',
        'type': '1002', // Login/Resend OTP type
        'ln': '322334',
        'lt': '233432',
        'device_id': '122334',
        'mobile': widget.phoneNumber,
      };

      debugPrint("Resending OTP to ${widget.phoneNumber}");

      final response = await http.post(
        url,
        headers: <String, String>{
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: body,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (responseData['error'] == false) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('OTP resent successfully!',
                  style: GoogleFonts.poppins()),
            ),
          );
          startTimer(); // Restart the timer
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(responseData['error_msg'] ?? 'Failed to resend OTP.',
                  style: GoogleFonts.poppins()),
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to resend OTP. Please try again.',
              style: GoogleFonts.poppins()),
        ),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = Provider.of<ThemeModeProvider>(context).themeMode;
    final isDarkMode = themeMode == ThemeMode.dark;

    // Define colors based on theme
    final Color gradientStartColor = isDarkMode ? Colors.black : const Color(0xffFFD9BD);
    final Color gradientEndColor = isDarkMode ? Colors.black : const Color(0xffFFFFFF);
    final Color backButtonColor = isDarkMode ? Colors.white : Colors.black87;
    final Color textColor = isDarkMode ? Colors.white : Colors.black;
    final Color otpFieldActiveColor = isDarkMode ? Colors.white : const Color(0xffEB7720); // Orange for light, white for dark
    final Color otpFieldInactiveColor = isDarkMode ? Colors.grey[600]! : Colors.grey;
    final Color timerTextColor = isDarkMode ? Colors.grey[400]! : Colors.grey;
    final Color orangeColor = const Color(0xffEB7720); // Orange color, remains constant
    // Removed logoColor as it's no longer needed for tinting


    return Scaffold(
      resizeToAvoidBottomInset: true, // Enable keyboard resize behavior
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [gradientStartColor, gradientEndColor], // Apply theme colors
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Back button section
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: Icon(Icons.arrow_back, color: backButtonColor), // Apply theme color
                  ),
                ),
              ),

              // Scrollable content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20), // Reduced spacing
                      Center(
                        child: Image.asset(
                          'assets/logo.png',
                          height: 80, // Reduced from 100
                          // Removed color property
                        ),
                      ),
                      const SizedBox(height: 40), // Reduced from 100
                      Center(
                        child: Text(
                          'OTP Verification',
                          style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: orangeColor), // Always orange
                        ),
                      ),
                      const SizedBox(height: 30), // Reduced from 50
                      Center(
                        child: RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: GoogleFonts.poppins(fontSize: 14, color: textColor), // Apply theme color
                            children: [
                              TextSpan(
                                text:
                                'We sent an OTP (One Time Password) to your mobile number ',
                                style: TextStyle(color: textColor), // Apply theme color
                              ),
                              // Use widget.phoneNumber to display the number passed from LoginScreen
                              TextSpan(
                                text: widget.phoneNumber,
                                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: textColor), // Apply theme color
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // PinCodeTextField without autofillHints for compatibility
                      PinCodeTextField(
                        appContext: context,
                        length: 6,
                        controller: otpController,
                        onChanged: (value) {
                          setState(() {
                            isOtpFilled = value.length == 6;
                          });
                        },
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        pinTheme: PinTheme(
                          shape: PinCodeFieldShape.underline,
                          fieldWidth: 30,
                          activeColor: otpFieldActiveColor, // Apply theme color
                          selectedColor: otpFieldActiveColor, // Apply theme color
                          inactiveColor: otpFieldInactiveColor, // Apply theme color
                          // Removed textStyle from PinTheme to fix the error
                        ),
                        textStyle: GoogleFonts.poppins(color: textColor), // Apply textStyle directly to PinCodeTextField
                        // autofillHints: const [AutofillHints.oneTimeCode], // This line is removed
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Didn't receive OTP?", style: GoogleFonts.poppins(fontSize: 13, color: textColor)), // Apply theme color
                          canResend
                              ? GestureDetector(
                            onTap: _resendOtp, // Call the resend OTP function
                            child: Text(
                              'Resend now',
                              style: GoogleFonts.poppins(
                                  color: orangeColor, // Always orange
                                  fontWeight: FontWeight.bold),
                            ),
                          )
                              : Text(
                            '0:${_start.toString().padLeft(2, '0')}',
                            style: GoogleFonts.poppins(color: timerTextColor), // Apply theme color
                          ),
                        ],
                      ),
                      // Add extra space to accommodate keyboard
                      SizedBox(height: MediaQuery.of(context).viewInsets.bottom > 0 ? 40 : 20),
                    ],
                  ),
                ),
              ),

              // Bottom button section
              Container(
                padding: EdgeInsets.only(
                  left: 24.0,
                  right: 24.0,
                  top: 16.0,
                  bottom: MediaQuery.of(context).viewInsets.bottom > 0 ? 16.0 : 30.0, // Adaptive bottom padding
                ),
                child: ElevatedButton(
                  onPressed: (isOtpFilled && !_isVerifying) ? _verifyOtp : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: orangeColor, // Always orange
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isVerifying
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                    'Verify & Proceed',
                    style: GoogleFonts.poppins(color: Colors.white),
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