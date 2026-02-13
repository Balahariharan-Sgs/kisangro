import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For input formatters
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart'; // REQUIRED: Import Provider
import 'package:kisangro/models/cart_model.dart'; // REQUIRED: Import CartModel
import 'package:kisangro/models/address_model.dart'; // Import AddressModel
import 'package:geolocator/geolocator.dart'; // Import geolocator
import 'package:geocoding/geocoding.dart'; // Import geocoding
import '../home/theme_mode_provider.dart'; // Import ThemeModeProvider
import '../common/common_app_bar.dart';
import 'package:shared_preferences/shared_preferences.dart'; // For storing/retrieving cus_id

// Corrected function to get cus_id from shared preferences
Future<String> getCusId() async {
  final prefs = await SharedPreferences.getInstance();
  final dynamic cusIdValue = prefs.get('cus_id');
  if (cusIdValue is int) {
    return cusIdValue.toString();
  } else if (cusIdValue is String) {
    return cusIdValue;
  }
  return '100';
}

// API to update address
Future<bool> updateAddress({
  required String name,
  required String address,
  required String pincode,
  required String cusId,
}) async {
  final url = Uri.parse('https://erpsmart.in/total/api/m_api/');

  try {
      final prefs = await SharedPreferences.getInstance();
      
      double? latitude = prefs.getDouble('latitude');
      double? longitude = prefs.getDouble('longitude');
      String? deviceId = prefs.getString('device_id');

    final response = await http.post(
      url,
      body: {
        'cid': '85788578',
        'type': '1007',
         'ln': longitude?.toString() ?? '',
        'lt': latitude?.toString() ?? '',
        'device_id': deviceId ?? '',
        'cus_id': cusId,
        'address': address,
        'name': name,
        'pin': pincode,
      },
    );

    if (response.statusCode == 200) {
      // Clean the response to remove any non-JSON prefix (warnings)
      String responseBody = response.body;

      // Find the start of JSON object
      int startIndex = responseBody.indexOf('{');
      if (startIndex == -1) {
        debugPrint('Invalid response: No JSON object found');
        return false;
      }

      // Extract only the JSON part
      responseBody = responseBody.substring(startIndex);

      try {
        final data = json.decode(responseBody);
        if (data['error'] == false && data['message'] == 'Address updated successfully') {
          debugPrint('Address update successful: $data');
          return true;
        } else {
          debugPrint('API error: ${data['message'] ?? 'Unknown error'}');
          return false;
        }
      } catch (e) {
        debugPrint('JSON parsing error: $e');
        debugPrint('Raw response: ${response.body}');
        return false;
      }
    } else {
      debugPrint('Server error: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');
      return false;
    }
  } catch (e) {
    debugPrint('Error updating address: $e');
    return false;
  }
}

// API to fetch saved addresses
Future<List<Map<String, dynamic>>> fetchAddresses(String cusId) async {
  final url = Uri.parse('https://erpsmart.in/total/api/m_api/');

 try {
      final prefs = await SharedPreferences.getInstance();
      
      double? latitude = prefs.getDouble('latitude');
      double? longitude = prefs.getDouble('longitude');
      String? deviceId = prefs.getString('device_id');

    final response = await http.post(
      url,
      body: {
        'cid': '85788578',
        'type': '1008',
        'ln': longitude?.toString() ?? '',
        'lt': latitude?.toString() ?? '',
        'device_id': deviceId ?? '',
        'cus_id': cusId,
      },
    );

    if (response.statusCode == 200) {
      // Clean the response to remove any non-JSON prefix (warnings)
      String responseBody = response.body;
      
      debugPrint('address view response body: $responseBody');

      // Find the start of JSON object
      int startIndex = responseBody.indexOf('{');
      if (startIndex == -1) {
        debugPrint('Invalid response: No JSON object found');
        return [];
      }

      // Extract only the JSON part
      responseBody = responseBody.substring(startIndex);

      try {
        final data = json.decode(responseBody);
        if (data['error'] == false && data['message'] == 'Customer data fetched successfully') {
          List<dynamic> addressData = data['data'] ?? [];
          List<Map<String, dynamic>> addresses = [];

          for (var item in addressData) {
            addresses.add({
              'name': item['name'] ?? '',
              'address': item['address'] ?? '',
              'pin': item['pin']?.toString() ?? '',
            });
          }

          debugPrint('Fetched ${addresses.length} addresses');
          return addresses;
        } else {
          debugPrint('API error: ${data['message'] ?? 'Unknown error'}');
          return [];
        }
      } catch (e) {
        debugPrint('JSON parsing error: $e');
        debugPrint('Raw response: ${response.body}');
        return [];
      }
    } else {
      debugPrint('Server error: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');
      return [];
    }
  } catch (e) {
    debugPrint('Error fetching addresses: $e');
    return [];
  }
}

