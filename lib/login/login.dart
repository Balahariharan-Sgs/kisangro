import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../home/theme_mode_provider.dart';
import 'package:kisangro/login/otp.dart';
import 'package:kisangro/login/registration.dart';

class LoginApp extends StatefulWidget {
  const LoginApp({super.key});

  @override
  State<LoginApp> createState() => _LoginAppState();
}

class _LoginAppState extends State<LoginApp> {
  @override
  Widget build(BuildContext context) {
    return const LoginRegisterScreen();
  }
}

class LoginRegisterScreen extends StatefulWidget {
  const LoginRegisterScreen({super.key});

  @override
  _LoginRegisterScreenState createState() => _LoginRegisterScreenState();
}

class _LoginRegisterScreenState extends State<LoginRegisterScreen> {
  bool isChecked = false;
  String _enteredPhoneNumber = '';
  bool isValidNumber = false;
  bool _isLoading = false;

  static const String _loginApiUrl = 'https://sgserp.in/erp/api/m_api/';
  static const String _checkRegistrationApiUrl = 'https://sgserp.in/erp/api/m_api/';

  // Check if user is registered before sending OTP - only check for cus_id
  Future<bool> _checkUserRegistration(String mobile) async {
    try {
      Uri url = Uri.parse(_checkRegistrationApiUrl);

      Map<String, String> body = {
        'cid': '23262954',
        'type': '1002', // Using login type to check registration
        'lt': '23233443',
        'ln': '43432323',
        'device_id': '3453434',
        'mobile': mobile,
      };

      debugPrint("Check Registration API URL: $url");
      debugPrint("Check Registration Request Body: $body");

      final response = await http.post(
        url,
        headers: <String, String>{
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: body,
      ).timeout(const Duration(seconds: 10));

      debugPrint('Check Registration Response Status Code: ${response.statusCode}');
      debugPrint('Check Registration Raw Response Body: ${response.body}');

      if (response.statusCode == 200) {
        String? contentType = response.headers['content-type'];
        if (contentType != null && contentType.contains('application/json')) {
          try {
            final Map<String, dynamic> responseData = jsonDecode(response.body);
            debugPrint('Parsed Check Registration API Response: $responseData');

            // Only check if cus_id exists in the response
            // If cus_id exists, user is registered
            return responseData.containsKey('cus_id');
          } on FormatException catch (e) {
            
            debugPrint('FormatException: $e. Raw response: ${response.body}');
            return false;
          }
        } else {
          debugPrint('Non-JSON response. Content-Type: $contentType, Raw response: ${response.body}');
          return false;
        }
      } else {
        debugPrint('Failed to connect to the server. Status Code: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('Network/API Error: $e');
      return false;
    }
  }

  Future<void> _sendOtp() async {
    if (!isChecked || !isValidNumber) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Please accept terms and enter a valid 10-digit mobile number.',
                style: GoogleFonts.poppins())),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // First check if the user is registered by checking for cus_id
      bool isRegistered = await _checkUserRegistration(_enteredPhoneNumber);

      if (!isRegistered) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please register before logging in.', style: GoogleFonts.poppins()),
            backgroundColor: const Color(0xffEB7720),
          ),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // If registered (cus_id exists), proceed with OTP sending
      Uri url = Uri.parse(_loginApiUrl);

      Map<String, String> body = {
        'cid': '23262954',
        'type': '1002',
        'lt': '23233443',
        'ln': '43432323',
        'device_id': '3453434',
        'mobile': _enteredPhoneNumber,
      };

      debugPrint("Login API URL: $url");
      debugPrint("Login Request Body: $body");

      final response = await http.post(
        url,
        headers: <String, String>{
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: body,
      ).timeout(const Duration(seconds: 10));

      debugPrint('Login Response Status Code: ${response.statusCode}');
      debugPrint('Raw Login Response Body: ${response.body}');

      if (response.statusCode == 200) {
        String? contentType = response.headers['content-type'];
        if (contentType != null && contentType.contains('application/json')) {
          try {
            final Map<String, dynamic> responseData = jsonDecode(response.body);
            debugPrint('Parsed Login API Response: $responseData');

            if (responseData['error'] == false) {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('isLoggedIn', false);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(responseData['error_msg'] ?? 'OTP sent successfully!',
                        style: GoogleFonts.poppins())),
              );
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => OtpScreen(phoneNumber: _enteredPhoneNumber),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(responseData['error_msg'] ?? 'Login failed. Please try again.',
                        style: GoogleFonts.poppins())),
              );
            }
          } on FormatException catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text('Server returned an unexpected response format. Please try again. Error: $e',
                      style: GoogleFonts.poppins())),
            );
            debugPrint('FormatException: $e. Raw response: ${response.body}');
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Server returned an unexpected response (not JSON). Please try again.',
                    style: GoogleFonts.poppins())),
          );
          debugPrint('Non-JSON response. Content-Type: $contentType, Raw response: ${response.body}');
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to connect to the server. Status Code: ${response.statusCode}',
                  style: GoogleFonts.poppins())),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Network Error: $e. Please check your internet connection.',
                style: GoogleFonts.poppins())),
      );
      debugPrint('Network/API Error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _navigateToRegistration() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RegistrationScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = Provider.of<ThemeModeProvider>(context).themeMode;
    final isDarkMode = themeMode == ThemeMode.dark;

    // Define colors based on theme
    final Color gradientStartColor = isDarkMode ? Colors.black : const Color(0xffFFD9BD);
    final Color gradientEndColor = isDarkMode ? Colors.black : const Color(0xffFFFFFF);
    final Color textColor = isDarkMode ? Colors.white : Colors.black;
    final Color hintColor = isDarkMode ? Colors.grey[400]! : Colors.black;
    final Color inputBorderColor = isDarkMode ? Colors.white : const Color(0xffEB7720); // Orange for light, white for dark
    final Color checkboxActiveColor = isDarkMode ? Colors.white : const Color(0xffEB7720); // Orange for light, white for dark
    final Color checkboxUncheckedColor = isDarkMode ? Colors.grey[400]! : Colors.black;
    final Color orangeColor = const Color(0xffEB7720); // Orange color, remains constant

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please complete the login process to proceed.', style: GoogleFonts.poppins())),
        );
      },
      child: Scaffold(
        backgroundColor: Colors.transparent, // Set to transparent to show gradient
        resizeToAvoidBottomInset: true,
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
          child: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 20),
                        Center(
                          child: Image.asset("assets/logo.png", height: 80), // Removed color property
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Login/Register',
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: orangeColor, // Always orange
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'OTP (One Time Password) will be sent to this number',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(fontSize: 13, color: textColor), // Apply theme color
                        ),
                        const SizedBox(height: 20),

                        IntlPhoneField(
                          decoration: InputDecoration(
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: inputBorderColor, // Apply theme color
                                width: 2.0,
                              ),
                              borderRadius: const BorderRadius.all(Radius.circular(8)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: inputBorderColor, // Apply theme color
                                width: 2.0,
                              ),
                              borderRadius: const BorderRadius.all(Radius.circular(8)),
                            ),
                            labelText: 'Enter mobile number',
                            labelStyle: GoogleFonts.poppins(color: hintColor), // Apply theme color
                            border: const OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(8)),
                            ),
                          ),
                          initialCountryCode: 'IN',
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          style: GoogleFonts.poppins(color: textColor), // Apply theme color to input text
                          onChanged: (phone) {
                            setState(() {
                              _enteredPhoneNumber = phone.number;
                              isValidNumber = phone.number.length == 10;
                            });
                          },
                        ),

                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center, // Added this line
                          children: [
                            Text( // Removed Expanded
                              "Don't worry your details are safe with us.",
                              style: GoogleFonts.poppins(fontSize: 13, color: textColor), // Apply theme color
                            ),
                            const SizedBox(width: 5),
                            Icon(Icons.verified, color: orangeColor), // Always orange
                          ],
                        ),
                        const SizedBox(height: 20),

                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Checkbox(
                              value: isChecked,
                              activeColor: checkboxActiveColor, // Apply theme color
                              checkColor: isDarkMode ? Colors.black : Colors.white, // Checkmark color
                              side: BorderSide(color: checkboxUncheckedColor), // Apply theme color
                              onChanged: (value) {
                                setState(() {
                                  isChecked = value!;
                                });
                              },
                            ),
                            Expanded(
                              child: Text.rich(
                                TextSpan(
                                  text: 'I accept the ',
                                  style: GoogleFonts.poppins(
                                    color: textColor, // Apply theme color
                                    fontSize: 13,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: 'Terms & Conditions',
                                      style: GoogleFonts.poppins(
                                        color: orangeColor, // Always orange
                                        fontWeight: FontWeight.w500,
                                      ),
                                      // You can add onTap functionality here if needed
                                    ),
                                    TextSpan(
                                      text: ' of Aura.',
                                      style: GoogleFonts.poppins(
                                        color: textColor, // Apply theme color
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        SizedBox(height: MediaQuery.of(context).viewInsets.bottom > 0 ? 20 : 0),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.only(
                    left: 24.0,
                    right: 24.0,
                    top: 16.0,
                    bottom: MediaQuery.of(context).viewInsets.bottom > 0 ? 16.0 : 30.0,
                  ),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: (isChecked && isValidNumber && !_isLoading)
                              ? _sendOtp
                              : null,
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            backgroundColor: orangeColor, // Always orange
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : Text(
                            'Send OTP',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: _navigateToRegistration,
                        child: Text(
                          'New user? Create an account',
                          style: GoogleFonts.poppins(
                            color: orangeColor,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
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