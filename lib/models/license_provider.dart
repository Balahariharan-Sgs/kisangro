import 'package:flutter/foundation.dart'; // For ChangeNotifier and debugPrint
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert'; // For base64 encoding/decoding
import 'dart:typed_data'; // For Uint8List

// A simple model to hold individual license data
class LicenseData {
  Uint8List? imageBytes;
  bool isImage; // True if image, false if PDF
  String? licenseNumber;
  DateTime? expirationDate;
  bool noExpiry;
  String? displayDate; // For displaying "Permanent" or formatted date

  LicenseData({
    this.imageBytes,
    this.isImage = true,
    this.licenseNumber,
    this.expirationDate,
    this.noExpiry = false,
    this.displayDate,
  });

  // Convert LicenseData to JSON for SharedPreferences
  Map<String, dynamic> toJson() {
    return {
      'imageBytesBase64': imageBytes != null ? base64Encode(imageBytes!) : null,
      'isImage': isImage,
      'licenseNumber': licenseNumber,
      'expirationDateMillis': expirationDate?.millisecondsSinceEpoch,
      'noExpiry': noExpiry,
      'displayDate': displayDate,
    };
  }

  // Create LicenseData from JSON (from SharedPreferences)
  factory LicenseData.fromJson(Map<String, dynamic> json) {
    Uint8List? bytes;
    if (json['imageBytesBase64'] != null) {
      try {
        bytes = base64Decode(json['imageBytesBase64']);
      } catch (e) {
        debugPrint('Error decoding imageBytesBase64: $e');
        bytes = null; // In case of decoding error, treat as null
      }
    }

    DateTime? expiryDate;
    if (json['expirationDateMillis'] != null) {
      try {
        expiryDate = DateTime.fromMillisecondsSinceEpoch(json['expirationDateMillis']);
      } catch (e) {
        debugPrint('Error parsing expirationDateMillis: $e');
        expiryDate = null;
      }
    }

    return LicenseData(
      imageBytes: bytes,
      isImage: json['isImage'] ?? true,
      licenseNumber: json['licenseNumber'],
      expirationDate: expiryDate,
      noExpiry: json['noExpiry'] ?? false,
      displayDate: json['displayDate'],
    );
  }
}

class LicenseProvider extends ChangeNotifier {
  LicenseData? _pesticideLicense;
  LicenseData? _fertilizerLicense;

  LicenseData? get pesticideLicense => _pesticideLicense;
  LicenseData? get fertilizerLicense => _fertilizerLicense;

  LicenseProvider() {
    _loadLicenses(); // Load licenses when the provider is created
  }

  // Load licenses from SharedPreferences
  Future<void> _loadLicenses() async {
    final prefs = await SharedPreferences.getInstance();

    final pesticideJson = prefs.getString('pesticideLicense');
    if (pesticideJson != null) {
      _pesticideLicense = LicenseData.fromJson(jsonDecode(pesticideJson));
    }

    final fertilizerJson = prefs.getString('fertilizerLicense');
    if (fertilizerJson != null) {
      _fertilizerLicense = LicenseData.fromJson(jsonDecode(fertilizerJson));
    }
    notifyListeners(); // Notify listeners after loading
  }

  // Save pesticide license
  Future<void> setPesticideLicense({
    Uint8List? imageBytes,
    required bool isImage,
    String? licenseNumber,
    DateTime? expirationDate,
    required bool noExpiry,
    String? displayDate,
  }) async {
    _pesticideLicense = LicenseData(
      imageBytes: imageBytes,
      isImage: isImage,
      licenseNumber: licenseNumber,
      expirationDate: expirationDate,
      noExpiry: noExpiry,
      displayDate: displayDate,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pesticideLicense', jsonEncode(_pesticideLicense!.toJson()));
    notifyListeners();
  }

  // Save fertilizer license
  Future<void> setFertilizerLicense({
    Uint8List? imageBytes,
    required bool isImage,
    String? licenseNumber,
    DateTime? expirationDate,
    required bool noExpiry,
    String? displayDate,
  }) async {
    _fertilizerLicense = LicenseData(
      imageBytes: imageBytes,
      isImage: isImage,
      licenseNumber: licenseNumber,
      expirationDate: expirationDate,
      noExpiry: noExpiry,
      displayDate: displayDate,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('fertilizerLicense', jsonEncode(_fertilizerLicense!.toJson()));
    notifyListeners();
  }

  // Clear a specific license (e.g., if user wants to re-upload)
  Future<void> clearPesticideLicense() async {
    _pesticideLicense = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('pesticideLicense');
    notifyListeners();
  }

  Future<void> clearFertilizerLicense() async {
    _fertilizerLicense = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('fertilizerLicense');
    notifyListeners();
  }
}
