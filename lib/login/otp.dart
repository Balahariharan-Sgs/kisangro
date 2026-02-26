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
import 'package:sms_autofill/sms_autofill.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class OtpScreen extends StatefulWidget {
  final String phoneNumber;

  const OtpScreen({super.key, required this.phoneNumber});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final TextEditingController otpController = TextEditingController();
  Timer? _timer;
  int _start = 30;
  bool canResend = false;
  bool isOtpFilled = false;
  bool _isVerifying = false;
  String _appSignature = '';
  bool _isDisposed = false;
  StreamSubscription<String>? _smsSubscription;

  static const String _verifyOtpApiUrl = 'https://erpsmart.in/total/api/m_api/';

  @override
  void initState() {
    super.initState();
    otpController.addListener(_onOtpChanged);
    startTimer();
    _initSmsAutofill();
    _loadAppSignature();
    _generateFCMToken(); // Generate FCM token early
  }

  void _onOtpChanged() {
    if (_isDisposed) return;

    setState(() {
      isOtpFilled = otpController.text.length == 6;
    });
  }

  // ================= FCM TOKEN GENERATION =================
  Future<void> _generateFCMToken() async {
    try {
      FirebaseMessaging messaging = FirebaseMessaging.instance;

      // Request permission (Android 13+ safety)
      await messaging.requestPermission();

      String? token = await messaging.getToken();

      if (token != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('fcm_token', token);
        debugPrint("🔥 FCM Token generated and saved: $token");
      }
    } catch (e) {
      debugPrint("FCM Token generation error: $e");
    }
  }

  // ================= SEND NOTIFICATION TOKEN TO SERVER =================
  Future<void> _sendNotificationTokenToServer(int customerId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get all required data from SharedPreferences
      String? fcmToken = prefs.getString('fcm_token');
      double? latitude = prefs.getDouble('latitude');
      double? longitude = prefs.getDouble('longitude');
      String? deviceId = prefs.getString('device_id');

      // Validate required data
      if (fcmToken == null || fcmToken.isEmpty) {
        debugPrint('FCM Token not available, generating now...');
        await _generateFCMToken();
        fcmToken = prefs.getString('fcm_token');
        
        if (fcmToken == null || fcmToken.isEmpty) {
          debugPrint('Still unable to get FCM token');
          return;
        }
      }

      // Prepare the API URL
      final String apiUrl = 'https://erpsmart.in/total/api/m_api/';
      
      // Prepare parameters
      final Map<String, String> params = {
        'cid': '85788578',
        'type': '1030',
        'ln': longitude?.toString() ?? '1', // Note: API uses ln for longitude
        'lt': latitude?.toString() ?? '1',  // Note: API uses lt for latitude
        'device_id': deviceId ?? '12345',
        'cus_id': customerId.toString(),
        'fcm_token': fcmToken,
      };

      debugPrint('Sending notification token to server with params: $params');

      // Make the API call (fire and forget - don't await to not block navigation)
      http.post(
        Uri.parse(apiUrl),
        body: params,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('Notification API timeout');
          return http.Response('Timeout', 408);
        },
      ).then((response) {
        if (response.statusCode == 200) {
          try {
            final responseData = json.decode(response.body);
            debugPrint('Notification API response: $responseData');
            
            if (responseData['error'] == false || 
                responseData['status'] == 'success' || 
                responseData['success'] == true) {
              debugPrint('✅ FCM token successfully registered on server');
              prefs.setBool('fcm_token_synced', true);
            } else {
              debugPrint('⚠️ Server returned non-success status: $responseData');
            }
          } catch (e) {
            debugPrint('Error parsing notification API response: $e');
          }
        } else {
          debugPrint('❌ Failed to send FCM token. Status: ${response.statusCode}');
        }
      }).catchError((e) {
        debugPrint('Error sending notification token to server: $e');
      });

    } catch (e) {
      debugPrint('Error in _sendNotificationTokenToServer: $e');
    }
  }

  Future<void> _initSmsAutofill() async {
    try {
      debugPrint('Initializing SMS autofill...');

      // Get app signature first
      final signature = await SmsAutoFill().getAppSignature;
      debugPrint('App Signature: $signature');

      // Start listening for SMS
      await SmsAutoFill().listenForCode();
      debugPrint('SMS listening started');

      // Subscribe to SMS code stream
      _smsSubscription = SmsAutoFill().code.listen((code) {
        debugPrint('Received SMS code: $code');
        if (code != null && code.length == 6 && !_isDisposed && mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!_isDisposed && mounted) {
              setState(() {
                otpController.text = code;
                isOtpFilled = true;
              });
              debugPrint('Auto-filled OTP: $code');
            }
          });
        }
      });

      // Also try to get the code immediately if already available
      final existingCode = await SmsAutoFill().getAppSignature.then((_) {
        return SmsAutoFill().code;
      });

      if (existingCode != null &&
          existingCode.length == 6 &&
          !_isDisposed &&
          mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!_isDisposed && mounted) {
            setState(() {
              otpController.text = existingCode as String;
              isOtpFilled = true;
            });
            debugPrint('Auto-filled existing OTP: $existingCode');
          }
        });
      }
    } catch (e) {
      debugPrint('SMS Autofill initialization error: $e');
    }
  }

  Future<void> _loadAppSignature() async {
    if (_isDisposed) return;

    try {
      final signature = await _getLiveAppSignature();
      if (_isDisposed) return;

      setState(() {
        _appSignature = signature;
      });
      debugPrint("OTP SCREEN LIVE APP SIGNATURE: $_appSignature");
    } catch (e) {
      debugPrint('Error loading app signature: $e');
    }
  }

  Future<String> _getLiveAppSignature() async {
    try {
      final signature = await SmsAutoFill().getAppSignature;
      debugPrint('Got app signature: $signature');
      return signature ?? '';
    } catch (e) {
      debugPrint('App signature error: $e');
      return '';
    }
  }

  void startTimer() {
    if (_isDisposed) return;

    setState(() {
      _start = 30;
      canResend = false;
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isDisposed) {
        timer.cancel();
        return;
      }

      if (_start == 0) {
        if (!_isDisposed) {
          setState(() {
            canResend = true;
          });
        }
        timer.cancel();
      } else {
        if (!_isDisposed) {
          setState(() {
            _start--;
          });
        }
      }
    });
  }

  Future<void> _verifyOtp() async {
    if (_isDisposed) return;

    if (!isOtpFilled) {
      if (!_isDisposed && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Please enter the complete OTP.',
              style: GoogleFonts.poppins(),
            ),
          ),
        );
      }
      return;
    }

    setState(() {
      _isVerifying = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();

      double? latitude = prefs.getDouble('latitude');
      double? longitude = prefs.getDouble('longitude');
      String? deviceId = prefs.getString('device_id');

      Uri url = Uri.parse(_verifyOtpApiUrl);

      Map<String, String> body = {
        'cid': '85788578',
        'type': '1004',
        'ln': longitude?.toString() ?? '1',
        'lt': latitude?.toString() ?? '1',
        'device_id': deviceId ?? '1',
        'mobile': widget.phoneNumber,
        'otp': otpController.text,
      };

      debugPrint("OTP Verification API BODY: $body");

      final response = await http
          .post(
            url,
            headers: <String, String>{
              'Content-Type': 'application/x-www-form-urlencoded',
            },
            body: body,
          )
          .timeout(const Duration(seconds: 10));

      if (_isDisposed) return;

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        debugPrint('OTP Verification API Response: $responseData');

        if (responseData['error'] == false) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('isLoggedIn', true);
          await prefs.setString('mobile_number', widget.phoneNumber);
          await prefs.remove('kyc_completed');

          debugPrint('Stored mobile number: ${widget.phoneNumber}');

          try {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              try {
                if (!_isDisposed && mounted) {
                  final kycBusinessDataProvider =
                      Provider.of<KycBusinessDataProvider>(
                        context,
                        listen: false,
                      );
                  final kycImageProvider = Provider.of<KycImageProvider>(
                    context,
                    listen: false,
                  );

                  kycBusinessDataProvider.clearKycData();
                  kycImageProvider.clearKycImage();

                  debugPrint('Cleared existing KYC data for new user login');
                }
              } catch (e) {
                debugPrint(
                  'Error clearing KYC data: $e. This is normal if providers are not initialized yet.',
                );
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
              
              // ===== SEND NOTIFICATION TOKEN TO SERVER AFTER LOGIN =====
              // Call this after successful login and storing cus_id
              _sendNotificationTokenToServer(cusId);
            }

            if (!_isDisposed && mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    responseData['error_msg'] ?? 'OTP verified successfully!',
                    style: GoogleFonts.poppins(),
                  ),
                ),
              );

              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => kyc()),
              );
            }
          } else {
            debugPrint('User data not found or invalid in API response.');
            if (!_isDisposed && mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'User data missing. Proceeding to KYC.',
                    style: GoogleFonts.poppins(),
                  ),
                ),
              );
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => kyc()),
              );
            }
          }
        } else {
          if (!_isDisposed && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  responseData['error_msg'] ?? 'Invalid OTP. Please try again.',
                  style: GoogleFonts.poppins(),
                ),
              ),
            );
          }

          otpController.clear();
          if (!_isDisposed) {
            setState(() {
              isOtpFilled = false;
            });
          }
        }
      } else {
        if (!_isDisposed && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to verify OTP. Status Code: ${response.statusCode}',
                style: GoogleFonts.poppins(),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (!_isDisposed && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Network Error: $e. Please check your internet connection.',
              style: GoogleFonts.poppins(),
            ),
          ),
        );
      }
      debugPrint('Network/API Error: $e');
    } finally {
      if (!_isDisposed) {
        setState(() {
          _isVerifying = false;
        });
      }
    }
  }

  Future<void> _resendOtp() async {
    if (_isDisposed) return;
    if (!canResend) return;

    try {
      final prefs = await SharedPreferences.getInstance();

      double? latitude = prefs.getDouble('latitude');
      double? longitude = prefs.getDouble('longitude');
      String? deviceId = prefs.getString('device_id');

      Uri url = Uri.parse(_verifyOtpApiUrl);

      Map<String, String> body = {
        'cid': '85788578',
        'type': '1002',
        'lt': latitude?.toString() ?? '1',
        'ln': longitude?.toString() ?? '1',
        'device_id': deviceId ?? '',
        'mobile': widget.phoneNumber,
        'app_signature': _appSignature,
      };

      debugPrint("RESEND OTP API BODY: $body");

      final response = await http
          .post(
            url,
            headers: <String, String>{
              'Content-Type': 'application/x-www-form-urlencoded',
            },
            body: body,
          )
          .timeout(const Duration(seconds: 10));

      if (_isDisposed) return;

      debugPrint("RESEND OTP STATUS: ${response.statusCode}");
      debugPrint("RESEND OTP RESPONSE: ${response.body}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        if (data.containsKey('cus_id')) {
          if (!_isDisposed && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  data['error_msg'] ?? 'OTP resent successfully!',
                  style: GoogleFonts.poppins(),
                ),
              ),
            );
          }
          startTimer();
        } else {
          if (!_isDisposed && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Failed to resend OTP. Please try again.',
                  style: GoogleFonts.poppins(),
                ),
              ),
            );
          }
        }
      } else {
        if (!_isDisposed && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Server error. Please try again.',
                style: GoogleFonts.poppins(),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (!_isDisposed && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Network error: $e', style: GoogleFonts.poppins()),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _timer?.cancel();
    _smsSubscription?.cancel();
    otpController.removeListener(_onOtpChanged);
    otpController.dispose();

    try {
      SmsAutoFill().unregisterListener();
    } catch (e) {
      debugPrint('Error during SMS autofill dispose: $e');
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = Provider.of<ThemeModeProvider>(context).themeMode;
    final isDarkMode = themeMode == ThemeMode.dark;

    final Color gradientStartColor =
        isDarkMode ? Colors.black : const Color(0xffFFD9BD);
    final Color gradientEndColor =
        isDarkMode ? Colors.black : const Color(0xffFFFFFF);
    final Color backButtonColor = isDarkMode ? Colors.white : Colors.black87;
    final Color textColor = isDarkMode ? Colors.white : Colors.black;
    final Color otpFieldActiveColor =
        isDarkMode ? Colors.white : const Color(0xffEB7720);
    final Color otpFieldInactiveColor =
        isDarkMode ? Colors.grey[600]! : Colors.grey;
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
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
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

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      Center(child: Image.asset('assets/logo.png', height: 80)),
                      const SizedBox(height: 40),
                      Center(
                        child: Text(
                          'OTP Verification',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: orangeColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      Center(
                        child: RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: textColor,
                            ),
                            children: [
                              TextSpan(
                                text:
                                    'We sent an OTP (One Time Password) to your mobile number ',
                                style: TextStyle(color: textColor),
                              ),
                              TextSpan(
                                text: widget.phoneNumber,
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Using PinCodeTextField with autofill
                      PinCodeTextField(
                        appContext: context,
                        length: 6,
                        controller: otpController,
                        onChanged: (value) {
                          if (_isDisposed) return;
                          setState(() {
                            isOtpFilled = value.length == 6;
                          });
                        },
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        pinTheme: PinTheme(
                          shape: PinCodeFieldShape.underline,
                          fieldWidth: 30,
                          activeColor: otpFieldActiveColor,
                          selectedColor: otpFieldActiveColor,
                          inactiveColor: otpFieldInactiveColor,
                        ),
                        textStyle: GoogleFonts.poppins(color: textColor),
                        // Enable autofill for SMS
                        autoFocus: true,
                        enableActiveFill: false,
                        // Add SMS autofill capability
                        autoDisposeControllers: false,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Didn't receive OTP?",
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: textColor,
                            ),
                          ),
                          canResend
                              ? GestureDetector(
                                onTap: _resendOtp,
                                child: Text(
                                  'Resend now',
                                  style: GoogleFonts.poppins(
                                    color: orangeColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )
                              : Text(
                                '0:${_start.toString().padLeft(2, '0')}',
                                style: GoogleFonts.poppins(
                                  color: timerTextColor,
                                ),
                              ),
                        ],
                      ),
                      SizedBox(
                        height:
                            MediaQuery.of(context).viewInsets.bottom > 0
                                ? 40
                                : 20,
                      ),
                    ],
                  ),
                ),
              ),

              Container(
                padding: EdgeInsets.only(
                  left: 24.0,
                  right: 24.0,
                  top: 16.0,
                  bottom:
                      MediaQuery.of(context).viewInsets.bottom > 0
                          ? 16.0
                          : 30.0,
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
                  child:
                      _isVerifying
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