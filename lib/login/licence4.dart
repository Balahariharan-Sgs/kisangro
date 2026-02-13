import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kisangro/login/onprocess.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io' show File;
import 'package:provider/provider.dart';
import 'package:kisangro/models/license_provider.dart';
import '../home/theme_mode_provider.dart';

class licence4 extends StatefulWidget {
  final String? licenseTypeToDisplay;

  const licence4({super.key, this.licenseTypeToDisplay});

  @override
  _licence4State createState() => _licence4State();
}

class _licence4State extends State<licence4> {
  final TextEditingController _insecticideLicenseController =
      TextEditingController();
  final TextEditingController _fertilizerLicenseController =
      TextEditingController();

  DateTime? _insecticideExpirationDate;
  DateTime? _fertilizerExpirationDate;

  bool _insecticideNoExpiry = false;
  bool _fertilizerNoExpiry = false;

  Uint8List? _insecticideImageBytes;
  Uint8List? _fertilizerImageBytes;

  bool _insecticideIsImage = true;
  bool _fertilizerIsImage = true;

  bool _isLoading = false;
  String? _errorMessage;

  final TextRecognizer _textRecognizer = TextRecognizer();

  final RegExp _licenseNumberRegExp = RegExp(
    r'(?:License Number|Licence Number)\s*[:\s]*([A-Z0-9\s\/\-\.]*[A-Z0-9])',
    caseSensitive: false,
  );

  final List<RegExp> _datePatterns = [
    RegExp(
      r'(?:Valid\s+upto|Valid\s+up\s+to|Expiry\s*Date)\s*:?\s*(\d{1,2}[\.\-\/]\d{1,2[\.\-\/]\d{4})',
      caseSensitive: false,
    ),
    RegExp(r'\b(\d{1,2}[\.\-\/]\d{1,2}[\.\-\/]\d{4})\b'),
    RegExp(r'\b(\d{4}[\.\-\/]\d{1,2}[\.\-\/]\d{1,2})\b'),
  ];

  final RegExp _permanentPattern = RegExp(
    r'(?:Permanent|No\s+Expiry|Non\s+Expiring|Validity\s+wherever\s+applicable\s*:\s*Permanent)',
    caseSensitive: false,
  );

  String? _currentLicenseTypeToDisplay;
  String? _actualCustomerId; // Store the actual customer ID

  @override
  void initState() {
    super.initState();
    _currentLicenseTypeToDisplay = widget.licenseTypeToDisplay;
    _insecticideLicenseController.addListener(_checkFormValidity);
    _fertilizerLicenseController.addListener(_checkFormValidity);
    _getActualCustomerId().then((_) {
      _loadExistingLicenseData();
    });
    _checkFormValidity();
  }

