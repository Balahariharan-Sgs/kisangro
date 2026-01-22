import 'package:flutter/foundation.dart'; // For ChangeNotifier and debugPrint
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert'; // For base64 encoding/decoding
import 'dart:typed_data'; // For Uint8List

// Model to hold all KYC and Business data
class KycBusinessData {
  String? fullName;
  String? mailId;
  String? whatsAppNumber;
  String? businessName;
  String? gstin;
  bool isGstinVerified; // New field to track GSTIN verification status
  String? aadhaarNumber;
  String? panNumber;
  String? natureOfBusiness;
  String? businessContactNumber;
  String? businessAddress; // Conditionally visible
  Uint8List? shopImageBytes; // Stores the image bytes for the shop photo

  KycBusinessData({
    this.fullName,
    this.mailId,
    this.whatsAppNumber,
    this.businessName,
    this.gstin,
    this.isGstinVerified = false, // Default to false
    this.aadhaarNumber,
    this.panNumber,
    this.natureOfBusiness,
    this.businessContactNumber,
    this.businessAddress,
    this.shopImageBytes,
  });

  // Convert KycBusinessData to JSON for SharedPreferences
  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'mailId': mailId,
      'whatsAppNumber': whatsAppNumber,
      'businessName': businessName,
      'gstin': gstin,
      'isGstinVerified': isGstinVerified,
      'aadhaarNumber': aadhaarNumber,
      'panNumber': panNumber,
      'natureOfBusiness': natureOfBusiness,
      'businessContactNumber': businessContactNumber,
      'businessAddress': businessAddress,
      'shopImageBytesBase64': shopImageBytes != null ? base64Encode(shopImageBytes!) : null,
    };
  }

  // Create KycBusinessData from JSON (from SharedPreferences)
  factory KycBusinessData.fromJson(Map<String, dynamic> json) {
    Uint8List? bytes;
    if (json['shopImageBytesBase64'] != null) {
      try {
        bytes = base64Decode(json['shopImageBytesBase64']);
      } catch (e) {
        debugPrint('Error decoding shopImageBytesBase64: $e');
        bytes = null;
      }
    }

    return KycBusinessData(
      fullName: json['fullName'],
      mailId: json['mailId'],
      whatsAppNumber: json['whatsAppNumber'],
      businessName: json['businessName'],
      gstin: json['gstin'],
      isGstinVerified: json['isGstinVerified'] ?? false,
      aadhaarNumber: json['aadhaarNumber'],
      panNumber: json['panNumber'],
      natureOfBusiness: json['natureOfBusiness'],
      businessContactNumber: json['businessContactNumber'],
      businessAddress: json['businessAddress'],
      shopImageBytes: bytes,
    );
  }
}

// Provider to manage and persist KycBusinessData
class KycBusinessDataProvider with ChangeNotifier {
  static const String _prefsKey = 'kycBusinessData'; // Key for SharedPreferences
  KycBusinessData? _kycBusinessData;

  KycBusinessData? get kycBusinessData => _kycBusinessData;

  KycBusinessDataProvider() {
    _loadKycData(); // Load data when the provider is initialized
  }

  // Load KYC data from SharedPreferences
  Future<void> _loadKycData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? kycJson = prefs.getString(_prefsKey);
      if (kycJson != null) {
        _kycBusinessData = KycBusinessData.fromJson(jsonDecode(kycJson));
        debugPrint('KycBusinessDataProvider: Loaded existing data.');
      } else {
        _kycBusinessData = KycBusinessData(); // Initialize with default if no data
        debugPrint('KycBusinessDataProvider: No existing data, initialized empty.');
      }
    } catch (e) {
      debugPrint('KycBusinessDataProvider: Error loading data: $e');
      _kycBusinessData = KycBusinessData(); // Fallback to empty on error
    } finally {
      notifyListeners(); // Notify listeners after load attempt
    }
  }

  // Set (save/update) all KYC data and persist to SharedPreferences
  Future<void> setKycBusinessData({
    String? fullName,
    String? mailId,
    String? whatsAppNumber,
    String? businessName,
    String? gstin,
    bool? isGstinVerified,
    String? aadhaarNumber,
    String? panNumber,
    String? natureOfBusiness,
    String? businessContactNumber,
    String? businessAddress,
    Uint8List? shopImageBytes,
  }) async {
    _kycBusinessData = KycBusinessData(
      fullName: fullName ?? _kycBusinessData?.fullName,
      mailId: mailId ?? _kycBusinessData?.mailId,
      whatsAppNumber: whatsAppNumber ?? _kycBusinessData?.whatsAppNumber,
      businessName: businessName ?? _kycBusinessData?.businessName,
      gstin: gstin ?? _kycBusinessData?.gstin,
      isGstinVerified: isGstinVerified ?? _kycBusinessData?.isGstinVerified ?? false,
      aadhaarNumber: aadhaarNumber ?? _kycBusinessData?.aadhaarNumber,
      panNumber: panNumber ?? _kycBusinessData?.panNumber,
      natureOfBusiness: natureOfBusiness ?? _kycBusinessData?.natureOfBusiness,
      businessContactNumber: businessContactNumber ?? _kycBusinessData?.businessContactNumber,
      businessAddress: businessAddress ?? _kycBusinessData?.businessAddress,
      shopImageBytes: shopImageBytes ?? _kycBusinessData?.shopImageBytes,
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, jsonEncode(_kycBusinessData!.toJson()));
      debugPrint('KycBusinessDataProvider: Data saved successfully.');
    } catch (e) {
      debugPrint('KycBusinessDataProvider: Error saving data: $e');
    }
    notifyListeners();
  }

  // Clear all KYC data
  Future<void> clearKycData() async {
    _kycBusinessData = KycBusinessData(); // Reset to empty
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
    debugPrint('KycBusinessDataProvider: Data cleared.');
    notifyListeners();
  }
}
