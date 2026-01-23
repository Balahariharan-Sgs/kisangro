import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../home/theme_mode_provider.dart';
import 'dart:math';
import 'package:confetti/confetti.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';


class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _captchaController = TextEditingController();
  String _enteredPhoneNumber = '';
  bool _isLoading = false;
  bool isChecked = false;
  String _captchaCode = '';
  late ConfettiController _confettiController;
  bool _showCaptchaValidation = false;
  bool _isCaptchaVerified = false;
  int _failedAttempts = 0;
  int _remainingAttempts = 3;
  bool _showAttemptsWarning = false;
  bool _isCaptchaDisabled = false;
  bool _isHumanVerified = false;
  bool _showHumanVerification = true;
  bool _showCaptchaSection = false;
  bool _showSecurityBox = true;

  static const String _apiUrl = 'https://erpsmart.in/total/api/m_api/';

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    _generateCaptcha();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _generateCaptcha() {
    setState(() {
      const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
      final random = Random();
      _captchaCode = String.fromCharCodes(Iterable.generate(
        5,
            (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ));

      _captchaController.clear();
      _showCaptchaValidation = false;
    });
  }

  void _verifyCaptcha() {
    if (_isCaptchaDisabled) return;

    if (_captchaController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter the captcha code', style: GoogleFonts.poppins()),
        ),
      );
      return;
    }

    if (_captchaController.text == _captchaCode) {
      setState(() {
        _isCaptchaVerified = true;
        _showCaptchaValidation = true;
        _showAttemptsWarning = false;
        _showCaptchaSection = false;
        _showSecurityBox = false;
      });
      _confettiController.play();
    } else {
      setState(() {
        _isCaptchaVerified = false;
        _showCaptchaValidation = true;
        _failedAttempts++;
        _remainingAttempts--;

        if (_remainingAttempts <= 0) {
          _isCaptchaDisabled = true;
          _showAttemptsWarning = true;
        } else if (_remainingAttempts == 1) {
          _showAttemptsWarning = true;
        }
      });

      if (!_isCaptchaDisabled) {
        Future.delayed(const Duration(milliseconds: 500), () {
          _generateCaptcha();
        });
      }
    }
  }

  void _resetCaptchaAttempts() {
    setState(() {
      _remainingAttempts = 3;
      _failedAttempts = 0;
      _isCaptchaDisabled = false;
      _showAttemptsWarning = false;
      _isCaptchaVerified = false;
      _showCaptchaSection = true;
      _generateCaptcha();
    });
  }

  void _handleHumanVerification() {
    setState(() {
      _isHumanVerified = true;
      _showHumanVerification = false;
      _showCaptchaSection = true;
    });
  }

  Future<void> _handleRegistration() async {
    if (!_isHumanVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please verify that you are not a robot', style: GoogleFonts.poppins()),
        ),
      );
      return;
    }

    if (!_isCaptchaVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please complete the captcha verification', style: GoogleFonts.poppins()),
        ),
      );
      return;
    }

    // Validate all fields
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter your name', style: GoogleFonts.poppins()),
        ),
      );
      return;
    }

    if (_enteredPhoneNumber.isEmpty || _enteredPhoneNumber.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a valid mobile number', style: GoogleFonts.poppins()),
        ),
      );
      return;
    }

    if (_emailController.text.isEmpty || !_emailController.text.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a valid email address', style: GoogleFonts.poppins()),
        ),
      );
      return;
    }

    if (!isChecked) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please accept the terms and conditions', style: GoogleFonts.poppins()),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      Uri url = Uri.parse(_apiUrl);

final prefs = await SharedPreferences.getInstance();

double? latitude = prefs.getDouble('latitude');
double? longitude = prefs.getDouble('longitude');
String? deviceId = prefs.getString('device_id');