  // Get the actual customer ID from SharedPreferences
  Future<void> _getActualCustomerId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Get cus_id as int and convert to string for API usage
      final int? cusIdInt = prefs.getInt('cus_id');
      _actualCustomerId = cusIdInt?.toString();
      debugPrint('Retrieved customer ID: $_actualCustomerId');
    } catch (e) {
      debugPrint('Error getting customer ID: $e');
      _actualCustomerId = null;
    }
  }

  // Retrieve license data from API using type 1048 with actual customer ID
  Future<Map<String, dynamic>?> _retrieveLicenseData() async {
    const String apiUrl = 'https://sgserp.in/erp/api/m_api/';

    // Wait for customer ID to be loaded if not already
    if (_actualCustomerId == null) {
      await _getActualCustomerId();
    }

    // If still no customer ID, return null
    if (_actualCustomerId == null) {
      debugPrint('No customer ID available for license retrieval');
      return null;
    }

    try {
      final deviceId = "1234";
      final cid = "23262954";
      final ln = "12";
      final lt = "123";
      final type = "1048";
      final id = _actualCustomerId!; // Use the actual customer ID

      final response = await http
          .post(
            Uri.parse(apiUrl),
            body: {
              'cid': cid,
              'ln': ln,
              'lt': lt,
              'device_id': deviceId,
              'type': type,
              'id': id, // Use customer ID instead of hardcoded "116"
            },
          )
          .timeout(const Duration(seconds: 30));

      debugPrint('License Retrieve Response Code: ${response.statusCode}');
      debugPrint('License Retrieve Raw Response: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        debugPrint('License Retrieve API Response: $responseData');

        if (responseData['status'] == 'success' &&
            responseData['data'] != null) {
          final List<dynamic> dataList = responseData['data'];
          if (dataList.isNotEmpty) {
            return dataList.first as Map<String, dynamic>;
          }
        }
      }
    } catch (e) {
      debugPrint('Error retrieving license data: $e');
    }
    return null;
  }

  Future<void> _loadExistingLicenseData() async {
    final licenseProvider = Provider.of<LicenseProvider>(
      context,
      listen: false,
    );

    // Try to retrieve license data from API first
    final apiLicenseData = await _retrieveLicenseData();
    if (apiLicenseData != null) {
      setState(() {
        // Load pesticide license if available
        if (apiLicenseData['pl_no'] != null &&
            apiLicenseData['pl_no'].toString().isNotEmpty) {
          _insecticideLicenseController.text =
              apiLicenseData['pl_no'].toString();
        }

        // Load fertilizer license if available
        if (apiLicenseData['fl_no'] != null &&
            apiLicenseData['fl_no'].toString().isNotEmpty) {
          _fertilizerLicenseController.text =
              apiLicenseData['fl_no'].toString();
        }

        // Parse expiry date if available
        if (apiLicenseData['expire_date'] != null &&
            apiLicenseData['expire_date'].toString().isNotEmpty) {
          final expireDate = _parseDate(
            apiLicenseData['expire_date'].toString(),
          );
          if (expireDate != null) {
            _insecticideExpirationDate = expireDate;
            _fertilizerExpirationDate = expireDate;
          }
        }

        // Handle PDF file if available
        if (apiLicenseData['pdf_file_base64'] != null &&
            apiLicenseData['pdf_file_base64'].toString().isNotEmpty) {
          try {
            final pdfBytes = base64Decode(apiLicenseData['pdf_file_base64']);
            _insecticideImageBytes = pdfBytes;
            _fertilizerImageBytes = pdfBytes;
            _insecticideIsImage = false;
            _fertilizerIsImage = false;
          } catch (e) {
            debugPrint('Error decoding PDF base64: $e');
          }
        }
      });
    }

    // Load from local provider if no API data
    final pesticideData = licenseProvider.pesticideLicense;
    if (pesticideData != null) {
      setState(() {
        if (_insecticideLicenseController.text.isEmpty) {
          _insecticideLicenseController.text =
              pesticideData.licenseNumber ?? '';
        }
        _insecticideExpirationDate ??= pesticideData.expirationDate;
        _insecticideNoExpiry = pesticideData.noExpiry;
        _insecticideImageBytes ??= pesticideData.imageBytes;
        _insecticideIsImage = pesticideData.isImage;
      });
    }

    final fertilizerData = licenseProvider.fertilizerLicense;
    if (fertilizerData != null) {
      setState(() {
        if (_fertilizerLicenseController.text.isEmpty) {
          _fertilizerLicenseController.text =
              fertilizerData.licenseNumber ?? '';
        }
        _fertilizerExpirationDate ??= fertilizerData.expirationDate;
        _fertilizerNoExpiry = fertilizerData.noExpiry;
        _fertilizerImageBytes ??= fertilizerData.imageBytes;
        _fertilizerIsImage = fertilizerData.isImage;
      });
    }
  }

  bool get _shouldShowPesticideSection =>
      widget.licenseTypeToDisplay == 'pesticide' ||
      widget.licenseTypeToDisplay == 'all';
  bool get _shouldShowFertilizerSection =>
      widget.licenseTypeToDisplay == 'fertilizer' ||
      widget.licenseTypeToDisplay == 'all';

  bool get _isInsecticideSectionValid {
    return _insecticideLicenseController.text.isNotEmpty &&
        (_insecticideNoExpiry || _insecticideExpirationDate != null) &&
        _insecticideImageBytes != null;
  }

  bool get _isFertilizerSectionValid {
    return _fertilizerLicenseController.text.isNotEmpty &&
        (_fertilizerNoExpiry || _fertilizerExpirationDate != null) &&
        _fertilizerImageBytes != null;
  }

  bool get isFormValid {
    if (_shouldShowPesticideSection && _shouldShowFertilizerSection) {
      return _isInsecticideSectionValid && _isFertilizerSectionValid;
    } else if (_shouldShowPesticideSection) {
      return _isInsecticideSectionValid;
    } else if (_shouldShowFertilizerSection) {
      return _isFertilizerSectionValid;
    }
    return false;
  }

  // Pesticide API call (type: 1045)
  Future<bool> _uploadPesticideLicense({
    required String cid,
    required String cusId,
    required String ln,
    required String lt,
    required String deviceId,
    required String plNo,
    required File photoFile,
    required String expireDate,
  }) async {
    const String apiUrl = 'https://erpsmart.in/total/api/m_api/';

    try {
      final prefs = await SharedPreferences.getInstance();

      double? latitude = prefs.getDouble('latitude');
      double? longitude = prefs.getDouble('longitude');
      String? deviceId = prefs.getString('device_id');
      final request = http.MultipartRequest('POST', Uri.parse(apiUrl));

      // Add fields for pesticide API (type: 1045)
      request.fields.addAll({
        'cid': cid,
        'cus_id': cusId,
        'type': '1011', // Pesticide license type
        'lt': latitude?.toString() ?? '1',
        'ln': longitude?.toString() ?? '1',
        'device_id': deviceId ?? '1',
        'pl_no': plNo,
        'expire_date': expireDate,
      });

      // Add file - always send as PDF
      request.files.add(
        await http.MultipartFile.fromPath(
          'photo',
          photoFile.path,
          contentType: MediaType.parse('application/pdf'),
        ),
      );

      debugPrint("Pesticide API Request Fields: ${request.fields}");
      debugPrint("Pesticide API Upload File: ${photoFile.path}");
      debugPrint("Pesticide API Content Type: application/pdf");

      // Send request
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
      );
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('Pesticide Response Code: ${response.statusCode}');
      debugPrint('Pesticide Raw Response: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final Map<String, dynamic> responseData = jsonDecode(response.body);
          debugPrint('Pesticide API Response: $responseData');

          // Check if response contains error
          if (responseData['error'] == true) {
            debugPrint('Pesticide API Error: ${responseData['message']}');
            return false;
          }

          // Check for successful response
          return responseData['error'] == false &&
              responseData['data'] != null &&
              responseData['data'] is List &&
              responseData['data'].isNotEmpty;
        } catch (e) {
          debugPrint('Pesticide JSON Parse Error: $e');
          return false;
        }
      } else {
        debugPrint(
          'Pesticide API Error: Server returned ${response.statusCode}',
        );
        return false;
      }
    } catch (e) {
      debugPrint('Pesticide API Error: $e');
      return false;
    }
  }

  // Fertilizer API call (type: 1012)
  Future<bool> _uploadFertilizerLicense({
    required String cid,
    required String cusId,
    required String ln,
    required String lt,
    required String deviceId,
    required String flNo,
    required File photoFile,
    required String expireDate,
  }) async {
    const String apiUrl = 'https://erpsmart.in/total/api/m_api/';

   try {
      final prefs = await SharedPreferences.getInstance();

      double? latitude = prefs.getDouble('latitude');
      double? longitude = prefs.getDouble('longitude');
      String? deviceId = prefs.getString('device_id');
      final request = http.MultipartRequest('POST', Uri.parse(apiUrl));

      // Add fields for fertilizer API (type: 1012)
      request.fields.addAll({
        'cid': cid,
        'cus_id': cusId,
        'type': '1012', // Fertilizer license type
        'lt': latitude?.toString() ?? '1',
        'ln': longitude?.toString() ?? '1',
        'device_id': deviceId ?? '1',
        'fl_no': flNo,
        'expire_date': expireDate,
      });

      // Add file - always send as PDF
      request.files.add(
        await http.MultipartFile.fromPath(
          'photo',
          photoFile.path,
          contentType: MediaType.parse('application/pdf'),
        ),
      );

      debugPrint("Fertilizer API Request Fields: ${request.fields}");
      debugPrint("Fertilizer API Upload File: ${photoFile.path}");
      debugPrint("Fertilizer API Content Type: application/pdf");

      // Send request
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
      );
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('Fertilizer Response Code: ${response.statusCode}');
      debugPrint('Fertilizer Raw Response: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final Map<String, dynamic> responseData = jsonDecode(response.body);
          debugPrint('Fertilizer API Response: $responseData');

          // Check if response contains error
          if (responseData['error'] == true) {
            debugPrint('Fertilizer API Error: ${responseData['message']}');
            return false;
          }

          // Check for successful response
          return responseData['error'] == false &&
              responseData['data'] != null &&
              responseData['data'] is List &&
              responseData['data'].isNotEmpty;
        } catch (e) {
          debugPrint('Fertilizer JSON Parse Error: $e');
          return false;
        }
      } else {
        debugPrint(
          'Fertilizer API Error: Server returned ${response.statusCode}',
        );
        return false;
      }
    } catch (e) {
      debugPrint('Fertilizer API Error: $e');
      return false;
    }
  }

  // Helper method to create PDF file from image bytes if needed
  Future<File> _createPdfFile(
    Uint8List bytes,
    bool isImage,
    String fileName,
  ) async {
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/$fileName');

    if (isImage) {
      // Convert image to PDF
      final PdfDocument document = PdfDocument();
      final PdfPage page = document.pages.add();
      final PdfGraphics graphics = page.graphics;

      // Create PDF bitmap from image bytes
      final PdfBitmap bitmap = PdfBitmap(bytes);

      // Calculate size to fit the page
      final Size pageSize = page.getClientSize();
      double imageWidth = bitmap.width.toDouble();
      double imageHeight = bitmap.height.toDouble();

      // Scale image to fit page while maintaining aspect ratio
      double scaleX = pageSize.width / imageWidth;
      double scaleY = pageSize.height / imageHeight;
      double scale = scaleX < scaleY ? scaleX : scaleY;

      double finalWidth = imageWidth * scale;
      double finalHeight = imageHeight * scale;

      // Center the image on the page
      double x = (pageSize.width - finalWidth) / 2;
      double y = (pageSize.height - finalHeight) / 2;

      graphics.drawImage(bitmap, Rect.fromLTWH(x, y, finalWidth, finalHeight));

      // Save PDF
      final List<int> pdfBytes = await document.save();
      document.dispose();

      await file.writeAsBytes(pdfBytes);
    } else {
      // It's already a PDF
      await file.writeAsBytes(bytes);
    }

    return file;
  }

  void _checkFormValidity() {
    setState(() {});
  }

  Future<void> _pickDate(BuildContext context, bool isInsecticide) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (BuildContext context, Widget? child) {
        final themeMode = Provider.of<ThemeModeProvider>(context).themeMode;
        final isDarkMode = themeMode == ThemeMode.dark;
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: const Color(0xffEB7720),
              onPrimary: Colors.white,
              onSurface: isDarkMode ? Colors.white : Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xffEB7720),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isInsecticide) {
          _insecticideExpirationDate = picked;
          _insecticideNoExpiry = false;
        } else {
          _fertilizerExpirationDate = picked;
          _fertilizerNoExpiry = false;
        }
      });
      _checkFormValidity();
    }
  }

  Future<void> _pickFile(bool isInsecticide) async {
    final themeMode =
        Provider.of<ThemeModeProvider>(context, listen: false).themeMode;
    final isDarkMode = themeMode == ThemeMode.dark;
    final Color textColor = isDarkMode ? Colors.white : Colors.black;
    final Color iconColor = const Color(0xffEB7720);

    try {
      showModalBottomSheet(
        context: context,
        builder:
            (context) => SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: Icon(Icons.camera_alt, color: iconColor),
                    title: Text(
                      'Open Camera',
                      style: GoogleFonts.poppins(color: textColor),
                    ),
                    onTap: () async {
                      Navigator.pop(context);
                      final pickedFile = await ImagePicker().pickImage(
                        source: ImageSource.camera,
                        imageQuality: 85,
                        maxWidth: 1024,
                        maxHeight: 1024,
                      );
                      if (pickedFile != null) {
                        await _processImageFile(pickedFile, isInsecticide);
                      }
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.photo_library, color: iconColor),
                    title: Text(
                      'Open Gallery',
                      style: GoogleFonts.poppins(color: textColor),
                    ),
                    onTap: () async {
                      Navigator.pop(context);
                      final pickedFile = await ImagePicker().pickImage(
                        source: ImageSource.gallery,
                        imageQuality: 85,
                        maxWidth: 1024,
                        maxHeight: 1024,
                      );
                      if (pickedFile != null) {
                        await _processImageFile(pickedFile, isInsecticide);
                      }
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.picture_as_pdf, color: iconColor),
                    title: Text(
                      'Upload PDF',
                      style: GoogleFonts.poppins(color: textColor),
                    ),
                    onTap: () async {
                      Navigator.pop(context);
                      final result = await FilePicker.platform.pickFiles(
                        type: FileType.custom,
                        allowedExtensions: ['pdf'],
                      );
                      if (result != null &&
                          (result.files.single.bytes != null ||
                              result.files.single.path != null)) {
                        await _processPdfFile(
                          result.files.single,
                          isInsecticide,
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('No PDF selected. Please try again.'),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error opening file picker: $e')));
    }
  }

  Future<void> _processImageFile(XFile imageFile, bool isInsecticide) async {
    _showProcessingDialog('Processing image...');
    try {
      final bytes = await imageFile.readAsBytes();
      final inputImage = InputImage.fromFilePath(imageFile.path);
      final RecognizedText recognizedText = await _textRecognizer.processImage(
        inputImage,
      );
      final extractedText = recognizedText.text;

      Navigator.pop(context);

      if (extractedText.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No text found in the image. Please enter details manually.',
            ),
          ),
        );
        setState(() {
          if (isInsecticide) {
            _insecticideImageBytes = bytes;
            _insecticideIsImage = true;
          } else {
            _fertilizerImageBytes = bytes;
            _fertilizerIsImage = true;
          }
        });
        _checkFormValidity();
        return;
      }

      await _extractLicenseData(extractedText, isInsecticide, bytes, true);
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error processing image: $e. Please enter details manually.',
          ),
        ),
      );
      try {
        final bytes = await imageFile.readAsBytes();
        setState(() {
          if (isInsecticide) {
            _insecticideImageBytes = bytes;
            _insecticideIsImage = true;
          } else {
            _fertilizerImageBytes = bytes;
            _fertilizerIsImage = true;
          }
        });
        _checkFormValidity();
      } catch (e2) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error uploading image: $e2')));
      }
    }
  }

  Future<void> _processPdfFile(PlatformFile file, bool isInsecticide) async {
    _showProcessingDialog('Processing PDF...');

    File? tempFile;
    try {
      Uint8List bytes;
      if (file.bytes != null) {
        bytes = file.bytes!;
      } else if (file.path != null) {
        bytes = await File(file.path!).readAsBytes();
      } else {
        throw Exception('No bytes or path available for the PDF file.');
      }

      final tempDir = await getTemporaryDirectory();
      tempFile = File(
        '${tempDir.path}/${file.name?.replaceAll(RegExp(r'[^\w\.]'), '_') ?? 'temp_pdf.pdf'}',
      );
      await tempFile.writeAsBytes(bytes);

      final PdfDocument document = PdfDocument(inputBytes: bytes);
      final PdfTextExtractor extractor = PdfTextExtractor(document);
      final StringBuffer textBuffer = StringBuffer();
      for (int i = 0; i < document.pages.count; i++) {
        final pageText = extractor.extractText(
          startPageIndex: i,
          endPageIndex: i,
        );
        textBuffer.writeln(pageText);
      }
      final extractedText = textBuffer.toString();
      document.dispose();

      Navigator.pop(context);

      debugPrint('PDF Extracted Text (Raw): "$extractedText"');

      if (extractedText.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No text found in the PDF. Please enter details manually.',
            ),
          ),
        );
        setState(() {
          if (isInsecticide) {
            _insecticideImageBytes = bytes;
            _insecticideIsImage = false;
          } else {
            _fertilizerImageBytes = bytes;
            _fertilizerIsImage = false;
          }
        });
        _checkFormValidity();
        return;
      }

      await _extractLicenseData(extractedText, isInsecticide, bytes, false);
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error processing PDF: $e. Please enter details manually.',
          ),
        ),
      );
      try {
        Uint8List bytes;
        if (file.bytes != null) {
          bytes = file.bytes!;
        } else if (file.path != null) {
          bytes = await File(file.path!).readAsBytes();
        } else {
          throw Exception('No bytes or path available for the PDF file.');
        }
        setState(() {
          if (isInsecticide) {
            _insecticideImageBytes = bytes;
            _insecticideIsImage = false;
          } else {
            _fertilizerImageBytes = bytes;
            _fertilizerIsImage = false;
          }
        });
        _checkFormValidity();
      } catch (e2) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error uploading PDF: $e2')));
      }
    } finally {
      if (tempFile != null && await tempFile.exists()) {
        await tempFile.delete();
      }
    }
  }

  void _showProcessingDialog(String message) {
    final themeMode =
        Provider.of<ThemeModeProvider>(context, listen: false).themeMode;
    final isDarkMode = themeMode == ThemeMode.dark;
    final Color dialogBgColor = isDarkMode ? Colors.grey[850]! : Colors.white;
    final Color textColor = isDarkMode ? Colors.white : Colors.black;
    final Color indicatorColor = const Color(0xffEB7720);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            backgroundColor: dialogBgColor,
            content: Row(
              children: [
                CircularProgressIndicator(color: indicatorColor),
                const SizedBox(width: 20),
                Text(message, style: GoogleFonts.poppins(color: textColor)),
              ],
            ),
          ),
    );
  }

  Future<void> _extractLicenseData(
    String extractedText,
    bool isInsecticide,
    Uint8List bytes,
    bool isImage,
  ) async {
    String? licenseNumber;
    String? expiryDateStr;
    bool isPermanent = false;

    final cleanText =
        extractedText
            .replaceAll('\n', ' ')
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();
    debugPrint('Extracted text (cleaned): "$cleanText"');

    final licenseMatch = _licenseNumberRegExp.firstMatch(cleanText);
    if (licenseMatch != null && licenseMatch.group(1) != null) {
      licenseNumber = licenseMatch.group(1)?.trim();
      debugPrint('License Number extracted: "$licenseNumber"');
    } else {
      debugPrint('No License Number found using generic regex.');
      final fallbackMatch = RegExp(
        r'\b[A-Z0-9]{3,}[A-Z0-9\s\/\-\.]*\b',
        caseSensitive: false,
      ).firstMatch(cleanText);
      if (fallbackMatch != null) {
        licenseNumber = fallbackMatch.group(0)?.trim();
        debugPrint('Fallback License Number extracted: "$licenseNumber"');
      }
    }

    if (_permanentPattern.hasMatch(cleanText)) {
      isPermanent = true;
      expiryDateStr = 'Permanent';
      debugPrint('Permanent validity detected.');
    } else {
      for (RegExp pattern in _datePatterns) {
        final match = pattern.firstMatch(cleanText);
        if (match != null) {
          String matchedDate = match.group(1) ?? match.group(0)!;
          if (!(cleanText.contains('date of grant of licence') &&
              cleanText.contains(matchedDate))) {
            expiryDateStr = matchedDate;
            debugPrint(
              'Expiry Date extracted: "$expiryDateStr" using pattern: "${pattern.pattern}"',
            );
            break;
          }
        }
      }
      if (expiryDateStr == null) {
        debugPrint('No expiry date found.');
      }
    }

    setState(() {
      if (isInsecticide) {
        _insecticideImageBytes = bytes;
        _insecticideIsImage = isImage;
        _insecticideLicenseController.text = licenseNumber ?? '';
        _insecticideNoExpiry = isPermanent;
        _insecticideExpirationDate =
            isPermanent ? null : _parseDate(expiryDateStr ?? '');
      } else {
        _fertilizerImageBytes = bytes;
        _fertilizerIsImage = isImage;
        _fertilizerLicenseController.text = licenseNumber ?? '';
        _fertilizerNoExpiry = isPermanent;
        _fertilizerExpirationDate =
            isPermanent ? null : _parseDate(expiryDateStr ?? '');
      }
    });

    final licenseProvider = Provider.of<LicenseProvider>(
      context,
      listen: false,
    );
    if (isInsecticide) {
      await licenseProvider.setPesticideLicense(
        imageBytes: _insecticideImageBytes,
        isImage: _insecticideIsImage,
        licenseNumber: _insecticideLicenseController.text,
        expirationDate: _insecticideExpirationDate,
        noExpiry: _insecticideNoExpiry,
        displayDate:
            _insecticideNoExpiry
                ? 'Permanent'
                : (_insecticideExpirationDate != null
                    ? DateFormat(
                      'dd/MM/yyyy',
                    ).format(_insecticideExpirationDate!)
                    : null),
      );
    } else {
      await licenseProvider.setFertilizerLicense(
        imageBytes: _fertilizerImageBytes,
        isImage: _fertilizerIsImage,
        licenseNumber: _fertilizerLicenseController.text,
        expirationDate: _fertilizerExpirationDate,
        noExpiry: _fertilizerNoExpiry,
        displayDate:
            _fertilizerNoExpiry
                ? 'Permanent'
                : (_fertilizerExpirationDate != null
                    ? DateFormat(
                      'dd/MM/yyyy',
                    ).format(_fertilizerExpirationDate!)
                    : null),
      );
    }

    _checkFormValidity();

    String message = 'Document uploaded successfully!\n';
    if (licenseNumber != null && licenseNumber.isNotEmpty) {
      message += 'License: ${licenseNumber}\n';
    } else {
      message += 'License number could not be extracted.\n';
    }
    if (isPermanent) {
      message += 'Validity: Permanent';
    } else if (expiryDateStr != null && _parseDate(expiryDateStr) != null) {
      message +=
          'Expiry: ${DateFormat('dd/MM/yyyy').format(_parseDate(expiryDateStr)!)}';
    } else {
      message += 'Expiry date could not be extracted.';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 1)),
    );
  }

  DateTime? _parseDate(String dateStr) {
    String cleanDate = dateStr.replaceAll(RegExp(r'[^\d\.\-\/]'), '');
    List<String> formats = [
      'dd.MM.yyyy',
      'dd-MM.yyyy',
      'dd/MM/yyyy',
      'yyyy.MM.dd',
      'yyyy-MM-dd',
      'yyyy/MM/dd',
    ];

    for (String format in formats) {
      try {
        return DateFormat(format).parseStrict(cleanDate);
      } catch (e) {
        continue;
      }
    }
    debugPrint('Failed to parse date: "$cleanDate"');
    return null;
  }

  @override
  void dispose() {
    _insecticideLicenseController.removeListener(_checkFormValidity);
    _fertilizerLicenseController.removeListener(_checkFormValidity);
    _insecticideLicenseController.dispose();
    _fertilizerLicenseController.dispose();
    _textRecognizer.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool showPesticideSection = _shouldShowPesticideSection;
    final bool showFertilizerSection = _shouldShowFertilizerSection;
    final themeMode = Provider.of<ThemeModeProvider>(context).themeMode;
    final isDarkMode = themeMode == ThemeMode.dark;

    final Color backgroundColor =
        isDarkMode ? Colors.black : const Color(0xffFFD9BD);
    final Color appBarColor = const Color(0xffEB7720);
    final Color appBarIconColor = Colors.white;
    final Color appBarTextColor = Colors.white;
    final Color textColor = isDarkMode ? Colors.white : Colors.black87;
    final Color orangeColor = const Color(0xffEB7720);
    final Color inputFillColor = isDarkMode ? Colors.grey[800]! : Colors.white;
    final Color inputHintColor =
        isDarkMode ? Colors.grey[400]! : Colors.black87;
    final Color inputBorderColor = const Color(0xffEB7720);
    final Color inputFocusedBorderColor = const Color(0xffEB7720);
    final Color checkboxActiveColor = const Color(0xffEB7720);
    final Color checkboxUncheckedColor =
        isDarkMode ? Colors.grey[400]! : Colors.black;
    final Color imageContainerBg =
        isDarkMode ? Colors.grey[800]! : Colors.white;
    final Color imageContainerBorder = const Color(0xffEB7720);
    final Color noteTextColor =
        isDarkMode
            ? Colors.white.withOpacity(0.7)
            : Colors.black87.withOpacity(0.7);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back, color: appBarIconColor),
        ),
        backgroundColor: appBarColor,
        title: Transform.translate(
          offset: const Offset(-25, 0),
          child: Text(
            "Upload License",
            style: GoogleFonts.poppins(color: appBarTextColor, fontSize: 18),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Container(
        height: double.infinity,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              isDarkMode ? Colors.black : const Color(0xffFFD9BD),
              isDarkMode ? Colors.black : const Color(0xffFFFFFF),
            ],
          ),
        ),
        child:
            _isLoading
                ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: orangeColor),
                      const SizedBox(height: 20),
                      Text(
                        'Processing file...',
                        style: GoogleFonts.poppins(color: textColor),
                      ),
                    ],
                  ),
                )
                : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 30,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Step 2/2',
                        style: GoogleFonts.poppins(
                          color: orangeColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),

                      if (showPesticideSection)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildImageUpload(
                              "Upload Pesticide License Document",
                              _insecticideImageBytes,
                              _insecticideIsImage,
                              () => _pickFile(true),
                              isDarkMode,
                              imageContainerBg,
                              imageContainerBorder,
                              orangeColor,
                              noteTextColor,
                              textColor,
                            ),
                            const SizedBox(height: 20),
                            Text(
                              "Pesticide License Number",
                              style: GoogleFonts.poppins(
                                color: textColor,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildTextField(
                              _insecticideLicenseController,
                              "Enter Pesticide License Number",
                              inputFillColor,
                              inputHintColor,
                              inputBorderColor,
                              inputFocusedBorderColor,
                            ),
                            const SizedBox(height: 20),
                            _buildDatePicker(
                              "Expiration Date",
                              _insecticideExpirationDate,
                              _insecticideNoExpiry,
                              () => _pickDate(context, true),
                              (value) {
                                setState(() {
                                  _insecticideNoExpiry = value!;
                                  if (value) {
                                    _insecticideExpirationDate = null;
                                  }
                                });
                                _checkFormValidity();
                              },
                              textColor,
                              inputFillColor,
                              inputHintColor,
                              inputBorderColor,
                              inputFocusedBorderColor,
                              checkboxActiveColor,
                              checkboxUncheckedColor,
                            ),
                            const SizedBox(height: 30),
                          ],
                        ),

                      if (showFertilizerSection)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildImageUpload(
                              "Upload Fertilizer License Document",
                              _fertilizerImageBytes,
                              _fertilizerIsImage,
                              () => _pickFile(false),
                              isDarkMode,
                              imageContainerBg,
                              imageContainerBorder,
                              orangeColor,
                              noteTextColor,
                              textColor,
                            ),
                            const SizedBox(height: 20),
                            Text(
                              "Fertilizer License Number",
                              style: GoogleFonts.poppins(
                                color: textColor,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildTextField(
                              _fertilizerLicenseController,
                              "Enter Fertilizer License Number",
                              inputFillColor,
                              inputHintColor,
                              inputBorderColor,
                              inputFocusedBorderColor,
                            ),
                            const SizedBox(height: 20),
                            _buildDatePicker(
                              "Expiration Date",
                              _fertilizerExpirationDate,
                              _fertilizerNoExpiry,
                              () => _pickDate(context, false),
                              (value) {
                                setState(() {
                                  _fertilizerNoExpiry = value!;
                                  if (value) {
                                    _fertilizerExpirationDate = null;
                                  }
                                });
                                _checkFormValidity();
                              },
                              textColor,
                              inputFillColor,
                              inputHintColor,
                              inputBorderColor,
                              inputFocusedBorderColor,
                              checkboxActiveColor,
                              checkboxUncheckedColor,
                            ),
                            const SizedBox(height: 30),
                          ],
                        ),

                      if (_errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Text(
                            _errorMessage!,
                            style: GoogleFonts.poppins(color: Colors.red),
                          ),
                        ),

                      Center(
                        child: ElevatedButton(
                          onPressed: isFormValid ? _submitForm : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: orangeColor,
                            disabledBackgroundColor: orangeColor.withOpacity(
                              0.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            minimumSize: const Size(200, 50),
                          ),
                          child: Text(
                            'Submit',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
      ),
    );
  }

  Widget _buildImageUpload(
    String title,
    Uint8List? imageBytes,
    bool isImage,
    VoidCallback onTap,
    bool isDarkMode,
    Color containerBg,
    Color borderColor,
    Color iconColor,
    Color noteColor,
    Color textColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: GoogleFonts.poppins(color: textColor, fontSize: 14)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              color: containerBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor, width: 1),
            ),
            child:
                imageBytes == null
                    ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.cloud_upload, size: 40, color: iconColor),
                        const SizedBox(height: 8),
                        Text(
                          'Upload Document',
                          style: GoogleFonts.poppins(
                            color: textColor,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          '(PDF or Image)',
                          style: GoogleFonts.poppins(
                            color: noteColor,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    )
                    : isImage
                    ? Image.memory(imageBytes, fit: BoxFit.cover)
                    : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.picture_as_pdf,
                            size: 40,
                            color: iconColor,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'PDF Document',
                            style: GoogleFonts.poppins(
                              color: textColor,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hintText,
    Color fillColor,
    Color hintColor,
    Color borderColor,
    Color focusedBorderColor,
  ) {
    return TextField(
      controller: controller,
      style: GoogleFonts.poppins(fontSize: 14),
      decoration: InputDecoration(
        filled: true,
        fillColor: fillColor,
        hintText: hintText,
        hintStyle: GoogleFonts.poppins(color: hintColor),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: focusedBorderColor, width: 2),
        ),
      ),
    );
  }

  Widget _buildDatePicker(
    String title,
    DateTime? selectedDate,
    bool noExpiry,
    VoidCallback onTap,
    Function(bool?)? onCheckboxChanged,
    Color textColor,
    Color fillColor,
    Color hintColor,
    Color borderColor,
    Color focusedBorderColor,
    Color checkboxActiveColor,
    Color checkboxUncheckedColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.poppins(color: textColor, fontSize: 14),
              ),
            ),
            Row(
              children: [
                Text(
                  'No Expiry',
                  style: GoogleFonts.poppins(color: textColor, fontSize: 14),
                ),
                Checkbox(
                  value: noExpiry,
                  onChanged: onCheckboxChanged,
                  activeColor: checkboxActiveColor,
                  checkColor: Colors.white,
                  fillColor: MaterialStateProperty.resolveWith<Color>((
                    Set<MaterialState> states,
                  ) {
                    if (states.contains(MaterialState.selected)) {
                      return checkboxActiveColor;
                    }
                    return checkboxUncheckedColor;
                  }),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: noExpiry ? null : onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: fillColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  noExpiry
                      ? 'Permanent'
                      : (selectedDate != null
                          ? DateFormat('dd/MM/yyyy').format(selectedDate)
                          : 'Select Date'),
                  style: GoogleFonts.poppins(
                    color:
                        noExpiry
                            ? hintColor
                            : (selectedDate != null ? textColor : hintColor),
                    fontSize: 14,
                  ),
                ),
                Icon(
                  Icons.calendar_today,
                  color: noExpiry ? hintColor : borderColor,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _submitForm() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final licenseProvider = Provider.of<LicenseProvider>(
      context,
      listen: false,
    );

    // Get the actual customer ID if not already loaded
    if (_actualCustomerId == null) {
      await _getActualCustomerId();
    }

    // If still no customer ID, show error
    if (_actualCustomerId == null) {
      setState(() {
        _isLoading = false;
        _errorMessage =
            'Unable to retrieve customer information. Please try again.';
      });
      return;
    }

    // Retrieve location and device data from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final double? latitude = prefs.getDouble('latitude');
    final double? longitude = prefs.getDouble('longitude');
    final String? deviceId = prefs.getString('device_id');

    bool pesticideSuccess = true;
    bool fertilizerSuccess = true;

    // Upload pesticide license if applicable
    if (_shouldShowPesticideSection && _isInsecticideSectionValid) {
      try {
        final File pdfFile = await _createPdfFile(
          _insecticideImageBytes!,
          _insecticideIsImage,
          'pesticide_license.pdf',
        );
        final String expireDate =
            _insecticideNoExpiry
                ? 'Permanent'
                : DateFormat('yyyy-MM-dd').format(_insecticideExpirationDate!);

        pesticideSuccess = await _uploadPesticideLicense(
          cid: "85788578",
          cusId: _actualCustomerId!, // Use actual customer ID
          ln: latitude?.toString() ?? '',
          lt: longitude?.toString() ?? '',
          deviceId: deviceId ?? '',
          plNo: _insecticideLicenseController.text,
          photoFile: pdfFile,
          expireDate: expireDate,
        );

        if (pesticideSuccess) {
          await licenseProvider.setPesticideLicense(
            imageBytes: _insecticideImageBytes,
            isImage: _insecticideIsImage,
            licenseNumber: _insecticideLicenseController.text,
            expirationDate: _insecticideExpirationDate,
            noExpiry: _insecticideNoExpiry,
            displayDate:
                _insecticideNoExpiry
                    ? 'Permanent'
                    : (_insecticideExpirationDate != null
                        ? DateFormat(
                          'dd/MM/yyyy',
                        ).format(_insecticideExpirationDate!)
                        : null),
          );
        }
      } catch (e) {
        debugPrint('Pesticide upload error: $e');
        pesticideSuccess = false;
      }
    }

    // Upload fertilizer license if applicable
    if (_shouldShowFertilizerSection && _isFertilizerSectionValid) {
      try {
        final File pdfFile = await _createPdfFile(
          _fertilizerImageBytes!,
          _fertilizerIsImage,
          'fertilizer_license.pdf',
        );
        final String expireDate =
            _fertilizerNoExpiry
                ? 'Permanent'
                : DateFormat('yyyy-MM-dd').format(_fertilizerExpirationDate!);

        fertilizerSuccess = await _uploadFertilizerLicense(
          cid: "85788578",
          cusId: _actualCustomerId!, // Use actual customer ID
          ln: latitude?.toString() ?? '',
          lt: longitude?.toString() ?? '',
          deviceId: deviceId ?? '',
          flNo: _fertilizerLicenseController.text,
          photoFile: pdfFile,
          expireDate: expireDate,
        );

        if (fertilizerSuccess) {
          await licenseProvider.setFertilizerLicense(
            imageBytes: _fertilizerImageBytes,
            isImage: _fertilizerIsImage,
            licenseNumber: _fertilizerLicenseController.text,
            expirationDate: _fertilizerExpirationDate,
            noExpiry: _fertilizerNoExpiry,
            displayDate:
                _fertilizerNoExpiry
                    ? 'Permanent'
                    : (_fertilizerExpirationDate != null
                        ? DateFormat(
                          'dd/MM/yyyy',
                        ).format(_fertilizerExpirationDate!)
                        : null),
          );
        }
      } catch (e) {
        debugPrint('Fertilizer upload error: $e');
        fertilizerSuccess = false;
      }
    }

    setState(() {
      _isLoading = false;
    });

    if ((!_shouldShowPesticideSection || pesticideSuccess) &&
        (!_shouldShowFertilizerSection || fertilizerSuccess)) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => KycSplashScreen()),
      );
    } else {
      setState(() {
        _errorMessage = 'Failed to upload license(s). Please try again.';
      });
    }
  }
}