class delivery2 extends StatelessWidget {
  const delivery2({super.key});

  @override
  Widget build(BuildContext context) {
    return const AddAddressScreen();
  }
}

class AddAddressScreen extends StatefulWidget {
  const AddAddressScreen({super.key});

  @override
  State<AddAddressScreen> createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends State<AddAddressScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController pinController = TextEditingController();
  int wordCount = 0;
  final int wordLimit = 100;

  String _autoDetectedAddress = '';
  String _autoDetectedPincode = '';
  bool _isDetectingLocation = false;
  bool _isSaving = false;
  bool _isLoadingAddresses = false;
  List<Map<String, dynamic>> _savedAddresses = [];
  int _selectedAddressIndex = -1;
  String _cusId = '';

  @override
  void initState() {
    super.initState();
    // Initialize text controllers with current address details from the model
    // This ensures they are populated only once when the widget is created.
    final addressModel = Provider.of<AddressModel>(context, listen: false);

    if (addressModel.currentName != "Smart (name)") {
      nameController.text = addressModel.currentName;
    }
    if (addressModel.currentAddress != "D/no: 123, abc street, rrr nagar, near ppp, Coimbatore.") {
      addressController.text = addressModel.currentAddress;
      _onAddressChanged(addressModel.currentAddress); // Update word count on initialization
    }
    if (addressModel.currentPincode != "641612") {
      pinController.text = addressModel.currentPincode;
    }

    // Get cus_id and fetch saved addresses
    _initializeCusIdAndAddresses();
  }

  Future<void> _initializeCusIdAndAddresses() async {
    if (!mounted) return;
    setState(() {
      _isLoadingAddresses = true;
    });

    try {
      // Get cus_id from shared preferences
      _cusId = await getCusId();
      debugPrint('Using cus_id: $_cusId');

      // Fetch saved addresses using the retrieved cus_id
      final addresses = await fetchAddresses(_cusId);
      if (mounted) {
        setState(() {
          _savedAddresses = addresses;
          _isLoadingAddresses = false;
        });
      }
    } catch (e) {
      debugPrint('Error initializing cus_id and addresses: $e');
      if (mounted) {
        setState(() {
          _isLoadingAddresses = false;
        });
      }
    }
  }

  void _onAddressChanged(String value) {
    final words = value.trim().split(RegExp(r'\s+'));
    setState(() {
      wordCount = words.length;
    });
  }

  void _selectAddress(int index) {
    if (index >= 0 && index < _savedAddresses.length) {
      final address = _savedAddresses[index];
      setState(() {
        _selectedAddressIndex = index;
        nameController.text = address['name'] ?? '';
        addressController.text = address['address'] ?? '';
        pinController.text = address['pin'] ?? '';
        _onAddressChanged(addressController.text);
      });
    }
  }

