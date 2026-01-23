import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kisangro/models/kyc_business_model.dart';
import 'package:kisangro/models/kyc_image_provider.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'dart:async';
import 'package:kisangro/login/kyc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kisangro/home/bottom.dart';
import 'package:provider/provider.dart';
import '../home/theme_mode_provider.dart';
import 'package:sms_autofill/sms_autofill.dart'; // Added for OTP autofill

class OtpScreen extends StatefulWidget {
  final String phoneNumber;

  const OtpScreen({super.key, required this.phoneNumber});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> with CodeAutoFill {
  TextEditingController otpController = TextEditingController();
  Timer? _timer;
  int _start = 30;
  bool canResend = false;
  bool isOtpFilled = false;
  bool _isVerifying = false;
  String _appSignature = '';
  String? _otpCode;

  static const String _verifyOtpApiUrl = 'https://erpsmart.in/total/api/m_api/';

  @override
  void codeUpdated() {
    setState(() {
      if (code != null && code!.length == 6) {
        otpController.text = code!;
        isOtpFilled = true;
      }
    });
  }

  @override
  void initState() {
    super.initState();
    startTimer();
    _initAutoFill();
    _loadAppSignature();
  }

  Future<void> _initAutoFill() async {
    await SmsAutoFill().listenForCode();
  }

  Future<void> _loadAppSignature() async {
    final signature = await _getLiveAppSignature();
    setState(() {
      _appSignature = signature;
    });
    debugPrint("OTP SCREEN LIVE APP SIGNATURE: $_appSignature");
  }

  Future<String> _getLiveAppSignature() async {
    try {
      final signature = await SmsAutoFill().getAppSignature;
      return signature ?? '';
    } catch (e) {
      debugPrint('App signature error: $e');
      return '';
    }
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
      _isVerifying = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get values from SharedPreferences (same as login screen)
      double? latitude = prefs.getDouble('latitude');
      double? longitude = prefs.getDouble('longitude');
      String? deviceId = prefs.getString('device_id');

      Uri url = Uri.parse(_verifyOtpApiUrl);

      // Construct the body with values from SharedPreferences
      Map<String, String> body = {
        'cid': '85788578',
        'type': '1004', // OTP verification type
        'ln': longitude?.toString() ?? '',
        'lt': latitude?.toString() ?? '',
        'device_id': deviceId ?? '',
        'mobile': widget.phoneNumber,
        'otp': otpController.text,
      };

      debugPrint("OTP Verification API BODY: $body");

      final response = await http.post(
        url,
        headers: <String, String>{
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: body,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        debugPrint('OTP Verification API Response: $responseData');

        if (responseData['error'] == false) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('isLoggedIn', true);

          // Clear existing KYC data for new user login
          try {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              try {
                final kycBusinessDataProvider = Provider.of<KycBusinessDataProvider>(context, listen: false);
                final kycImageProvider = Provider.of<KycImageProvider>(context, listen: false);
                
                kycBusinessDataProvider.clearKycData();
                kycImageProvider.clearKycImage();
                
                debugPrint('Cleared existing KYC data for new user login');
              } catch (e) {
                debugPrint('Error clearing KYC data: $e. This is normal if providers are not initialized yet.');
              }
            });
          } catch (e) {
            debugPrint('Error in clearing KYC data flow: $e');
          }

          final userData = responseData['user_data'];
          if (userData != null && userData is Map<String, dynamic>) {
            final int? cusId = userData['cus_id'] as int?;

            if (cusId != null) {
              await prefs.setInt('cus_id', cusId);
              debugPrint('Stored cus_id: $cusId');
            }

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(responseData['error_msg'] ?? 'OTP verified successfully!',
                    style: GoogleFonts.poppins()),
              ),
            );

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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(responseData['error_msg'] ?? 'Invalid OTP. Please try again.',
                  style: GoogleFonts.poppins()),
            ),
          );

          otpController.clear();
          setState(() {
            isOtpFilled = false;
          });
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to verify OTP. Status Code: ${response.statusCode}',
                style: GoogleFonts.poppins()),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Network Error: $e. Please check your internet connection.',
              style: GoogleFonts.poppins()),
        ),
      );
      debugPrint('Network/API Error: $e');
    } finally {
      setState(() {
        _isVerifying = false;
      });
    }
  }

  Future<void> _resendOtp() async {
    if (!canResend) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get values from SharedPreferences (same as login screen)
      double? latitude = prefs.getDouble('latitude');
      double? longitude = prefs.getDouble('longitude');
      String? deviceId = prefs.getString('device_id');

      Uri url = Uri.parse(_verifyOtpApiUrl);

      // Use type 1002 with app signature (same as login screen)
      Map<String, String> body = {
        'cid': '85788578',
        'type': '1002', // Login/Resend OTP type (same as login screen)
        'lt': latitude?.toString() ?? '',
        'ln': longitude?.toString() ?? '',
        'device_id': deviceId ?? '',
        'mobile': widget.phoneNumber,
        'app_signature': _appSignature, // Use app signature from loaded value
      };

      debugPrint("RESEND OTP API BODY: $body");

      final response = await http.post(
        url,
        headers: <String, String>{
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: body,
      ).timeout(const Duration(seconds: 10));

      debugPrint("RESEND OTP STATUS: ${response.statusCode}");
      debugPrint("RESEND OTP RESPONSE: ${response.body}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        if (data.containsKey('cus_id')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                data['error_msg'] ?? 'OTP resent successfully!',
                style: GoogleFonts.poppins(),
              ),
            ),
          );
          startTimer();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to resend OTP. Please try again.',
                style: GoogleFonts.poppins(),
              ),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Server error. Please try again.',
                style: GoogleFonts.poppins()),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Network error: $e',
              style: GoogleFonts.poppins()),
        ),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    otpController.dispose();
    SmsAutoFill().unregisterListener();
    cancel();
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
    final Color otpFieldActiveColor = isDarkMode ? Colors.white : const Color(0xffEB7720);
    final Color otpFieldInactiveColor = isDarkMode ? Colors.grey[600]! : Colors.grey;
    final Color timerTextColor = isDarkMode ? Colors.grey[400]! : Colors.grey;
    final Color orangeColor = const Color(0xffEB7720);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [gradientStartColor, gradientEndColor],
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
                    icon: Icon(Icons.arrow_back, color: backButtonColor),
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
                      const SizedBox(height: 20),
                      Center(
                        child: Image.asset(
                          'assets/logo.png',
                          height: 80,
                        ),
                      ),
                      const SizedBox(height: 40),
                      Center(
                        child: Text(
                          'OTP Verification',
                          style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: orangeColor),
                        ),
                      ),
                      const SizedBox(height: 30),
                      Center(
                        child: RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: GoogleFonts.poppins(fontSize: 14, color: textColor),
                            children: [
                              TextSpan(
                                text:
                                'We sent an OTP (One Time Password) to your mobile number ',
                                style: TextStyle(color: textColor),
                              ),
                              TextSpan(
                                text: widget.phoneNumber,
                                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: textColor),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
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
                          activeColor: otpFieldActiveColor,
                          selectedColor: otpFieldActiveColor,
                          inactiveColor: otpFieldInactiveColor,
                        ),
                        textStyle: GoogleFonts.poppins(color: textColor),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Didn't receive OTP?", style: GoogleFonts.poppins(fontSize: 13, color: textColor)),
                          canResend
                              ? GestureDetector(
                            onTap: _resendOtp,
                            child: Text(
                              'Resend now',
                              style: GoogleFonts.poppins(
                                  color: orangeColor,
                                  fontWeight: FontWeight.bold),
                            ),
                          )
                              : Text(
                            '0:${_start.toString().padLeft(2, '0')}',
                            style: GoogleFonts.poppins(color: timerTextColor),
                          ),
                        ],
                      ),
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
                  bottom: MediaQuery.of(context).viewInsets.bottom > 0 ? 16.0 : 30.0,
                ),
                child: ElevatedButton(
                  onPressed: (isOtpFilled && !_isVerifying) ? _verifyOtp : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: orangeColor,
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