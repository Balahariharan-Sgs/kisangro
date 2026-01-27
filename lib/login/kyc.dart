import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:kisangro/login/licence.dart';
import 'package:provider/provider.dart';
import 'package:kisangro/models/kyc_image_provider.dart';
import 'package:kisangro/models/kyc_business_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kisangro/home/bottom.dart';
import '../home/theme_mode_provider.dart';

class kyc extends StatefulWidget {
  @override
  _kycState createState() => _kycState();
}

class _kycState extends State<kyc> {
  Uint8List? _imageBytes;
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _mailIdController = TextEditingController();
  final TextEditingController _whatsAppNumberController =
      TextEditingController();
  final TextEditingController _businessNameController = TextEditingController();
  final TextEditingController _gstinController = TextEditingController();
  final TextEditingController _aadhaarNumberController =
      TextEditingController();
  final TextEditingController _panNumberController = TextEditingController();
  String? _natureOfBusinessSelected;
  final TextEditingController _businessContactNumberController =
      TextEditingController();

  bool _isGstinVerified = false;
  Map<String, dynamic>? _gstinDetails;
  KycBusinessDataProvider? _kycBusinessDataProvider;
  KycImageProvider? _kycImageProvider;
  int? _cusId;
  bool _isLoadingCusId = true;
  bool _isLoadingKycData = false;
  bool _isSubmitting = false;
  bool _hasExistingKycData = false;
  bool _isLoadingImage = false;
  bool _imageLoadFailed = false;
  bool _isKycOptionalFlow = false;

  static const int maxChars = 100;
  static const String _apiUrl = 'https://sgserp.in/erp/api/m_api/';
  static const String _cid = '23262954';

  @override
  void initState() {
    super.initState();
    debugPrint('KYC Screen: initState called');
    _initializeKycScreen();
    _whatsAppNumberController.addListener(_autoFillBusinessContactNumber);
  }

  Future<void> _initializeKycScreen() async {
    try {
      _kycBusinessDataProvider = Provider.of<KycBusinessDataProvider>(
        context,
        listen: false,
      );
      _kycImageProvider = Provider.of<KycImageProvider>(context, listen: false);
      debugPrint('KYC Screen: Providers initialized successfully');
    } catch (e) {
      debugPrint('KYC Screen: Error initializing providers: $e');
    }

    await _loadCusId();
    if (_cusId != null) {
      await _fetchKycData(_cusId!);
    } else {
      _loadExistingKycData();
    }
    setState(() {
      _isLoadingCusId = false;
    });
  }

  @override
  void dispose() {
    debugPrint('KYC Screen: dispose called');
    _fullNameController.dispose();
    _mailIdController.dispose();
    _whatsAppNumberController.dispose();
    _businessNameController.dispose();
    _gstinController.dispose();
    _aadhaarNumberController.dispose();
    _panNumberController.dispose();
    _businessContactNumberController.dispose();
    _whatsAppNumberController.removeListener(_autoFillBusinessContactNumber);
    super.dispose();
  }