  Future<void> _determinePosition() async {
    setState(() {
      _isDetectingLocation = true;
      _autoDetectedAddress = 'Detecting...';
      _autoDetectedPincode = 'Loading...';
    });

    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!mounted) return;
      setState(() {
        _autoDetectedAddress = 'Location services disabled.';
        _autoDetectedPincode = 'N/A';
        _isDetectingLocation = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location services are disabled. Please enable them.')),
      );
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (!mounted) return;
        setState(() {
          _autoDetectedAddress = 'Location permission denied.';
          _autoDetectedPincode = 'N/A';
          _isDetectingLocation = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permissions are denied. Cannot fetch current location.')),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (!mounted) return;
      setState(() {
        _autoDetectedAddress = 'Location permission permanently denied.';
        _autoDetectedPincode = 'N/A';
        _isDetectingLocation = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location permissions are permanently denied. Please enable from app settings.')),
      );
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);

      if (mounted) {
        if (placemarks.isNotEmpty) {
          Placemark place = placemarks.first;
          String address = [
            place.street,
            place.subLocality,
            place.locality,
            place.administrativeArea,
            place.country
          ].where((element) => element != null && element.isNotEmpty).join(', ');

          String pincode = place.postalCode ?? '';

          setState(() {
            addressController.text = address;
            pinController.text = pincode;
            _onAddressChanged(address); // Update word count for the new address
            _autoDetectedAddress = address; // Update local state for display
            _autoDetectedPincode = pincode; // Update local state for display
            _selectedAddressIndex = -1; // Deselect any saved address
            // IMPORTANT: nameController.text is NOT touched here, as requested.
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Location auto-detected: $address, $pincode')),
          );

        } else {
          setState(() {
            _autoDetectedAddress = 'Location found, but address unknown.';
            _autoDetectedPincode = 'N/A';
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location found, but could not get readable address.')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error getting location in payment2: $e');
      if (mounted) {
        setState(() {
          _autoDetectedAddress = 'Could not get location.';
          _autoDetectedPincode = 'N/A';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting current location: ${e.toString()}.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDetectingLocation = false;
        });
      }
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    addressController.dispose();
    pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final addressModel = Provider.of<AddressModel>(context, listen: false);
    final themeMode = Provider.of<ThemeModeProvider>(context).themeMode;
    final isDarkMode = themeMode == ThemeMode.dark;

    // Define colors based on theme
    final Color gradientStartColor = isDarkMode ? Colors.black : const Color(0xffFFD9BD);
    final Color gradientEndColor = isDarkMode ? Colors.black : const Color(0xffFFFFFF);
    final Color textColor = isDarkMode ? Colors.white : Colors.black;
    final Color labelColor = isDarkMode ? Colors.white70 : Colors.grey;
    final Color hintColor = isDarkMode ? Colors.grey[400]! : Colors.grey;
    final Color inputBorderColor = isDarkMode ? Colors.grey[600]! : Colors.grey;
    final Color inputFocusedBorderColor = isDarkMode ? Colors.white : const Color(0xffEB7720); // Orange for light, white for dark
    final Color inputFillColor = isDarkMode ? Colors.grey[800]! : Colors.white;
    final Color dividerColor = isDarkMode ? Colors.grey[700]! : Colors.black;
    final Color orangeColor = const Color(0xffEB7720); // Orange color, remains constant
    final Color cardBackgroundColor = isDarkMode ? Colors.grey[850]! : Colors.white;
    final Color cardBorderColor = isDarkMode ? Colors.grey[700]! : Colors.grey.shade300;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: orangeColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          "Add New Address",
          style: GoogleFonts.poppins(color: Colors.white, fontSize: 18),
        ),
        centerTitle: false,
      ),
      body: Container(
        height: double.infinity,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [gradientStartColor, gradientEndColor], // Apply theme colors
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Divider(thickness: 1, color: dividerColor), // Apply theme color
              Text(
                'Step 2/3',
                style: GoogleFonts.poppins(
                    color: orangeColor, fontWeight: FontWeight.bold), // Always orange
              ),
              const SizedBox(height: 16),

              // Saved Addresses Section
              if (_savedAddresses.isNotEmpty) ...[
                Text(
                  'Saved Addresses',
                  style: GoogleFonts.poppins(
                      fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
                ),
                const SizedBox(height: 12),
                _isLoadingAddresses
                    ? Center(child: CircularProgressIndicator(color: orangeColor))
                    : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _savedAddresses.length,
                  itemBuilder: (context, index) {
                    final address = _savedAddresses[index];
                    return GestureDetector(
                      onTap: () => _selectAddress(index),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: cardBackgroundColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _selectedAddressIndex == index
                                ? orangeColor
                                : cardBorderColor,
                            width: _selectedAddressIndex == index ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              address['name'] ?? 'No Name',
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              address['address'] ?? 'No Address',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: hintColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Pincode: ${address['pin'] ?? 'N/A'}',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: hintColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                Divider(thickness: 1, color: dividerColor),
                const SizedBox(height: 20),
              ],

              Text(
                'Address details',
                style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.bold, color: textColor), // Apply theme color
              ),
              const SizedBox(height: 16),
              // Name Text Field
              TextField(
                controller: nameController,
                style: GoogleFonts.poppins(color: textColor), // Apply theme color
                decoration: InputDecoration(
                  labelText: 'Enter Name',
                  labelStyle: GoogleFonts.poppins(color: labelColor), // Apply theme color
                  hintStyle: GoogleFonts.poppins(color: hintColor), // Apply theme color
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: inputBorderColor), // Apply theme color
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: inputFocusedBorderColor, width: 2), // Apply theme color
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: inputBorderColor), // Apply theme color
                  ),
                  fillColor: inputFillColor, // Apply theme color
                  filled: true,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: addressController,
                style: GoogleFonts.poppins(color: textColor), // Apply theme color
                maxLines: 3,
                onChanged: _onAddressChanged,
                decoration: InputDecoration(
                  labelText: 'Enter Address',
                  labelStyle: GoogleFonts.poppins(color: labelColor), // Apply theme color
                  hintStyle: GoogleFonts.poppins(color: hintColor), // Apply theme color
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: inputBorderColor), // Apply theme color
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: inputFocusedBorderColor, width: 2), // Apply theme color
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: inputBorderColor), // Apply theme color
                  ),
                  fillColor: inputFillColor, // Apply theme color
                  filled: true,
                  suffixText: '$wordCount/$wordLimit',
                  suffixStyle: GoogleFonts.poppins(
                    color: wordCount > wordLimit ? Colors.red : hintColor, // Apply theme color for hint
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: pinController,
                style: GoogleFonts.poppins(color: textColor), // Apply theme color
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                maxLength: 6,
                decoration: InputDecoration(
                  labelText: 'Enter Pincode',
                  labelStyle: GoogleFonts.poppins(color: labelColor), // Apply theme color
                  hintStyle: GoogleFonts.poppins(color: hintColor), // Apply theme color
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: inputBorderColor), // Apply theme color
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: inputFocusedBorderColor, width: 2), // Apply theme color
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: inputBorderColor), // Apply theme color
                  ),
                  fillColor: inputFillColor, // Apply theme color
                  filled: true,
                  counterText: '',
                ),
              ),
              const SizedBox(height: 20),
              // Auto-Detect Location Button
              ElevatedButton.icon(
                onPressed: _isDetectingLocation ? null : _determinePosition,
                style: ElevatedButton.styleFrom(
                  backgroundColor: orangeColor, // Always orange
                  foregroundColor: Colors.white, // Always white
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  minimumSize: const Size(double.infinity, 50),
                ),
                icon: _isDetectingLocation
                    ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                    : const Icon(Icons.location_on_outlined),
                label: Text(
                  _isDetectingLocation ? 'Detecting Location...' : 'Auto-Detect Location',
                  style: GoogleFonts.poppins(fontSize: 16),
                ),
              ),
              const SizedBox(height: 20),
              // Save Address Button
              ElevatedButton(
                onPressed: _isSaving
                    ? null
                    : () async {
                  if (nameController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter a name.')),
                    );
                    return;
                  }
                  if (addressController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter an address.')),
                    );
                    return;
                  }
                  if (pinController.text.length != 6) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter a valid 6-digit pincode.')),
                    );
                    return;
                  }
                  if (wordCount > wordLimit) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Address exceeds the word limit. Please shorten it.')),
                    );
                    return;
                  }

                  setState(() {
                    _isSaving = true;
                  });

                  // Check and fetch cus_id just before the API call to ensure it's not empty
                  if (_cusId.isEmpty) {
                    _cusId = await getCusId();
                  }

                  // Update the AddressModel
                  addressModel.setAddress(
                    address: addressController.text,
                    pincode: pinController.text,
                    name: nameController.text,
                  );

                  // Call the API to update address using the retrieved cus_id
                  bool success = await updateAddress(
                    name: nameController.text,
                    address: addressController.text,
                    pincode: pinController.text,
                    cusId: _cusId, // Use the retrieved cus_id
                  );

                  setState(() {
                    _isSaving = false;
                  });

                  if (mounted) {
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Address saved successfully!')),
                      );
                      // Re-initialize addresses after a successful save to reflect the new data.
                      await _initializeCusIdAndAddresses();
                      // Only pop the screen if the addresses were re-fetched successfully
                      // Or if you want to pop it anyway, but it's better to show the new list.
                      Navigator.pop(context);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Failed to save address. Please try again.')),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: orangeColor, // Always orange
                  foregroundColor: Colors.white, // Always white
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: _isSaving
                    ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                    : Text(
                  'Save Address',
                  style: GoogleFonts.poppins(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}