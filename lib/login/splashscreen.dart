import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:kisangro/login/secondscreen.dart';
import 'package:kisangro/home/bottom.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kisangro/login/onprocess.dart';
import 'package:kisangro/services/product_service.dart';
import 'dart:async';
import 'package:kisangro/login/login.dart';
import 'package:provider/provider.dart';
import '../home/theme_mode_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

class splashscreen extends StatefulWidget {
  const splashscreen({super.key});

  @override
  State<splashscreen> createState() => _splashscreenState();
}

class _splashscreenState extends State<splashscreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // First, request location permission (regardless of login status)
    await _handleLocationPermission();
    
    // Then proceed with login check and navigation
    await _checkLoginStatusAndNavigate();
  }

  Future<void> _handleLocationPermission() async {
    bool permissionGranted = await _forceAskLocationPermission();
    
    if (permissionGranted) {
      await _storeLocationAndDeviceId();
    } else {
      debugPrint("⚠️ Location permission denied by user");
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('latitude', 0.0);
      await prefs.setDouble('longitude', 0.0);
    }
  }

  Future<bool> _forceAskLocationPermission() async {
    var status = await Permission.locationWhenInUse.status;

    if (status.isGranted) {
      debugPrint("✅ Location already granted");
      return true;
    }

    debugPrint("📢 Requesting location permission from user...");
    status = await Permission.locationWhenInUse.request();

    if (status.isGranted) {
      debugPrint("✅ Location granted via popup");
      return true;
    }

    if (status.isPermanentlyDenied) {
      debugPrint("🚫 Permanently denied — opening settings");
      await openAppSettings();
    }

    return false;
  }

  Future<void> _generateAndStoreFCMToken() async {
    try {
      FirebaseMessaging messaging = FirebaseMessaging.instance;

      // Request permission (Android 13+ safety)
      await messaging.requestPermission();

      String? token = await messaging.getToken();

      if (token != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('fcm_token', token);

        debugPrint("🔥 FCM Token saved: $token");
        
        // Send token to server after saving
        await _sendNotificationTokenToServer();
      }
    } catch (e) {
      debugPrint("FCM Token error: $e");
    }
  }

  // ================= NEW: Send Notification Token to Server =================
  Future<void> _sendNotificationTokenToServer() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get all required data from SharedPreferences
      String? fcmToken = prefs.getString('fcm_token');
      double? latitude = prefs.getDouble('latitude');
      double? longitude = prefs.getDouble('longitude');
      String? deviceId = prefs.getString('device_id');
      int? customerId = prefs.getInt('cus_id'); // Make sure this is stored during login
      
      // If customerId is not stored as int, try getting as string and parse
      if (customerId == null) {
        String? cusIdString = prefs.getString('cus_id');
        if (cusIdString != null) {
          customerId = int.tryParse(cusIdString);
        }
      }

      // Validate required data
      if (fcmToken == null || fcmToken.isEmpty) {
        debugPrint('FCM Token not available yet');
        return;
      }

      if (customerId == null) {
        debugPrint('Customer ID not available - user might not be logged in');
        return;
      }

      // Prepare the API URL
      final String apiUrl = 'https://erpsmart.in/total/api/m_api/';
      
      // Prepare parameters
      final Map<String, String> params = {
        'cid': '85788578',
        'type': '1030',
        'ln': latitude?.toString() ?? '0', // Default to '0' if not available
        'lt': longitude?.toString() ?? '0', // Default to '0' if not available
        'device_id': deviceId ?? '12345', // Fallback to provided example
        'cus_id': customerId.toString(),
        'fcm_token': fcmToken,
      };

      debugPrint('Sending notification token to server with params: $params');

      // Make the API call
      final response = await http.post(
        Uri.parse(apiUrl),
        body: params,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('Notification API timeout');
          return http.Response('Timeout', 408);
        },
      );

      if (response.statusCode == 200) {
        try {
          final responseData = json.decode(response.body);
          debugPrint('Notification API response: $responseData');
          
          // Check if response indicates success (adjust based on your API response structure)
          if (responseData['status'] == 'success' || responseData['success'] == true) {
            debugPrint('✅ FCM token successfully registered on server');
            
            // Optionally store that token was synced
            await prefs.setBool('fcm_token_synced', true);
          } else {
            debugPrint('⚠️ Server returned non-success status: $responseData');
          }
        } catch (e) {
          debugPrint('Error parsing notification API response: $e');
          debugPrint('Raw response: ${response.body}');
        }
      } else {
        debugPrint('❌ Failed to send FCM token. Status: ${response.statusCode}');
        debugPrint('Response body: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error sending notification token to server: $e');
    }
  }

  Future<void> _checkLoginStatusAndNavigate() async {
    await Future.delayed(const Duration(seconds: 2)); // Show splash for 2 seconds

    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    final hasUploadedLicenses = prefs.getBool('hasUploadedLicenses') ?? false;

    // Generate FCM token (only if logged in)
    if (isLoggedIn) {
      await _generateAndStoreFCMToken();
    }

    // Load categories
    try {
      debugPrint('SplashScreen: Loading categories...');
      await ProductService.loadCategoriesFromApi();
    } catch (e) {
      debugPrint('Failed to load data: $e');
    }

    if (!mounted) return;

    // Navigate based on login status
    if (isLoggedIn) {
      if (hasUploadedLicenses) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const Bot()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => KycSplashScreen()),
        );
      }
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const secondscreen()),
      );
    }
  }

  // ================= LOCATION + DEVICE ID =================
  Future<void> _storeLocationAndDeviceId() async {
    final prefs = await SharedPreferences.getInstance();

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      await prefs.setDouble('latitude', position.latitude);
      await prefs.setDouble('longitude', position.longitude);

      debugPrint("📍 Location fetched successfully: ${position.latitude}, ${position.longitude}");
    } catch (e) {
      debugPrint("Location error: $e");
      await prefs.setDouble('latitude', 0.0);
      await prefs.setDouble('longitude', 0.0);
    }

    // -------- DEVICE ID --------
    try {
      final deviceInfo = DeviceInfoPlugin();
      String deviceId = '';

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceId = androidInfo.id ?? androidInfo.device;
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceId = iosInfo.identifierForVendor ?? '';
      }

      await prefs.setString('device_id', deviceId);
      debugPrint("📱 Device ID fetched: $deviceId");
    } catch (e) {
      debugPrint('Device ID error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.shortestSide >= 600;
    final themeMode = Provider.of<ThemeModeProvider>(context).themeMode;
    final isDarkMode = themeMode == ThemeMode.dark;

    final Color gradientStartColor =
        isDarkMode ? Colors.black : const Color(0xffFFD9BD);
    final Color gradientEndColor =
        isDarkMode ? Colors.black : const Color(0xffFFFFFF);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [gradientStartColor, gradientEndColor],
          ),
        ),
        child: Center(
          child: Container(
            height: isTablet ? screenSize.height * 0.5 : 192,
            width: isTablet ? screenSize.width * 0.4 : 149,
            child: Image.asset("assets/logo.png", fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }
}