  Future<void> _loadCusId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _cusId = prefs.getInt('cus_id');
      debugPrint('KYC Screen: Loaded cus_id: $_cusId');
    });
  }

  // Enhanced method to load image from URL with comprehensive error handling
  Future<Uint8List?> _loadImageFromUrl(String imageUrl) async {
    if (imageUrl.isEmpty) return null;

    try {
      setState(() {
        _isLoadingImage = true;
        _imageLoadFailed = false;
      });

      debugPrint('KYC Screen: Original image path from server: $imageUrl');

      // Validate image format
      if (!imageUrl.toLowerCase().endsWith('.jpg') &&
          !imageUrl.toLowerCase().endsWith('.jpeg') &&
          !imageUrl.toLowerCase().endsWith('.png')) {
        debugPrint('KYC Screen: Invalid image format detected: $imageUrl');
        setState(() {
          _imageLoadFailed = true;
        });
        return null;
      }

      // Check if the URL already starts with http
      if (imageUrl.startsWith('http')) {
        // URL is already complete, use it directly
        debugPrint('KYC Screen: Using complete URL: $imageUrl');
        final response = await http
            .get(
              Uri.parse(imageUrl),
              headers: {
                'Accept': 'image/*',
                'User-Agent': 'KisangroApp/1.0',
                'Cache-Control': 'no-cache',
              },
            )
            .timeout(Duration(seconds: 12));

        if (response.statusCode == 200 &&
            _isValidImageData(response.bodyBytes)) {
          return response.bodyBytes;
        }
      }

      // If we get here, we need to construct the URL properly
      // The server returns paths like "erp/uploads/kyc/kyc_23262954_287_1758264669.jpg"
      // The correct URL should be "https://sgserp.in/erp/uploads/kyc/kyc_23262954_287_1758264669.jpg"

      String baseUrl = 'https://sgserp.in';
      String completeUrl = '$baseUrl/$imageUrl';

      // Remove any double slashes that might occur
      completeUrl = completeUrl.replaceAll('//', '/').replaceFirst(':/', '://');

      debugPrint('KYC Screen: Constructed URL: $completeUrl');

      final response = await http
          .get(
            Uri.parse(completeUrl),
            headers: {
              'Accept': 'image/*',
              'User-Agent': 'KisangroApp/1.0',
              'Cache-Control': 'no-cache',
            },
          )
          .timeout(Duration(seconds: 12));

      debugPrint(
        'KYC Screen: Response status for $completeUrl: ${response.statusCode}',
      );
      debugPrint(
        'KYC Screen: Content-Type: ${response.headers['content-type']}',
      );
      debugPrint(
        'KYC Screen: Content-Length: ${response.headers['content-length']}',
      );

      if (response.statusCode == 200) {
        if (_isValidImageData(response.bodyBytes)) {
          debugPrint(
            'KYC Screen: ✅ Image loaded successfully from: $completeUrl',
          );
          debugPrint(
            'KYC Screen: Image size: ${response.bodyBytes.lengthInBytes} bytes',
          );
          return response.bodyBytes;
        } else {
          debugPrint(
            'KYC Screen: ❌ Response is not a valid image: $completeUrl',
          );
        }
      } else {
        debugPrint(
          'KYC Screen: ❌ HTTP ${response.statusCode} for: $completeUrl',
        );
      }

      debugPrint('KYC Screen: ❌ Failed to load image: $imageUrl');
      setState(() {
        _imageLoadFailed = true;
      });
      return null;
    } catch (e) {
      debugPrint('KYC Screen: Critical error in image loading process: $e');
      setState(() {
        _imageLoadFailed = true;
      });
      return null;
    } finally {
      setState(() {
        _isLoadingImage = false;
      });
    }
  }

  // Helper method to validate if bytes represent a valid image
  bool _isValidImageData(Uint8List bytes) {
    if (bytes.length < 4) return false;

    // Check for common image file signatures
    // JPEG: FF D8 FF
    if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
      return true;
    }

    // PNG: 89 50 4E 47
    if (bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return true;
    }

    // GIF: 47 49 46 38
    if (bytes[0] == 0x47 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x38) {
      return true;
    }

    // WebP: 52 49 46 46 (RIFF) + WebP signature
    if (bytes.length >= 12 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) {
      return true;
    }

    return false;
  }

  Future<void> _fetchKycData(int cusId) async {
    setState(() {
      _isLoadingKycData = true;
    });

    debugPrint(
      'KYC Screen: Attempting to fetch existing KYC data for cus_id: $cusId',
    );
    try {
      final prefs = await SharedPreferences.getInstance();

      double? latitude = prefs.getDouble('latitude');
      double? longitude = prefs.getDouble('longitude');
      String? deviceId = prefs.getString('device_id');

      final response = await _callApiWithRetry(
        body: {
          'cid': _cid,
          'type': '1024',
          'lt': latitude?.toString() ?? '',
          'ln': longitude?.toString() ?? '',
          'device_id': deviceId ?? '',
          'cus_id': cusId.toString(),
        },
      );

      debugPrint('KYC Screen: API response for fetching data: $response');

      if (response['error'] == false && response['data'] != null) {
        // Handle the new API response format
        final responseData = response['data'];

        // Extract all fields with null checks
        final kycData = {
          'name': responseData['name'] ?? '',
          'email': responseData['email'] ?? '',
          'mobile': responseData['w_num'] ?? '',
          'business_name': responseData['com_name'] ?? '',
          'gstin': responseData['gstin'] ?? '',
          'aadhar': responseData['aadhar'] ?? '',
          'pan': responseData['pan'] ?? '',
          'nature_of_business':
              'Distributor', // Default as not provided in new API
          'business_contact_number': responseData['phone_1'] ?? '',
          'isGstinVerified': responseData['v_status'] == 'verified',
          'business_address': responseData['address'] ?? '',
          'photo': responseData['photo'] ?? '', // Get photo URL
        };

        // Load image from URL if available
        Uint8List? imageBytes;
        if (kycData['photo']!.isNotEmpty) {
          debugPrint('KYC Screen: Photo URL found: ${kycData['photo']}');
          imageBytes = await _loadImageFromUrl(kycData['photo']!);
          if (imageBytes == null) {
            debugPrint(
              'KYC Screen: Failed to load image, will show placeholder',
            );
          }
        }

        // Update UI and provider
        WidgetsBinding.instance.addPostFrameCallback((_) {
          setState(() {
            _fullNameController.text = kycData['name']!;
            _mailIdController.text = kycData['email']!;
            _whatsAppNumberController.text = kycData['mobile']!;
            _businessNameController.text = kycData['business_name']!;
            _gstinController.text = kycData['gstin']!;
            _aadhaarNumberController.text = kycData['aadhar']!;
            _panNumberController.text = kycData['pan']!;
            _natureOfBusinessSelected = kycData['nature_of_business']!;
            _businessContactNumberController.text =
                kycData['business_contact_number']!;
            _isGstinVerified = kycData['isGstinVerified']!;
            _hasExistingKycData = true;

            // Set image bytes if loaded successfully
            if (imageBytes != null) {
              _imageBytes = imageBytes;
              debugPrint('KYC Screen: Image loaded and set successfully');
            } else if (kycData['photo']!.isNotEmpty) {
              debugPrint('KYC Screen: Image path exists but loading failed');
            }

            // Set GSTIN details if verified
            if (_isGstinVerified) {
              _gstinDetails = {
                'GSTIN': kycData['gstin'],
                'Business Address': kycData['business_address'],
              };
            }
          });

          // Save to provider
          _kycBusinessDataProvider?.setKycBusinessData(
            fullName: kycData['name'],
            mailId: kycData['email'],
            whatsAppNumber: kycData['mobile'],
            businessName: kycData['business_name'],
            gstin: kycData['gstin'],
            isGstinVerified: kycData['isGstinVerified'],
            aadhaarNumber: kycData['aadhar'],
            panNumber: kycData['pan'],
            natureOfBusiness: kycData['nature_of_business'],
            businessContactNumber: kycData['business_contact_number'],
            businessAddress: kycData['business_address'],
            shopImageBytes: imageBytes, // Save image bytes
          );

          // Update image provider
          if (imageBytes != null) {
            _kycImageProvider?.setKycImage(imageBytes);
          }
        });

        debugPrint(
          'KYC Screen: Successfully fetched and populated data from new API',
        );
      } else {
        // Fallback to old API if new one doesn't return data
        debugPrint('KYC Screen: New API returned no data, trying old API...');
        await _fetchKycDataOldApi(cusId);
      }
    } catch (e) {
      debugPrint(
        'KYC Screen: Error fetching data from new API: $e. Trying old API...',
      );
      await _fetchKycDataOldApi(cusId);
    } finally {
      setState(() {
        _isLoadingKycData = false;
      });
    }
  }

  Future<void> _fetchKycDataOldApi(int cusId) async {
    try {
      final response = await _callApiWithRetry(
        body: {
          'cid': _cid,
          'type': '1003',
          'cus_id': cusId.toString(),
          'ln': '2324',
          'lt': '23',
          'device_id': '122',
        },
      );

      debugPrint('KYC Screen: Old API response for fetching data: $response');

      if (response['status'] == 'success') {
        // Handle both array and object response formats
        dynamic responseData = response['data'];
        if (responseData is List && responseData.isNotEmpty) {
          responseData = responseData[0];
        }

        // Extract all fields with null checks
        final kycData = {
          'name': responseData['name'] ?? '',
          'email': responseData['email'] ?? '',
          'mobile': responseData['mobile'] ?? '',
          'business_name': responseData['business_name'] ?? '',
          'gstin': responseData['gstin'] ?? '',
          'aadhar': responseData['aadhar'] ?? '',
          'pan': responseData['pan'] ?? '',
          'nature_of_business': responseData['nature_of_business'] ?? '',
          'business_contact_number':
              responseData['business_contact_number'] ?? '',
          'isGstinVerified': responseData['isGstinVerified'] ?? false,
          'photo':
              responseData['photo'] ?? '', // Get photo URL from old API too
        };

        // Load image from URL if available
        Uint8List? imageBytes;
        if (kycData['photo']!.isNotEmpty) {
          debugPrint(
            'KYC Screen: Photo URL found in old API: ${kycData['photo']}',
          );
          imageBytes = await _loadImageFromUrl(kycData['photo']!);
        }

        // Update UI and provider
        WidgetsBinding.instance.addPostFrameCallback((_) {
          setState(() {
            _fullNameController.text = kycData['name']!;
            _mailIdController.text = kycData['email']!;
            _whatsAppNumberController.text = kycData['mobile']!;
            _businessNameController.text = kycData['business_name']!;
            _gstinController.text = kycData['gstin']!;
            _aadhaarNumberController.text = kycData['aadhar']!;
            _panNumberController.text = kycData['pan']!;
            _natureOfBusinessSelected = kycData['nature_of_business']!;
            _businessContactNumberController.text =
                kycData['business_contact_number']!;
            _isGstinVerified = kycData['isGstinVerified']!;
            _hasExistingKycData = true;

            // Set image bytes if loaded
            if (imageBytes != null) {
              _imageBytes = imageBytes;
              debugPrint(
                'KYC Screen: Image loaded and set successfully from old API',
              );
            }
          });

          // Save to provider
          _kycBusinessDataProvider?.setKycBusinessData(
            fullName: kycData['name'],
            mailId: kycData['email'],
            whatsAppNumber: kycData['mobile'],
            businessName: kycData['business_name'],
            gstin: kycData['gstin'],
            isGstinVerified: kycData['isGstinVerified'],
            aadhaarNumber: kycData['aadhar'],
            panNumber: kycData['pan'],
            natureOfBusiness: kycData['nature_of_business'],
            businessContactNumber: kycData['business_contact_number'],
            shopImageBytes: imageBytes, // Save image bytes
          );

          // Update image provider
          if (imageBytes != null) {
            _kycImageProvider?.setKycImage(imageBytes);
          }
        });

        debugPrint(
          'KYC Screen: Successfully fetched and populated data from old API',
        );
      } else {
        debugPrint(
          'KYC Screen: No data found for cus_id: $cusId or API call failed. Loading local data instead.',
        );
        _loadExistingKycData();
      }
    } catch (e) {
      debugPrint(
        'KYC Screen: Error fetching data from old API: $e. Loading local data instead.',
      );
      _loadExistingKycData();
    }
  }

  void _loadExistingKycData() {
    debugPrint('KYC Screen: Loading existing KYC data from local provider');
    try {
      final existingBusinessData = _kycBusinessDataProvider?.kycBusinessData;
      if (existingBusinessData != null) {
        setState(() {
          _fullNameController.text = existingBusinessData.fullName ?? '';
          _mailIdController.text = existingBusinessData.mailId ?? '';
          _whatsAppNumberController.text =
              existingBusinessData.whatsAppNumber ?? '';
          _businessNameController.text =
              existingBusinessData.businessName ?? '';
          _gstinController.text = existingBusinessData.gstin ?? '';
          _isGstinVerified = existingBusinessData.isGstinVerified;
          _gstinDetails =
              existingBusinessData.gstin != null &&
                      existingBusinessData.businessAddress != null
                  ? {
                    'GSTIN': existingBusinessData.gstin,
                    'Business Address': existingBusinessData.businessAddress,
                  }
                  : null;
          _aadhaarNumberController.text =
              existingBusinessData.aadhaarNumber ?? '';
          _panNumberController.text = existingBusinessData.panNumber ?? '';
          _natureOfBusinessSelected = existingBusinessData.natureOfBusiness;
          _businessContactNumberController.text =
              existingBusinessData.businessContactNumber ?? '';
          _imageBytes = existingBusinessData.shopImageBytes;
          _hasExistingKycData =
              existingBusinessData.fullName != null &&
              existingBusinessData.fullName!.isNotEmpty;

          if (existingBusinessData.shopImageBytes != null) {
            _kycImageProvider?.setKycImage(
              existingBusinessData.shopImageBytes!,
            );
          }
          debugPrint('KYC Screen: Existing KYC data loaded successfully');
        });
      } else {
        debugPrint('KYC Screen: No existing local KYC data found');
      }
    } catch (e) {
      debugPrint('KYC Screen: Error loading existing local KYC data: $e');
    }
  }

  void _autoFillBusinessContactNumber() {
    if (_whatsAppNumberController.text.length == 10 &&
        _businessContactNumberController.text.isEmpty) {
      _businessContactNumberController.text = _whatsAppNumberController.text;
      debugPrint(
        'KYC Screen: Autofilled business contact number with WhatsApp number: ${_whatsAppNumberController.text}',
      );
    }
  }

  Future<void> _showImagePickerDialog() async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Select Image', style: GoogleFonts.poppins()),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                GestureDetector(
                  child: ListTile(
                    leading: Icon(Icons.photo_camera),
                    title: Text('Camera', style: GoogleFonts.poppins()),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                Padding(padding: EdgeInsets.all(8.0)),
                GestureDetector(
                  child: ListTile(
                    leading: Icon(Icons.image),
                    title: Text('Gallery', style: GoogleFonts.poppins()),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    debugPrint('KYC Screen: Attempting to pick image from $source');
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: source,
        maxWidth: 300, // Much smaller dimensions
        maxHeight: 300, // Much smaller dimensions
        imageQuality: 40, // Much lower quality for smaller file size
      );

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        debugPrint(
          'KYC Screen: Compressed image size: ${bytes.lengthInBytes} bytes (${(bytes.lengthInBytes / 1024).toStringAsFixed(1)} KB)',
        );

        // Only proceed if image is under 100KB
        if (bytes.lengthInBytes > 100000) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Image is still too large (${(bytes.lengthInBytes / 1024).toStringAsFixed(1)} KB). Please try a different image or take a new photo.',
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 4),
            ),
          );
          return;
        }

        setState(() {
          _imageBytes = bytes;
          _imageLoadFailed = false; // Reset the flag when new image is selected
        });

        await _kycBusinessDataProvider?.setKycBusinessData(
          shopImageBytes: bytes,
        );
        _kycImageProvider?.setKycImage(bytes);
        debugPrint(
          'KYC Screen: Image successfully set. Size: ${bytes.lengthInBytes} bytes',
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Image selected successfully! Size: ${(bytes.lengthInBytes / 1024).toStringAsFixed(1)} KB',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        debugPrint('KYC Screen: Image picking cancelled from $source');
      }
    } catch (e) {
      debugPrint('KYC Screen: Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error picking image: $e',
            style: GoogleFonts.poppins(),
          ),
        ),
      );
    }
  }

  Widget _sectionTitle(String title, bool isTablet, bool isDarkMode) {
    final Color orangeColor = const Color(0xffEB7720);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: isTablet ? 15 : 10),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: isTablet ? 18 : 16,
            fontWeight: FontWeight.bold,
            color: orangeColor,
          ),
        ),
      ),
    );
  }

  Widget _textFormField(
    String label, {
    String? hintText,
    bool isNumber = false,
    bool showVerify = false,
    bool isPAN = false,
    TextEditingController? controller,
    required bool isTablet,
    required bool isDarkMode,
  }) {
    final Color textColor = isDarkMode ? Colors.white : Colors.black;
    final Color hintColor = isDarkMode ? Colors.grey[400]! : Colors.black;
    final Color fillColor =
        isDarkMode ? Colors.grey[700]! : const Color(0xfff8bc8c);
    final Color borderColor =
        isDarkMode ? Colors.grey[600]! : Colors.transparent;
    final Color focusedBorderColor =
        isDarkMode ? Colors.white : const Color(0xfff8bc8c);
    final Color orangeColor = const Color(0xffEB7720);

    return SizedBox(
      height: isTablet ? 80 : 70,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: isTablet ? 20 : 10),
        child: TextFormField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          inputFormatters:
              isPAN
                  ? [
                    FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                    UpperCaseTextFormatter(),
                  ]
                  : isNumber
                  ? [FilteringTextInputFormatter.digitsOnly]
                  : null,
          maxLength: () {
            if (isPAN) return 10;
            if (!isNumber) return null;
            if (label == "WhatsApp Number" ||
                label == "Business Contact Number")
              return 10;
            if (label == "Aadhaar Number (Owner)") return 12;
            return null;
          }(),
          decoration: InputDecoration(
            counterText: "",
            border: OutlineInputBorder(
              borderSide: BorderSide(color: borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: focusedBorderColor, width: 2),
            ),
            filled: true,
            fillColor: fillColor,
            labelText: label,
            labelStyle: GoogleFonts.poppins(color: hintColor),
            hintText: hintText,
            hintStyle: GoogleFonts.poppins(
              color: hintColor,
              fontWeight: FontWeight.bold,
            ),
            contentPadding: EdgeInsets.symmetric(
              vertical: isTablet ? 20 : 16,
              horizontal: isTablet ? 20 : 12,
            ),
            isDense: true,
            suffixIcon:
                showVerify
                    ? Padding(
                      padding: EdgeInsets.zero,
                      child: ElevatedButton(
                        onPressed: () async {
                          debugPrint('KYC Screen: GSTIN Verify button pressed');
                          FocusScope.of(context).unfocus();

                          if (_gstinController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Please enter GSTIN number',
                                  style: GoogleFonts.poppins(),
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          // GSTIN verification logic here
                          try {
                            final response = await _verifyGstin(
                              gstin: _gstinController.text,
                              cid: _cid,
                              type: '1018',
                              ln: '2324',
                              lt: '23',
                              deviceId: '122',
                              cusId: _cusId?.toString() ?? '',
                            );

                            if (response['status'] == 'success') {
                              final address = _extractAddressFromResponse(
                                response,
                              );
                              setState(() {
                                _isGstinVerified = true;
                                _gstinDetails = {
                                  'GSTIN': _gstinController.text,
                                  'Business Address':
                                      address ?? 'Address verified',
                                };
                              });

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'GSTIN verified successfully!',
                                    style: GoogleFonts.poppins(),
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'GSTIN verification failed: ${response['message']}',
                                    style: GoogleFonts.poppins(),
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Error verifying GSTIN: $e',
                                  style: GoogleFonts.poppins(),
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(2),
                          ),
                          backgroundColor: orangeColor,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 0,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Verify',
                          style: GoogleFonts.poppins(
                            fontSize: isTablet ? 14 : 12,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    )
                    : null,
          ),
          style: GoogleFonts.poppins(
            fontSize: isTablet ? 16 : 14,
            color: textColor,
          ),
          validator: null,
        ),
      ),
    );
  }

  Widget _dropdownField(
    String label,
    String? selectedValue,
    ValueChanged<String?> onChanged,
    bool isTablet,
    bool isDarkMode,
  ) {
    final Color textColor = isDarkMode ? Colors.white : Colors.black;
    final Color fillColor =
        isDarkMode ? Colors.grey[700]! : const Color(0xfff8bc8c);
    final Color borderColor =
        isDarkMode ? Colors.grey[600]! : Colors.transparent;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 20 : 10,
        vertical: isTablet ? 8 : 6,
      ),
      child: SizedBox(
        height: isTablet ? 80 : 70,
        child: DropdownButtonFormField<String>(
          value: selectedValue,
          decoration: InputDecoration(
            filled: true,
            fillColor: fillColor,
            labelText: label,
            labelStyle: GoogleFonts.poppins(
              color: isDarkMode ? Colors.grey[400]! : Colors.black,
            ),
            border: OutlineInputBorder(
              borderSide: BorderSide(color: borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: isDarkMode ? Colors.white : const Color(0xfff8bc8c),
                width: 2,
              ),
            ),
            contentPadding: EdgeInsets.symmetric(
              vertical: isTablet ? 20 : 16,
              horizontal: isTablet ? 20 : 12,
            ),
          ),
          items: const [
            DropdownMenuItem(value: 'Distributor', child: Text('Distributor')),
          ],
          onChanged: onChanged,
          validator: null,
          style: GoogleFonts.poppins(
            fontSize: isTablet ? 16 : 14,
            color: textColor,
          ),
          dropdownColor: isDarkMode ? Colors.grey[800] : Colors.white,
        ),
      ),
    );
  }

  // Enhanced photo upload box with better error handling and status display
  Widget _photoUploadBox(bool isTablet, bool isDarkMode) {
    final Color textColor = isDarkMode ? Colors.white : Colors.black54;
    final Color containerColor =
        isDarkMode ? Colors.grey[700]! : Colors.grey.shade200;
    final Color borderColor = isDarkMode ? Colors.grey[600]! : Colors.grey;
    final Color iconColor = const Color(0xffEB7720);

    return Padding(
      padding: EdgeInsets.only(
        top: isTablet ? 20 : 10,
        left: isTablet ? 20 : 0,
        right: isTablet ? 20 : 0,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () => _showImagePickerDialog(),
            child: Container(
              width: isTablet ? 160 : 130,
              height: isTablet ? 160 : 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: borderColor, width: 1),
                color: containerColor,
              ),
              child: _buildImageContent(isTablet, isDarkMode, iconColor),
            ),
          ),
          SizedBox(width: isTablet ? 20 : 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getImageStatusText(),
                  textAlign: TextAlign.start,
                  style: GoogleFonts.poppins(
                    fontSize: isTablet ? 15 : 13,
                    color: textColor,
                  ),
                ),
                if (_imageBytes != null) ...[
                  SizedBox(height: 5),
                  Text(
                    'Image size: ${(_imageBytes!.lengthInBytes / 1024).toStringAsFixed(1)} KB',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.green,
                    ),
                  ),
                ],
                if (_isLoadingImage) ...[
                  SizedBox(height: 5),
                  Text(
                    'Loading image from server...',
                    style: GoogleFonts.poppins(fontSize: 12, color: iconColor),
                  ),
                ],
                if (_imageLoadFailed) ...[
                  SizedBox(height: 5),
                  Text(
                    'Previous image unavailable. Please upload a new image.',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageContent(bool isTablet, bool isDarkMode, Color iconColor) {
    // Show loading indicator
    if (_isLoadingKycData || _isLoadingImage) {
      return Center(child: CircularProgressIndicator(color: iconColor));
    }

    // Show existing image if available
    if (_imageBytes != null) {
      return ClipOval(
        child: Image.memory(
          _imageBytes!,
          width: isTablet ? 160 : 130,
          height: isTablet ? 160 : 130,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            debugPrint(
              'KYC Screen: Error displaying image from memory: $error',
            );
            return _buildImagePlaceholder(isTablet, isDarkMode, iconColor);
          },
        ),
      );
    }

    // Show placeholder for failed image load
    if (_hasExistingKycData && _imageLoadFailed) {
      return _buildImagePlaceholder(isTablet, isDarkMode, iconColor);
    }

    // Default camera icon for new upload
    return Icon(Icons.camera_alt, size: isTablet ? 70 : 50, color: iconColor);
  }

  Widget _buildImagePlaceholder(
    bool isTablet,
    bool isDarkMode,
    Color iconColor,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.image_not_supported,
          size: isTablet ? 40 : 30,
          color: iconColor,
        ),
        SizedBox(height: 5),
        Text(
          'Image\nUnavailable',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: isTablet ? 12 : 10,
            color: iconColor,
          ),
        ),
      ],
    );
  }

  String _getImageStatusText() {
    if (_isLoadingImage) {
      return 'Loading existing image from server...';
    } else if (_imageLoadFailed && _hasExistingKycData) {
      return 'Previous image could not be loaded. Tap to upload a new photo of your shop with good quality.';
    } else if (_imageBytes == null && _hasExistingKycData) {
      return 'Previous image unavailable. Tap to upload a new photo of your shop with good quality.';
    } else if (_imageBytes == null) {
      return 'Tap to upload a photo of your shop with good quality.';
    } else {
      return 'Tap to change the shop photo.';
    }
  }

  Future<dynamic> _callApiWithRetry({
    required Map<String, String> body,
    int retries = 3,
  }) async {
    for (int i = 0; i < retries; i++) {
      try {
        final response = await http
            .post(Uri.parse(_apiUrl), body: body)
            .timeout(const Duration(seconds: 15));

        if (response.statusCode == 200) {
          final decodedBody = json.decode(response.body);
          return decodedBody;
        } else {
          debugPrint(
            'API call failed with status: ${response.statusCode}. Retrying...',
          );
        }
      } catch (e) {
        debugPrint('API call failed with error: $e. Retrying...');
      }
      if (i < retries - 1) {
        await Future.delayed(const Duration(seconds: 2));
      }
    }
    throw Exception('Failed to connect to the API after $retries attempts.');
  }

  Future<Map<String, dynamic>> _verifyGstin({
    required String gstin,
    required String cid,
    required String type,
    required String ln,
    required String lt,
    required String deviceId,
    required String cusId,
  }) async {
    final body = {
      'cid': cid,
      'type': type,
      'ln': ln,
      'lt': lt,
      'device_id': deviceId,
      'gstin': gstin,
      'cus_id': cusId,
    };
    final response = await _callApiWithRetry(body: body);

    debugPrint('Full GSTIN verification response: $response');
    return response;
  }

  String? _extractAddressFromResponse(Map<String, dynamic> response) {
    try {
      // Handle the detailed GSTIN verification response (first type)
      if (response['data'] is String) {
        try {
          final parsedData = json.decode(response['data']);
          if (parsedData['result'] != null &&
              parsedData['result']['gstnDetailed'] != null) {
            final gstnDetails = parsedData['result']['gstnDetailed'];

            // First try to get from principalPlaceAddress if available
            if (gstnDetails['principalPlaceAddress'] != null &&
                gstnDetails['principalPlaceAddress']['address'] != null) {
              return gstnDetails['principalPlaceAddress']['address'].toString();
            }

            // Then try additionalPlaceAddress
            if (gstnDetails['additionalPlaceAddress'] != null &&
                gstnDetails['additionalPlaceAddress'] is List &&
                gstnDetails['additionalPlaceAddress'].isNotEmpty) {
              return gstnDetails['additionalPlaceAddress'][0]['address']
                  .toString();
            }

            // Fallback to constructing from other details
            final addressParts = <String>[];

            // Add business name
            if (gstnDetails['tradeNameOfBusiness'] != null) {
              addressParts.add(gstnDetails['tradeNameOfBusiness'].toString());
            } else if (gstnDetails['legalNameOfBusiness'] != null) {
              addressParts.add(gstnDetails['legalNameOfBusiness'].toString());
            }

            // Add jurisdiction information
            if (gstnDetails['centreJurisdiction'] != null) {
              final parts = gstnDetails['centreJurisdiction'].toString().split(
                ',',
              );
              for (final part in parts) {
                final trimmed = part.trim();
                if (trimmed.startsWith('ZONE - ')) {
                  addressParts.add(trimmed.replaceFirst('ZONE - ', ''));
                } else if (trimmed.startsWith('DIVISION - ')) {
                  addressParts.add(trimmed.replaceFirst('DIVISION - ', ''));
                }
              }
            }

            if (gstnDetails['stateJurisdiction'] != null) {
              final parts = gstnDetails['stateJurisdiction'].toString().split(
                ',',
              );
              for (final part in parts) {
                final trimmed = part.trim();
                if (trimmed.startsWith('STATE - ')) {
                  addressParts.add(trimmed.replaceFirst('STATE - ', ''));
                }
              }
            }

            if (addressParts.isNotEmpty) {
              return addressParts.join(', ');
            }
          }
        } catch (e) {
          debugPrint('Error parsing nested GSTIN data: $e');
        }
      }
      // Handle the simple KYC data response (second type)
      else if (response['data'] is List && response['data'].isNotEmpty) {
        final responseData = response['data'][0];
        return responseData['address'] ??
            responseData['paddress'] ??
            responseData['caddress'];
      }

      return null;
    } catch (e) {
      debugPrint('Error extracting address from response: $e');
      return null;
    }
  }

  Widget _buildVerifiedGstinDetails(bool isTablet, bool isDarkMode) {
    final Color textColor = isDarkMode ? Colors.white : Colors.black;
    final Color orangeColor = const Color(0xffEB7720);

    if (!_isGstinVerified || _gstinDetails == null)
      return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 20 : 10,
        vertical: 10,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Verified GSTIN Details",
            style: GoogleFonts.poppins(
              fontSize: isTablet ? 18 : 16,
              fontWeight: FontWeight.bold,
              color: orangeColor,
            ),
          ),
          SizedBox(height: isTablet ? 15 : 10),
          _buildDetailRow(
            "GSTIN Number:",
            _gstinDetails!['GSTIN'],
            isTablet,
            textColor,
          ),
          SizedBox(height: isTablet ? 10 : 8),
          _buildDetailRow(
            "Business Address:",
            _gstinDetails!['Business Address'],
            isTablet,
            textColor,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value,
    bool isTablet,
    Color textColor,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: isTablet ? 150 : 120,
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: isTablet ? 16 : 14,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: isTablet ? 16 : 14,
              color: textColor,
            ),
          ),
        ),
      ],
    );
  }

  // Updated method to submit KYC data with improved image handling
  Future<Map<String, dynamic>> _submitKycData() async {
    debugPrint('KYC Screen: Submitting KYC data to API with image');

    try {
      // Generate a unique KYC ID
      final String kycId =
          'KYC${DateTime.now().millisecondsSinceEpoch.toRadixString(16)}';

      // Get the business address from GSTIN details or use a default value
      final String businessAddress =
          _gstinDetails?['Business Address'] ??
          (_businessNameController.text.isNotEmpty
              ? '${_businessNameController.text}, Address to be verified'
              : 'Address to be verified');

      // Retry logic for multipart request
      for (int attempt = 1; attempt <= 3; attempt++) {
        try {
          debugPrint('KYC Screen: Upload attempt $attempt/3');

          // Create multipart request
          var request = http.MultipartRequest('POST', Uri.parse(_apiUrl));

          // Add text fields
          request.fields.addAll({
            'cid': _cid,
            'type': '1023',
            'ln': '2324',
            'lt': '23',
            'device_id': '122',
            'cus_id': _cusId?.toString() ?? '',
            'kyc_id': kycId,
            'name': _fullNameController.text,
            'com_name': _businessNameController.text,
            'gstin': _gstinController.text,
            'pan': _panNumberController.text,
            'aadhar': _aadhaarNumberController.text,
            'nature_of_business': _natureOfBusinessSelected ?? 'Distributor',
            'address': businessAddress,
            'phone_1': _businessContactNumberController.text,
            'w_num': _whatsAppNumberController.text,
            'email': _mailIdController.text,
          });

          debugPrint('KYC Screen: Multipart request fields: ${request.fields}');

          // Add image file if available with improved handling
          if (_imageBytes != null && _imageBytes!.isNotEmpty) {
            debugPrint(
              'KYC Screen: Adding shop image to multipart request. Size: ${_imageBytes!.lengthInBytes} bytes',
            );

            // Final image size check
            debugPrint('Final image details:');
            debugPrint(
              '- Size: ${_imageBytes!.lengthInBytes} bytes (${(_imageBytes!.lengthInBytes / 1024).toStringAsFixed(1)} KB)',
            );
            debugPrint('- Field name: photo');
            debugPrint('- Content-Type: image/jpeg');

            // Check if first few bytes look like JPEG
            if (_imageBytes!.length > 10) {
              debugPrint('- First 4 bytes: ${_imageBytes!.sublist(0, 4)}');
              debugPrint(
                '- Is JPEG: ${_imageBytes![0] == 0xFF && _imageBytes![1] == 0xD8}',
              );
            }

            // Use exactly 'photo' as confirmed by the API parameter list
            var multipartFile = http.MultipartFile.fromBytes(
              'photo',
              _imageBytes!,
              filename: 'shop_photo.jpg',
              contentType: MediaType('image', 'jpeg'),
            );

            request.files.add(multipartFile);
            debugPrint('KYC Screen: Shop image added with field name "photo"');
          } else {
            debugPrint('KYC Screen: No shop image available to upload');
          }

          debugPrint('KYC Screen: Request headers: ${request.headers}');
          debugPrint(
            'KYC Screen: Multipart request files count: ${request.files.length}',
          );

          // Send the request with progressive timeout
          int timeoutSeconds = 60 + (attempt * 30); // 60, 90, 120 seconds
          debugPrint(
            'KYC Screen: Sending request with ${timeoutSeconds}s timeout',
          );

          var streamedResponse = await request.send().timeout(
            Duration(seconds: timeoutSeconds),
          );
          var response = await http.Response.fromStream(streamedResponse);

          debugPrint('KYC Screen: API response status: ${response.statusCode}');
          debugPrint('KYC Screen: API response headers: ${response.headers}');
          debugPrint('KYC Screen: API response body: ${response.body}');

          if (response.statusCode == 200) {
            final decodedResponse = json.decode(response.body);
            debugPrint('KYC Screen: Decoded API response: $decodedResponse');

            // If this attempt was successful, return the response
            if (decodedResponse['status'] == 'success') {
              return decodedResponse;
            } else if (decodedResponse['status'] == 'error' &&
                decodedResponse['message'] == 'Failed to upload photo') {
              // Photo upload specifically failed, try different approaches
              debugPrint(
                'KYC Screen: Photo upload failed, trying alternative approach on attempt $attempt',
              );

              if (attempt < 3) {
                // On next attempt, try base64 upload
                if (attempt == 2) {
                  debugPrint('KYC Screen: Trying base64 upload method');
                  return await _submitKycDataBase64();
                }
                continue;
              } else {
                // On final attempt, try without image
                debugPrint(
                  'KYC Screen: All photo upload attempts failed, trying without image',
                );
                return await _submitKycDataFallback();
              }
            } else {
              // Other error, return the response
              return decodedResponse;
            }
          } else {
            throw Exception(
              'API request failed with status: ${response.statusCode}, body: ${response.body}',
            );
          }
        } catch (e) {
          debugPrint('KYC Screen: Attempt $attempt failed: $e');
          if (attempt == 3) {
            // Last attempt failed, try fallback method without image
            debugPrint(
              'KYC Screen: All multipart attempts failed, trying fallback without image',
            );
            return await _submitKycDataFallback();
          }

          // Wait before retry
          await Future.delayed(Duration(seconds: 2 * attempt));
        }
      }

      throw Exception('All upload attempts failed');
    } catch (e) {
      debugPrint('KYC Screen: Error in multipart request: $e');
      rethrow;
    }
  }

  // Base64 upload method as alternative
  Future<Map<String, dynamic>> _submitKycDataBase64() async {
    debugPrint('KYC Screen: Trying base64 upload method');

    try {
      final String kycId =
          'KYC${DateTime.now().millisecondsSinceEpoch.toRadixString(16)}';
      final String businessAddress =
          _gstinDetails?['Business Address'] ??
          (_businessNameController.text.isNotEmpty
              ? '${_businessNameController.text}, Address to be verified'
              : 'Address to be verified');

      final String base64Image = base64Encode(_imageBytes!);
      debugPrint(
        'KYC Screen: Base64 image length: ${base64Image.length} characters',
      );

      final Map<String, String> body = {
        'cid': _cid,
        'type': '1023',
        'ln': '2324',
        'lt': '23',
        'device_id': '122',
        'cus_id': _cusId?.toString() ?? '',
        'kyc_id': kycId,
        'name': _fullNameController.text,
        'com_name': _businessNameController.text,
        'gstin': _gstinController.text,
        'pan': _panNumberController.text,
        'aadhar': _aadhaarNumberController.text,
        'nature_of_business': _natureOfBusinessSelected ?? 'Distributor',
        'address': businessAddress,
        'phone_1': _businessContactNumberController.text,
        'w_num': _whatsAppNumberController.text,
        'email': _mailIdController.text,
        'photo_base64': base64Image,
      };

      debugPrint(
        'KYC Screen: Base64 request body prepared (without base64 data for brevity)',
      );
      return await _callApiWithRetry(body: body);
    } catch (e) {
      debugPrint('KYC Screen: Error in base64 method: $e');
      rethrow;
    }
  }

  // Fallback method to submit without image if multipart fails
  Future<Map<String, dynamic>> _submitKycDataFallback() async {
    debugPrint('KYC Screen: Using fallback method without image upload');

    try {
      // Generate a unique KYC ID
      final String kycId =
          'KYC${DateTime.now().millisecondsSinceEpoch.toRadixString(16)}';

      // Get the business address from GSTIN details or use a default value
      final String businessAddress =
          _gstinDetails?['Business Address'] ??
          (_businessNameController.text.isNotEmpty
              ? '${_businessNameController.text}, Address to be verified'
              : 'Address to be verified');

      // Prepare the request body with all required fields (without image)
      final Map<String, String> body = {
        'cid': _cid,
        'type': '1023',
        'ln': '2324',
        'lt': '23',
        'device_id': '122',
        'cus_id': _cusId?.toString() ?? '',
        'kyc_id': kycId,
        'name': _fullNameController.text,
        'com_name': _businessNameController.text,
        'gstin': _gstinController.text,
        'pan': _panNumberController.text,
        'aadhar': _aadhaarNumberController.text,
        'nature_of_business': _natureOfBusinessSelected ?? 'Distributor',
        'address': businessAddress,
        'phone_1': _businessContactNumberController.text,
        'w_num': _whatsAppNumberController.text,
        'email': _mailIdController.text,
      };

      debugPrint('KYC Screen: Fallback API request body: $body');

      // Call the API using regular POST
      final response = await _callApiWithRetry(body: body);
      debugPrint('KYC Screen: Fallback API response: $response');

      return response;
    } catch (e) {
      debugPrint('KYC Screen: Error in fallback method: $e');
      rethrow;
    }
  }

  // New method to skip KYC and go to next screen
  Future<void> _skipKycAndProceed() async {
    debugPrint('KYC Screen: Skipping KYC and proceeding to next screen');

    // Save any filled data to provider
    await _kycBusinessDataProvider?.setKycBusinessData(
      fullName: _fullNameController.text,
      mailId: _mailIdController.text,
      whatsAppNumber: _whatsAppNumberController.text,
      businessName: _businessNameController.text,
      gstin: _gstinController.text,
      isGstinVerified: _isGstinVerified,
      aadhaarNumber: _aadhaarNumberController.text,
      panNumber: _panNumberController.text,
      natureOfBusiness: _natureOfBusinessSelected,
      businessContactNumber: _businessContactNumberController.text,
      businessAddress: _gstinDetails?['Business Address'],
      shopImageBytes: _imageBytes,
    );

    // ScaffoldMessenger.of(context).showSnackBar(
    //   SnackBar(
    //     content: Text(
    //       'You can complete KYC later from profile section.',
    //       style: GoogleFonts.poppins(),
    //     ),
    //     backgroundColor: Colors.green,
    //   ),
    // );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => licence1()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = Provider.of<ThemeModeProvider>(context).themeMode;
    final isDarkMode = themeMode == ThemeMode.dark;

    // Define colors based on theme
    final Color gradientStartColor =
        isDarkMode ? Colors.black : const Color(0xffFFD9BD);
    final Color gradientEndColor =
        isDarkMode ? Colors.black : const Color(0xffFFFFFF);
    final Color textColor = isDarkMode ? Colors.white : Colors.black87;
    final Color subtitleColor = isDarkMode ? Colors.white70 : Colors.black54;
    final Color dividerColor = isDarkMode ? Colors.white : Colors.black;
    final Color orangeColor = const Color(0xffEB7720);

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
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bool isTablet = constraints.maxWidth > 600;
            return SingleChildScrollView(
              padding: EdgeInsets.all(isTablet ? 24 : 16),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isTablet ? 700 : double.infinity,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        SizedBox(height: isTablet ? 20 : 10),
                        Image.asset(
                          "assets/kyc1.gif",
                          height: isTablet ? 200 : 150,
                        ),
                        SizedBox(height: isTablet ? 20 : 10),
                        Text(
                          '"Safe, Secure, And Hassle-Free KYC"',
                          style: GoogleFonts.poppins(
                            fontSize: isTablet ? 18 : 16,
                            color: textColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: isTablet ? 10 : 5),
                        Text(
                          "Submit Your Details And Unlock Access To All KISANGRO B2B Products",
                          style: GoogleFonts.poppins(
                            fontSize: isTablet ? 16 : 14,
                            color: subtitleColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        Divider(
                          endIndent: isTablet ? 200 : 130,
                          indent: isTablet ? 200 : 130,
                          color: dividerColor,
                        ),
                        _sectionTitle("Primary Details", isTablet, isDarkMode),
                        _textFormField(
                          "Full Name",
                          controller: _fullNameController,
                          isTablet: isTablet,
                          isDarkMode: isDarkMode,
                        ),
                        _textFormField(
                          "Mail Id",
                          controller: _mailIdController,
                          isTablet: isTablet,
                          isDarkMode: isDarkMode,
                        ),
                        _textFormField(
                          "WhatsApp Number",
                          isNumber: true,
                          controller: _whatsAppNumberController,
                          isTablet: isTablet,
                          isDarkMode: isDarkMode,
                        ),
                        _sectionTitle("Business Details", isTablet, isDarkMode),
                        _textFormField(
                          "Business Name",
                          controller: _businessNameController,
                          isTablet: isTablet,
                          isDarkMode: isDarkMode,
                        ),
                        _textFormField(
                          "GSTIN",
                          showVerify: true,
                          controller: _gstinController,
                          isTablet: isTablet,
                          isDarkMode: isDarkMode,
                        ),
                        _textFormField(
                          "Aadhaar Number (Owner)",
                          isNumber: true,
                          controller: _aadhaarNumberController,
                          isTablet: isTablet,
                          isDarkMode: isDarkMode,
                        ),
                        _textFormField(
                          "Business PAN Number",
                          isPAN: true,
                          controller: _panNumberController,
                          isTablet: isTablet,
                          isDarkMode: isDarkMode,
                        ),
                        _dropdownField(
                          "Nature Of Core Business",
                          _natureOfBusinessSelected,
                          (newValue) {
                            setState(() {
                              _natureOfBusinessSelected = newValue;
                            });
                          },
                          isTablet,
                          isDarkMode,
                        ),
                        _textFormField(
                          "Business Contact Number",
                          isNumber: true,
                          controller: _businessContactNumberController,
                          isTablet: isTablet,
                          isDarkMode: isDarkMode,
                        ),
                        _buildVerifiedGstinDetails(isTablet, isDarkMode),
                        _sectionTitle(
                          "Establishment Photo",
                          isTablet,
                          isDarkMode,
                        ),
                        _photoUploadBox(isTablet, isDarkMode),
                        SizedBox(height: isTablet ? 30 : 20),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: isTablet ? 20 : 8.0,
                          ),
                          child: Text(
                            '(Note: A verification team will be arriving within 3 working days at the given address to verify your business. Make sure you are available at that time.)',
                            textAlign: TextAlign.start,
                            style: GoogleFonts.poppins(
                              fontSize: isTablet ? 14 : 12,
                              color: textColor,
                            ),
                          ),
                        ),
                        SizedBox(height: isTablet ? 30 : 20),
                        // Main Submit Button
                        SizedBox(
                          width: isTablet ? 400 : double.infinity,
                          height: isTablet ? 60 : 50,
                          child: ElevatedButton(
                            onPressed:
                                _isSubmitting
                                    ? null
                                    : () async {
                                      debugPrint(
                                        'KYC Screen: Submit button pressed',
                                      );
                                      FocusScope.of(context).unfocus();

                                      // Show validation message if image is not selected
                                      if (_imageBytes == null ||
                                          _imageBytes!.isEmpty) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Please upload a shop image before submitting.',
                                              style: GoogleFonts.poppins(),
                                            ),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                        return;
                                      }

                                      // Check image size and warn if too large
                                      if (_imageBytes!.lengthInBytes > 100000) {
                                        // 100KB
                                        final shouldContinue =
                                            await showDialog<bool>(
                                              context: context,
                                              builder:
                                                  (context) => AlertDialog(
                                                    title: Text(
                                                      'Large Image',
                                                      style:
                                                          GoogleFonts.poppins(),
                                                    ),
                                                    content: Text(
                                                      'The selected image is ${(_imageBytes!.lengthInBytes / 1024).toStringAsFixed(1)} KB. For better upload success, images under 100 KB are recommended. Do you want to continue?',
                                                      style:
                                                          GoogleFonts.poppins(),
                                                    ),
                                                    actions: [
                                                      TextButton(
                                                        onPressed:
                                                            () => Navigator.pop(
                                                              context,
                                                              false,
                                                            ),
                                                        child: Text(
                                                          'Cancel',
                                                          style:
                                                              GoogleFonts.poppins(),
                                                        ),
                                                      ),
                                                      TextButton(
                                                        onPressed:
                                                            () => Navigator.pop(
                                                              context,
                                                              true,
                                                            ),
                                                        child: Text(
                                                          'Continue',
                                                          style:
                                                              GoogleFonts.poppins(),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                            ) ??
                                            false;

                                        if (!shouldContinue) return;
                                      }

                                      debugPrint(
                                        'KYC Screen: All validations passed, submitting data',
                                      );
                                      setState(() {
                                        _isSubmitting = true;
                                      });

                                      try {
                                        // Show progress dialog
                                        showDialog(
                                          context: context,
                                          barrierDismissible: false,
                                          builder:
                                              (context) => AlertDialog(
                                                content: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    const CircularProgressIndicator(),
                                                    const SizedBox(height: 16),
                                                    Text(
                                                      'Uploading KYC data and image...\nThis may take a few moments.',
                                                      style:
                                                          GoogleFonts.poppins(),
                                                      textAlign:
                                                          TextAlign.center,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                        );

                                        // Save data to provider first with all fields including address
                                        await _kycBusinessDataProvider
                                            ?.setKycBusinessData(
                                              fullName:
                                                  _fullNameController.text,
                                              mailId: _mailIdController.text,
                                              whatsAppNumber:
                                                  _whatsAppNumberController
                                                      .text,
                                              businessName:
                                                  _businessNameController.text,
                                              gstin: _gstinController.text,
                                              isGstinVerified: _isGstinVerified,
                                              aadhaarNumber:
                                                  _aadhaarNumberController.text,
                                              panNumber:
                                                  _panNumberController.text,
                                              natureOfBusiness:
                                                  _natureOfBusinessSelected,
                                              businessContactNumber:
                                                  _businessContactNumberController
                                                      .text,
                                              businessAddress:
                                                  _gstinDetails?['Business Address'],
                                              shopImageBytes: _imageBytes,
                                            );

                                        // Submit to API with image
                                        final response = await _submitKycData();

                                        // Close progress dialog
                                        Navigator.pop(context);

                                        if (response['status'] == 'success') {
                                          debugPrint(
                                            'KYC Screen: KYC data submitted successfully',
                                          );

                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'KYC submitted successfully!',
                                                style: GoogleFonts.poppins(),
                                              ),
                                              backgroundColor: Colors.green,
                                            ),
                                          );

                                          // Navigate to the next screen
                                          Navigator.pushReplacement(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => licence1(),
                                            ),
                                          );
                                        } else {
                                          debugPrint(
                                            'KYC Screen: KYC submission failed: ${response['message']}',
                                          );
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'KYC submission failed: ${response['message'] ?? 'Unknown error'}',
                                                style: GoogleFonts.poppins(),
                                              ),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      } catch (e) {
                                        // Close progress dialog if still open
                                        try {
                                          Navigator.pop(context);
                                        } catch (_) {}

                                        debugPrint(
                                          'KYC Screen: Error submitting KYC: $e',
                                        );

                                        // Show more user-friendly error message
                                        String errorMessage =
                                            'Error submitting KYC data.';
                                        if (e.toString().contains(
                                          'TimeoutException',
                                        )) {
                                          errorMessage =
                                              'Upload timeout. Please check your internet connection and try again.';
                                        } else if (e.toString().contains(
                                          'SocketException',
                                        )) {
                                          errorMessage =
                                              'Network error. Please check your internet connection.';
                                        }

                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              errorMessage,
                                              style: GoogleFonts.poppins(),
                                            ),
                                            backgroundColor: Colors.red,
                                            duration: const Duration(
                                              seconds: 5,
                                            ),
                                          ),
                                        );
                                      } finally {
                                        setState(() {
                                          _isSubmitting = false;
                                        });
                                      }
                                    },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: orangeColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child:
                                _isSubmitting
                                    ? const CircularProgressIndicator(
                                      color: Colors.white,
                                    )
                                    : Text(
                                      'Submit KYC',
                                      style: GoogleFonts.poppins(
                                        fontSize: isTablet ? 18 : 16,
                                        color: Colors.white,
                                      ),
                                    ),
                          ),
                        ),
                        SizedBox(height: isTablet ? 15 : 10),
                        // Skip KYC Button
                        SizedBox(
                          width: isTablet ? 400 : double.infinity,
                          height: isTablet ? 50 : 40,
                          child: TextButton(
                            onPressed:
                                _isSubmitting ? null : _skipKycAndProceed,
                            style: TextButton.styleFrom(
                              foregroundColor: orangeColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: BorderSide(color: orangeColor, width: 2),
                              ),
                            ),
                            child: Text(
                              'Proceed',
                              style: GoogleFonts.poppins(
                                fontSize: isTablet ? 16 : 14,
                                color: orangeColor,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: isTablet ? 30 : 20),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
