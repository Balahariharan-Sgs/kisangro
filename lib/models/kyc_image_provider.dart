import 'dart:typed_data';
import 'package:flutter/foundation.dart'; // For ChangeNotifier

class KycImageProvider with ChangeNotifier {
  Uint8List? _kycImageBytes; // Stores the image bytes in memory

  Uint8List? get kycImageBytes => _kycImageBytes;

  KycImageProvider(); // Constructor, no Firebase init needed

  /// Sets the KYC image from provided bytes.
  /// This image is stored in memory and will NOT persist across app restarts.
  /// This is the method that was causing the error if not present.
  void setKycImage(Uint8List imageBytes) {
    _kycImageBytes = imageBytes;
    notifyListeners();
    print('DEBUG: KycImageProvider: KYC image updated in memory. Length: ${imageBytes.lengthInBytes} bytes');
    // In a real app, you would add an API call here to upload the image to your backend
    // and potentially store a URL.
  }

  /// Clears the KYC image from memory.
  void clearKycImage() {
    _kycImageBytes = null;
    notifyListeners();
    print('DEBUG: KycImageProvider: KYC image cleared from memory.');
    // In a real app, you might also call an API to delete the image from your backend.
  }
}
