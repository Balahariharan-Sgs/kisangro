import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:sms_autofill/sms_autofill.dart';
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
  String _appSignature = '';
  late SharedPreferences _prefs;
  bool _prefsLoaded = false;

  static const String _loginApiUrl = 'https://erpsmart.in/total/api/m_api/';

  @override
  void initState() {
    super.initState();
    _initializePrefs();
  }

  Future<void> _initializePrefs() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      await _loadAppSignature();
      setState(() {
        _prefsLoaded = true;
      });
    } catch (e) {
      debugPrint('Prefs initialization error: $e');
      // Initialize with empty prefs to prevent crashes
      _prefs = await SharedPreferences.getInstance();
      setState(() {
        _prefsLoaded = true;
      });
    }
  }

  Future<void> _loadAppSignature() async {
    try {
      final signature = await _getLiveAppSignature();
      setState(() {
        _appSignature = signature;
      });
      debugPrint("LIVE APP SIGNATURE: $_appSignature");
    } catch (e) {
      debugPrint('App signature error: $e');
      setState(() {
        _appSignature = '';
      });
    }
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

  Future<void> _sendOtp() async {
    if (!isChecked || !isValidNumber) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please accept terms and enter a valid 10-digit mobile number.',
            style: GoogleFonts.poppins(),
          ),
        ),
      );
      return;
    }

    if (!_prefsLoaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Initializing app... Please wait.',
            style: GoogleFonts.poppins(),
          ),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      double? latitude = _prefs.getDouble('latitude');
      double? longitude = _prefs.getDouble('longitude');
      String? deviceId = _prefs.getString('device_id');

      Uri url = Uri.parse(_loginApiUrl);

      Map<String, String> body = {
        'cid': '85788578',
        'type': '1002',
        'lt': latitude?.toString() ?? '33',
        'ln': longitude?.toString() ?? '33',
        'device_id': deviceId ?? '33',
        'mobile': _enteredPhoneNumber,
        'app_signature': _appSignature,
      };

      debugPrint("LOGIN API BODY: $body");

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: body,
      ).timeout(const Duration(seconds: 30)); // Increased timeout for slower devices

      debugPrint("STATUS: ${response.statusCode}");
      debugPrint("RESPONSE: ${response.body}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        /// ✅ REGISTERED USER
        if (data.containsKey('cus_id')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                data['error_msg'] ?? 'OTP sent successfully',
                style: GoogleFonts.poppins(),
              ),
            ),
          );

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => OtpScreen(phoneNumber: _enteredPhoneNumber),
            ),
          );
        }

        /// ❌ NOT REGISTERED USER
        else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Mobile number not registered. Please create an account.',
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: const Color(0xffEB7720),
            ),
          );

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const RegistrationScreen(),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Server error (${response.statusCode}). Please try again.',
              style: GoogleFonts.poppins(),
            ),
          ),
        );
      }
    } on http.ClientException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Network connection error. Please check your internet.',
            style: GoogleFonts.poppins(),
          ),
        ),
      );
      debugPrint('ClientException: $e');
    }

     on TimeoutException catch (e) {
       ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Request timeout. Please try again.',
            style: GoogleFonts.poppins(),
          ),
        ),
      );
      debugPrint('TimeoutException: $e');
    } on FormatException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Invalid server response. Please try again.',
            style: GoogleFonts.poppins(),
          ),
        ),
      );
      debugPrint('FormatException: $e');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'An error occurred: $e',
            style: GoogleFonts.poppins(),
          ),
        ),
      );
      debugPrint('General error: $e');
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
    final Color inputBorderColor = isDarkMode ? Colors.white : const Color(0xffEB7720);
    final Color checkboxActiveColor = isDarkMode ? Colors.white : const Color(0xffEB7720);
    final Color checkboxUncheckedColor = isDarkMode ? Colors.grey[400]! : Colors.black;
    final Color orangeColor = const Color(0xffEB7720);

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please complete the login process to proceed.', style: GoogleFonts.poppins())),
        );
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        resizeToAvoidBottomInset: true,
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                gradientStartColor,
                gradientEndColor,
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
                          child: Image.asset("assets/logo.png", height: 80),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Login/Register',
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: orangeColor,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'OTP (One Time Password) will be sent to this number',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(fontSize: 13, color: textColor),
                        ),
                        const SizedBox(height: 20),

                        IntlPhoneField(
                          decoration: InputDecoration(
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: inputBorderColor,
                                width: 2.0,
                              ),
                              borderRadius: const BorderRadius.all(Radius.circular(8)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: inputBorderColor,
                                width: 2.0,
                              ),
                              borderRadius: const BorderRadius.all(Radius.circular(8)),
                            ),
                            labelText: 'Enter mobile number',
                            labelStyle: GoogleFonts.poppins(color: hintColor),
                            border: const OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(8)),
                            ),
                          ),
                          initialCountryCode: 'IN',
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          style: GoogleFonts.poppins(color: textColor),
                          onChanged: (phone) {
                            setState(() {
                              _enteredPhoneNumber = phone.number;
                              isValidNumber = phone.number.length == 10;
                            });
                          },
                        ),

                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Don't worry your details are safe with us.",
                              style: GoogleFonts.poppins(fontSize: 13, color: textColor),
                            ),
                            const SizedBox(width: 5),
                            Icon(Icons.verified, color: orangeColor),
                          ],
                        ),
                        const SizedBox(height: 20),

                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Checkbox(
                              value: isChecked,
                              activeColor: checkboxActiveColor,
                              checkColor: isDarkMode ? Colors.black : Colors.white,
                              side: BorderSide(color: checkboxUncheckedColor),
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
                                    color: textColor,
                                    fontSize: 13,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: 'Terms & Conditions',
                                      style: GoogleFonts.poppins(
                                        color: orangeColor,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    TextSpan(
                                      text: ' of Aura.',
                                      style: GoogleFonts.poppins(
                                        color: textColor,
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
                          onPressed: (!_prefsLoaded || _isLoading || !isChecked || !isValidNumber)
                              ? null
                              : _sendOtp,
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            backgroundColor: orangeColor,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(color: Colors.white),
                                )
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