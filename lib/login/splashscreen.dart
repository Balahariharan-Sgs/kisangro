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

import 'package:geolocator/geolocator.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

class splashscreen extends StatefulWidget {
  const splashscreen({super.key});

  @override
  State<splashscreen> createState() => _splashscreenState();
}

class _splashscreenState extends State<splashscreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatusAndNavigate();
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
      }
    } catch (e) {
      debugPrint("FCM Token error: $e");
    }
  }

  Future<void> _checkLoginStatusAndNavigate() async {
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) {
      return;
    }

    // ---------------- STORE LOCATION & DEVICE ID ----------------
    await _storeLocationAndDeviceId();
    await _generateAndStoreFCMToken(); // ✅ ADD THIS

    try {
      debugPrint('SplashScreen: Starting to load product data...');
      await ProductService.loadProductsFromApi();
      await ProductService.loadCategoriesFromApi();
      debugPrint(
        'SplashScreen: Product and Category data loaded successfully.',
      );
    } catch (e) {
      debugPrint('SplashScreen: Failed to load product/category data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to load app data: $e. Please check your internet connection.',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    final hasUploadedLicenses = prefs.getBool('hasUploadedLicenses') ?? false;

    if (mounted) {
      if (isLoggedIn) {
        if (hasUploadedLicenses) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const Bot()),
          );
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => KycSplashScreen()),
          );
        }
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const secondscreen()),
        );
      }
    }
  }

  // ================= LOCATION + DEVICE ID =================

  Future<void> _storeLocationAndDeviceId() async {
    final prefs = await SharedPreferences.getInstance();

    // -------- LOCATION --------
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      await prefs.setDouble('latitude', position.latitude);
      await prefs.setDouble('longitude', position.longitude);

      debugPrint('Location saved: ${position.latitude}, ${position.longitude}');
    } catch (e) {
      debugPrint('Location error: $e');
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

      debugPrint('Device ID saved: $deviceId');
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