Map<String, String> body = {
  'cid': '85788578',
  'ln': longitude?.toString() ?? '',
  'lt': latitude?.toString() ?? '',
  'device_id': deviceId ?? '',
  'name': _nameController.text,
  'mobile': _enteredPhoneNumber,
  'email': _emailController.text,
  'type': '1003',
};

      

      debugPrint("Registration API URL: $url");
      debugPrint("Registration Request Body: $body");

      final response = await http.post(
        url,
        headers: <String, String>{
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: body,
      ).timeout(const Duration(seconds: 10));

      debugPrint('Registration Response Status Code: ${response.statusCode}');
      debugPrint('Registration Raw Response Body: ${response.body}');

      if (response.statusCode == 200) {
        String? contentType = response.headers['content-type'];
        if (contentType != null && contentType.contains('application/json')) {
          try {
            final Map<String, dynamic> responseData = jsonDecode(response.body);
            debugPrint('Parsed Registration API Response: $responseData');

            // Check if cus_id exists in response (registration successful)
            if (responseData.containsKey('cus_id')) {
              // Registration successful
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Registration successful! Please login.', style: GoogleFonts.poppins()),
                  backgroundColor: const Color(0xffEB7720),
                ),
              );
              Navigator.pop(context);
            } else {
              // Registration failed or user already exists
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(responseData['message'] ?? 'Registration failed. Please try again.', style: GoogleFonts.poppins()),
                ),
              );
            }
          } on FormatException catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Server returned an unexpected response format. Please try again. Error: $e', style: GoogleFonts.poppins()),
              ),
            );
            debugPrint('FormatException: $e. Raw response: ${response.body}');
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Server returned an unexpected response (not JSON). Please try again.', style: GoogleFonts.poppins()),
            ),
          );
          debugPrint('Non-JSON response. Content-Type: $contentType, Raw response: ${response.body}');
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to connect to the server. Status Code: ${response.statusCode}', style: GoogleFonts.poppins()),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Network Error: $e. Please check your internet connection.', style: GoogleFonts.poppins()),
        ),
      );
      debugPrint('Network/API Error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildHumanVerification() {
    if (!_showHumanVerification) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!, width: 1.0),
          ),
          child: Row(
            children: [
              Checkbox(
                value: _isHumanVerified,
                onChanged: (value) {
                  _handleHumanVerification();
                },
                activeColor: const Color(0xffEB7720),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              const SizedBox(width: 8),
              Image.asset(
                "assets/recaptcha.png",
                height: 30,
                width: 30,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 12),
              Text(
                "I'm not a robot",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Please verify that you are human to continue',
          style: GoogleFonts.poppins(
            fontSize: 11,
            color: Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildTextCaptcha() {
    if (!_showCaptchaSection) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Attempts counter and warning
        if (_showAttemptsWarning)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
            decoration: BoxDecoration(
              color: _remainingAttempts == 0 ? Colors.red[50] : Colors.orange[50],
              borderRadius: BorderRadius.circular(5),
              border: Border.all(
                color: _remainingAttempts == 0 ? Colors.red[200]! : Colors.orange[200]!,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _remainingAttempts == 0 ? Icons.error : Icons.warning,
                  size: 16,
                  color: _remainingAttempts == 0 ? Colors.red : Colors.orange[700],
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _remainingAttempts == 0
                        ? 'Captcha disabled. Please reset to try again.'
                        : '${_remainingAttempts} attempt${_remainingAttempts == 1 ? '' : 's'} remaining!',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: _remainingAttempts == 0 ? Colors.red[800] : Colors.orange[800],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (_remainingAttempts == 0)
                  TextButton(
                    onPressed: _resetCaptchaAttempts,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(50, 20),
                    ),
                    child: Text(
                      'RESET',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: const Color(0xffEB7720),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),

        if (_showAttemptsWarning) const SizedBox(height: 8),

        // Captcha code and refresh
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.grey[300]!, width: 1.0),
                ),
                child: Text(
                  _captchaCode,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    color: Colors.grey[800],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _isCaptchaDisabled ? null : _generateCaptcha,
              icon: Icon(Icons.refresh,
                  color: _isCaptchaDisabled ? Colors.grey : const Color(0xffEB7720),
                  size: 20
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              tooltip: 'Generate new code',
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Captcha input field
        TextFormField(
          controller: _captchaController,
          enabled: !_isCaptchaDisabled && _isHumanVerified,
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: const Color(0xffEB7720),
                width: 1.0,
              ),
              borderRadius: const BorderRadius.all(Radius.circular(6)),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: const Color(0xffEB7720),
                width: 1.0,
              ),
              borderRadius: const BorderRadius.all(Radius.circular(6)),
            ),
            disabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: Colors.grey[400]!,
                width: 1.0,
              ),
              borderRadius: const BorderRadius.all(Radius.circular(6)),
            ),
            labelText: 'Enter code',
            labelStyle: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600]),
            border: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(6)),
            ),
          ),
          style: GoogleFonts.poppins(fontSize: 14),
        ),
        const SizedBox(height: 8),

        // Verification status
        if (_showCaptchaValidation)
          Row(
            children: [
              Icon(
                _isCaptchaVerified ? Icons.check_circle : Icons.error,
                size: 16,
                color: _isCaptchaVerified ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 6),
              Text(
                _isCaptchaVerified ? 'Verification successful!' : 'Incorrect code. Please try again.',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: _isCaptchaVerified ? Colors.green : Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

        if (_showCaptchaValidation) const SizedBox(height: 8),

        // Verify button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isCaptchaDisabled ? null : _verifyCaptcha,
            style: ElevatedButton.styleFrom(
              backgroundColor: _isCaptchaDisabled ? Colors.grey : const Color(0xffEB7720),
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            child: Text(
              _isCaptchaVerified ? 'Verified ✓' : 'Verify Captcha',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSecurityVerificationSummary() {
    if (!_isHumanVerified || !_isCaptchaVerified) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green[200]!, width: 1.0),
      ),
      child: Row(
        children: [
          Icon(Icons.verified, color: Colors.green[800], size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Security verification completed ✓',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.green[800],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = Provider.of<ThemeModeProvider>(context).themeMode;
    final isDarkMode = themeMode == ThemeMode.dark;

    final Color gradientStartColor = isDarkMode ? Colors.black : const Color(0xffFFD9BD);
    final Color gradientEndColor = isDarkMode ? Colors.black : const Color(0xffFFFFFF);
    final Color textColor = isDarkMode ? Colors.white : Colors.black;
    final Color hintColor = isDarkMode ? Colors.grey[400]! : Colors.black;
    final Color inputBorderColor = isDarkMode ? Colors.white : const Color(0xffEB7720);
    final Color checkboxActiveColor = isDarkMode ? Colors.white : const Color(0xffEB7720);
    final Color checkboxUncheckedColor = isDarkMode ? Colors.grey[400]! : Colors.black;
    final Color orangeColor = const Color(0xffEB7720);

    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          Container(
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.only(left: 16, top: 16),
                    child: IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: Icon(Icons.arrow_back,
                          color: isDarkMode ? Colors.white : Colors.black87,
                          size: 24),
                      style: IconButton.styleFrom(
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ),

                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: 8),
                          Center(
                            child: Image.asset("assets/logo.png", height: 60),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Create Account',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: orangeColor,
                            ),
                          ),
                          const SizedBox(height: 16),

                          TextFormField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: inputBorderColor,
                                  width: 1.0,
                                ),
                                borderRadius: const BorderRadius.all(Radius.circular(6)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: inputBorderColor,
                                  width: 1.0,
                                ),
                                borderRadius: const BorderRadius.all(Radius.circular(6)),
                              ),
                              labelText: 'Full Name',
                              labelStyle: GoogleFonts.poppins(fontSize: 14, color: hintColor),
                              border: const OutlineInputBorder(
                                borderRadius: BorderRadius.all(Radius.circular(6)),
                              ),
                            ),
                            style: GoogleFonts.poppins(fontSize: 14, color: textColor),
                          ),
                          const SizedBox(height: 12),

                          IntlPhoneField(
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: inputBorderColor,
                                  width: 1.0,
                                ),
                                borderRadius: const BorderRadius.all(Radius.circular(6)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: inputBorderColor,
                                  width: 1.0,
                                ),
                                borderRadius: const BorderRadius.all(Radius.circular(6)),
                              ),
                              labelText: 'Mobile Number',
                              labelStyle: GoogleFonts.poppins(fontSize: 14, color: hintColor),
                              border: const OutlineInputBorder(
                                borderRadius: BorderRadius.all(Radius.circular(6)),
                              ),
                            ),
                            initialCountryCode: 'IN',
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            style: GoogleFonts.poppins(fontSize: 14, color: textColor),
                            onChanged: (phone) {
                              setState(() {
                                _enteredPhoneNumber = phone.number;
                              });
                            },
                          ),
                          const SizedBox(height: 12),

                          TextFormField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: inputBorderColor,
                                  width: 1.0,
                                ),
                                borderRadius: const BorderRadius.all(Radius.circular(6)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: inputBorderColor,
                                  width: 1.0,
                                ),
                                borderRadius: const BorderRadius.all(Radius.circular(6)),
                              ),
                              labelText: 'Email Address',
                              labelStyle: GoogleFonts.poppins(fontSize: 14, color: hintColor),
                              border: const OutlineInputBorder(
                                borderRadius: BorderRadius.all(Radius.circular(6)),
                              ),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            style: GoogleFonts.poppins(fontSize: 14, color: textColor),
                          ),
                          const SizedBox(height: 20),

                          // Security Verification Section - Only show if not completed or if we need to show summary
                          if (_showSecurityBox || (_isHumanVerified && _isCaptchaVerified))
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isDarkMode ? Colors.grey[900] : Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                                  width: 1.0,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Security Verification',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  if (_showSecurityBox) _buildHumanVerification(),
                                  if (_showSecurityBox) _buildTextCaptcha(),
                                  if (!_showSecurityBox) _buildSecurityVerificationSummary(),
                                ],
                              ),
                            ),
                          const SizedBox(height: 16),

                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Checkbox(
                                value: isChecked,
                                activeColor: checkboxActiveColor,
                                checkColor: isDarkMode ? Colors.black : Colors.white,
                                side: BorderSide(color: checkboxUncheckedColor),
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                                onChanged: (value) {
                                  setState(() {
                                    isChecked = value!;
                                  });
                                },
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text.rich(
                                    TextSpan(
                                      text: 'I accept the ',
                                      style: GoogleFonts.poppins(
                                        color: textColor,
                                        fontSize: 12,
                                      ),
                                      children: [
                                        TextSpan(
                                          text: 'Terms & Conditions',
                                          style: GoogleFonts.poppins(
                                            color: orangeColor,
                                            fontWeight: FontWeight.w500,
                                            fontSize: 12,
                                          ),
                                        ),
                                        TextSpan(
                                          text: ' of Aura.',
                                          style: GoogleFonts.poppins(
                                            color: textColor,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),

                  Container(
                    padding: EdgeInsets.only(
                      left: 24.0,
                      right: 24.0,
                      top: 12.0,
                      bottom: MediaQuery.of(context).viewInsets.bottom > 0 ? 12.0 : 24.0,
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isHumanVerified && _isCaptchaVerified && !_isLoading ? _handleRegistration : null,
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          backgroundColor: orangeColor,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                            : Text(
                          'Register',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
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

          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [
                Colors.green,
                Colors.blue,
                Colors.pink,
                Colors.orange,
                Colors.purple
              ],
            ),
          ),
        ],
      ),
    );
  }
}