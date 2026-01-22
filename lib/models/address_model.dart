import 'package:flutter/foundation.dart';

class AddressModel extends ChangeNotifier {
  String _currentAddress = "D/no: 123, abc street, rrr nagar, near ppp, Coimbatore.";
  String _currentPincode = "641612";
  String _currentName = "Smart (name)";
  String _currentCusId = "";

  String get currentAddress => _currentAddress;
  String get currentPincode => _currentPincode;
  String get currentName => _currentName;
  String get currentCusId => _currentCusId;

  void setAddress({
    required String address,
    required String pincode,
    required String name,
    String? cusId,
  }) {
    _currentAddress = address;
    _currentPincode = pincode;
    _currentName = name;
    if (cusId != null) {
      _currentCusId = cusId;
    }
    notifyListeners();
  }

  void updateFromApiResponse(Map<String, dynamic> addressData) {
    _currentName = addressData['name'] ?? _currentName;
    _currentAddress = addressData['address'] ?? _currentAddress;
    _currentPincode = addressData['pin']?.toString() ?? _currentPincode;
    _currentCusId = addressData['cus_id']?.toString() ?? _currentCusId;
    notifyListeners();
  }

  void resetAddress() {
    _currentAddress = "D/no: 123, abc street, rrr nagar, near ppp, Coimbatore.";
    _currentPincode = "641612";
    _currentName = "Smart (name)";
    _currentCusId = "";
    notifyListeners();
  }
}